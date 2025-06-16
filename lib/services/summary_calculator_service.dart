import 'package:saint_bi/models/management_summary.dart';
import 'package:saint_bi/models/invoice.dart';
import 'package:saint_bi/models/invoice_item.dart';
import 'package:saint_bi/models/product.dart';
import 'package:saint_bi/models/account_receivable.dart';
import 'package:saint_bi/models/account_payable.dart';
import 'package:saint_bi/models/purchase.dart';
import 'package:saint_bi/models/inventory_operation.dart';

/// Una clase pura y sin estado dedicada exclusivamente a realizar los cálculos
/// para el Resumen Gerencial.
class ManagementSummaryCalculator {
  /// Calcula el resumen completo a partir de las listas de datos de la API.
  /// Se asume que las listas transaccionales (invoices, purchases, etc.)
  /// ya han sido pre-filtradas por el rango de fechas seleccionado en el Notifier.
  ManagementSummary calculate({
    required List<Invoice> invoices,
    required List<InvoiceItem> invoiceItems,
    required List<Product> products,
    required List<AccountReceivable> receivables,
    required List<AccountPayable> payables,
    required List<Purchase> purchases,
    required List<InventoryOperation> inventoryOps,
  }) {
    final Set<String> returnedDocNumbers = invoices
        .where((inv) => inv.type == 'B')
        .map((inv) => inv.docnumber)
        .toSet();

    final List<Invoice> validSaleInvoices = invoices
        .where((inv) =>
            inv.type == 'A' && !returnedDocNumbers.contains(inv.docnumber))
        .toList();

    final Set<String> validSaleDocNumber =
        validSaleInvoices.map((inv) => inv.docnumber).toSet();

    // 1. Lógica de Ventas, Impuestos y Comisiones
    double totalNetSalesCredit = 0.0;
    double totalNetSalesCash = 0.0;
    double salesVat = 0.0;
    double commissionsPayable = 0.0;

    for (final inv in validSaleInvoices) {
      totalNetSalesCredit += inv.credit;
      totalNetSalesCash += inv.cash;
      salesVat += inv.amounttax;
      commissionsPayable += (inv.collectionComision + inv.saleCommission);
    }
    final double totalNetSales = totalNetSalesCredit + totalNetSalesCash;

    // 2. Lógica de Compras e Impuestos de Compras
    double purchasesVat = 0.0;
    for (final p in purchases) {
      purchasesVat += p.amountTax * p.sign;
    }

    // 3. Lógica de Costos y Utilidad
    final double costOfGoodsSold = invoiceItems
        .where((item) => validSaleDocNumber.contains(item.docNumber))
        .fold(0.0, (sum, item) => sum + (item.cost * item.qty));
    final double grossProfit = totalNetSales - costOfGoodsSold;

    // 4. Lógica de Inventario
    final double currentInventory = products.fold(
        0.0, (previousValue, prod) => previousValue + (prod.cost * prod.stock));
    final double inventoryCharges = inventoryOps
        .where((op) => op.type == 'O') // 'O' para Cargos de Inventario
        .fold(0.0, (previousValue, op) => previousValue + op.amount);
    final double inventoryDischarges = inventoryOps
        .where((op) => op.type == 'P') // 'P' para Descargos de Inventario
        .fold(0.0, (previousValue, op) => previousValue + op.amount);

    // 5. Lógica de Cuentas por Cobrar (utiliza la lista completa, sin filtro de fecha)
    final now = DateTime.now();
    final double overdueReceivables = receivables
        .where((ar) => ar.balance > 0 && ar.dueDate.isBefore(now))
        .fold(0.0, (previousValue, ar) => previousValue + ar.balance);
    final double totalReceivables = receivables
        .where((ar) =>
            ar.balance > 0 &&
            ar.type != '50') // Excluye anticipos del total a cobrar
        .fold(0.0, (previousValue, ar) => previousValue + ar.balance);
    final double customerAdvances = receivables
        .where((ar) => ar.type == '50') // '50' para Anticipo de Clientes
        .fold(0.0, (previousValue, ar) => previousValue + ar.balance);

    // 6. Lógica de Cuentas por Pagar (utiliza la lista completa, sin filtro de fecha)
    final double overduePayables = payables
        .where((ap) => ap.balance > 0 && ap.dueDate.isBefore(now))
        .fold(0.0, (previousValue, ap) => previousValue + ap.balance);
    final double totalPayables = payables
        .where((ap) =>
            ap.balance > 0 &&
            ap.type != '50') // Excluye anticipos del total a pagar
        .fold(0.0, (previousValue, ap) => previousValue + ap.balance);
    final double supplierAdvances = payables
        .where((ap) => ap.type == '50') // '50' para Anticipo de Proveedores
        .fold(0.0, (previousValue, ap) => previousValue + ap.balance);

    // 7. Costos Fijos y Utilidad Neta
    final double netProfitOrLoss = grossProfit - commissionsPayable;

    // 8. Retornamos el objeto de resumen completamente poblado con todos los valores calculados

    return ManagementSummary(
      totalNetSalesCredit: totalNetSalesCredit,
      totalNetSalesCash: totalNetSalesCash,
      totalNetSales: totalNetSales,
      costOfGoodsSold: costOfGoodsSold,
      grossProfit: grossProfit,
      inventoryCharges: inventoryCharges,
      inventoryDischarges: inventoryDischarges,
      commissionsPayable: commissionsPayable,
      netProfitOrLoss: netProfitOrLoss,
      currentInventory: currentInventory,
      overdueReceivables: overdueReceivables,
      totalReceivables: totalReceivables,
      customerAdvances: customerAdvances,
      supplierAdvances: supplierAdvances,
      overduePayables: overduePayables,
      totalPayables: totalPayables,
      salesVat: salesVat,
      purchasesVat: purchasesVat,
    );
  }
}

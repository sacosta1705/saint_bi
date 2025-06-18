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
    // ---------------------------------------------------------------------------
    /// PASO 1: IDENTIFICACIÓN Y AISLAMIENTO DE DEVOLUCIONES
    /// Para garantizar la precisión del reporte, es crucial anular el impacto de las
    /// ventas que han sido devueltas. Esta sección se encarga de ese filtrado inicial.
    // ---------------------------------------------------------------------------

    // 1.1. Se crea un conjunto con los números de documento de todas las transacciones
    // marcadas como Devolución (tipo 'B').
    final Set<String> returnedDocNumbers = invoices
        .where((inv) => inv.type == 'B')
        .map((inv) => inv.docnumber)
        .toSet();

    // 1.2. Se crea la lista definitiva de "Facturas de Venta Válidas".
    // Esta lista contiene únicamente las facturas (tipo 'A') que NO están en el
    // conjunto de devoluciones. Todos los cálculos de ventas y costos se basarán
    // exclusivamente en esta lista.
    final List<Invoice> validSaleInvoices = invoices
        .where((inv) =>
            inv.type == 'A' && !returnedDocNumbers.contains(inv.docnumber))
        .toList();

    // 1.3. Se extraen los números de documento de las facturas válidas para usarlos
    // más adelante en el filtrado de los artículos vendidos.
    final Set<String> validSaleDocNumbers =
        validSaleInvoices.map((inv) => inv.docnumber).toSet();

    // ---------------------------------------------------------------------------
    /// PASO 2: CÁLCULO DE VENTAS NETAS, IMPUESTOS Y COMISIONES
    /// Se calculan los totales basados exclusivamente en la lista de "Facturas de Venta Válidas".
    // ---------------------------------------------------------------------------
    double totalNetSalesCredit = 0.0;
    double totalNetSalesCash = 0.0;
    double salesVat = 0.0;
    double commissionsPayable = 0.0;
    double salesIvaWithheld = 0.0;
    double salesIslrWithheld = 0.0;

    for (final inv in validSaleInvoices) {
      /// Lógica de cálculo de Ventas Netas (Base Imponible):
      /// El objetivo es obtener la porción de la base imponible que fue pagada a
      /// crédito y a contado, según los datos de la API.

      // La base imponible de la factura es provista por la API en el campo 'Monto'.
      final double invoiceTaxableBase = inv.amount;
      // El monto total pagado en la factura es la suma de los campos 'Credito' y 'Contado'.
      final double invoiceTotalPaid = inv.credit + inv.cash;

      // Se distribuye la base imponible de forma proporcional al método de pago.
      // Se previene una división por cero si el monto total pagado es 0.
      if (invoiceTotalPaid > 0) {
        final double creditProportion = inv.credit / invoiceTotalPaid;
        final double cashProportion = inv.cash / invoiceTotalPaid;

        totalNetSalesCredit += invoiceTaxableBase * creditProportion;
        totalNetSalesCash += invoiceTaxableBase * cashProportion;
      }

      // Se acumulan los montos totales de impuestos y comisiones de las ventas válidas.
      salesVat += inv.amounttax;
      commissionsPayable += (inv.collectionComision + inv.saleCommission);

      salesIvaWithheld += inv.ivaWithheld;
      salesIslrWithheld += inv.islrWithheld;
    }

    for (final ar in receivables) {
      if (ar.type == '10') {
        totalNetSalesCredit += ar.netAmount;
        salesVat += ar.taxAmount;
        commissionsPayable += ar.commission;
      }
    }
    // La Venta Neta Total es la suma de la base imponible a crédito y a contado.
    final double totalNetSales = totalNetSalesCredit + totalNetSalesCash;

    // ---------------------------------------------------------------------------
    /// PASO 3: CÁLCULO DE IMPUESTOS EN COMPRAS
    /// Suma el IVA soportado en las compras realizadas en el período.
    // ---------------------------------------------------------------------------
    double purchasesVat = 0.0;
    for (final p in purchases) {
      purchasesVat += p.amountTax * p.sign;
    }

    // ---------------------------------------------------------------------------
    /// PASO 4: CÁLCULO DE COSTO DE MERCANCÍA Y UTILIDAD BRUTA
    /// Mide la rentabilidad directa de las ventas de productos.
    // ---------------------------------------------------------------------------

    // 4.1. Se calcula el costo de la mercancía vendida (CMV).
    // Se filtran los artículos para incluir solo aquellos que pertenecen a las "Facturas de Venta Válidas".
    final double costOfGoodsSold = invoiceItems
        .where((item) => validSaleDocNumbers.contains(item.docNumber))
        .fold(0.0, (sum, item) => sum + (item.cost * item.qty));

    // 4.2. Se calcula la Utilidad Bruta aplicando la fórmula contable estándar:
    // Utilidad Bruta = Ventas Netas Totales - Costo de Mercancía Vendida
    final double grossProfit = totalNetSales - costOfGoodsSold;

    // ---------------------------------------------------------------------------
    /// PASO 5: CÁLCULO DE VALORES DE INVENTARIO
    /// Determina el valor del inventario actual y sus movimientos.
    // ---------------------------------------------------------------------------
    final double currentInventory = products.fold(
        0.0, (previousValue, prod) => previousValue + (prod.cost * prod.stock));
    final double inventoryCharges = inventoryOps
        .where((op) => op.type == 'O') // 'O' para Cargos de Inventario
        .fold(0.0, (previousValue, op) => previousValue + op.amount);
    final double inventoryDischarges = inventoryOps
        .where((op) => op.type == 'P') // 'P' para Descargos de Inventario
        .fold(0.0, (previousValue, op) => previousValue + op.amount);

    // ---------------------------------------------------------------------------
    /// PASO 6: CÁLCULO DE CUENTAS POR COBRAR
    /// Analiza la cartera de clientes (utiliza la lista completa, sin filtro de fecha).
    // ---------------------------------------------------------------------------
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

    // ---------------------------------------------------------------------------
    /// PASO 7: CÁLCULO DE CUENTAS POR PAGAR
    /// Analiza las deudas con proveedores (utiliza la lista completa, sin filtro de fecha).
    // ---------------------------------------------------------------------------
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

    // ---------------------------------------------------------------------------
    /// PASO 8: CÁLCULO DE UTILIDAD O PÉRDIDA NETA (OPERATIVA)
    /// Refleja la utilidad después de considerar los costos y comisiones de venta.
    // ---------------------------------------------------------------------------
    final double netProfitOrLoss = grossProfit - commissionsPayable;

    // ---------------------------------------------------------------------------
    /// Paso 9: Calculo de retenciones de compra y venta
    // ---------------------------------------------------------------------------

    // Retenciones en Compras (lo que nosotros retenemos a proveedores)
    final double purchasesIvaWithheld = payables
        .where((ap) => ap.type == '81') // '81' para Retención de I.V.A. en CxP
        .fold(0.0, (prev, ap) => prev + ap.amount);

    final double purchasesIslrWithheld = payables
        .where((ap) => ap.type == '21') // '21' para Retención de ISLR en CxP
        .fold(0.0, (prev, ap) => prev + ap.amount);

    // ---------------------------------------------------------------------------
    /// PASO 10: RETORNO DEL OBJETO DE RESUMEN
    /// Se construye y devuelve el objeto ManagementSummary con todos los valores calculados.
    // ---------------------------------------------------------------------------
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
      salesIvaWithheld: salesIvaWithheld,
      salesIslrWithheld: salesIslrWithheld,
      purchasesIvaWithheld: purchasesIvaWithheld,
      purchasesIslrWithheld: purchasesIslrWithheld,
    );
  }
}

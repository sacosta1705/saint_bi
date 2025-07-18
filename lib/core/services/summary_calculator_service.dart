import 'package:saint_bi/core/data/models/management_summary.dart';
import 'package:saint_bi/core/data/models/invoice.dart';
import 'package:saint_bi/core/data/models/invoice_item.dart';
import 'package:saint_bi/core/data/models/product.dart';
import 'package:saint_bi/core/data/models/account_receivable.dart';
import 'package:saint_bi/core/data/models/account_payable.dart';
import 'package:saint_bi/core/data/models/purchase.dart';
import 'package:saint_bi/core/data/models/inventory_operation.dart';
import 'package:saint_bi/core/data/models/purchase_item.dart';

class ManagementSummaryCalculator {
  /// Calcula el resumen completo a partir de las listas de datos de la API.
  ManagementSummary calculate({
    required List<Invoice> invoices,
    required List<InvoiceItem> invoiceItems,
    required List<Product> products,
    required List<AccountReceivable> receivables,
    required List<AccountPayable> payables,
    required List<Purchase> purchases,
    required List<InventoryOperation> inventoryOps,
    required List<PurchaseItem> purchaseItems,
    required double monthlyBudget,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // Acumuladores para los totales del reporte.
    double totalNetSalesCredit = 0.0;
    double totalNetSalesCash = 0.0;
    double salesVat = 0.0;
    double commissionsPayable = 0.0;
    double salesIvaWithheld = 0.0;
    double salesIslrWithheld = 0.0;
    double costOfGoodsSold = 0.0;

    // --- PREPARACIÓN DE DATOS CLAVE ---
    // Se crea un conjunto con los números de documento de las CxC pendientes.
    final Set<String> outstandingReceivableDocNumbers = receivables
        .where((ar) => ar.balance > 0)
        .map((ar) => ar.docNumber)
        .toSet();

    // --- PROCESAMIENTO UNIFICADO DE VENTAS Y DEVOLUCIONES ---
    final List<Invoice> allBillingTransactions = invoices
        .where((inv) => inv.type == 'A' || inv.type == 'B')
        .toList();

    for (final inv in allBillingTransactions) {
      final double sign = inv.sign.toDouble();
      final double invoiceTaxableBase = inv.amount;

      // --- CLASIFICACIÓN DE VENTAS (CONTADO VS CRÉDITO) ---
      if (inv.credit > 0) {
        // La transacción original fue a crédito.
        if (outstandingReceivableDocNumbers.contains(inv.docnumber)) {
          // Si AÚN está en las CxC pendientes, impacta el total a CRÉDITO.
          totalNetSalesCredit += invoiceTaxableBase * sign;
        } else {
          // Si ya NO está en las CxC pendientes, significa que fue PAGADA.
          // Por lo tanto, impacta el total de CONTADO.
          totalNetSalesCash += invoiceTaxableBase * sign;
        }
      } else {
        // La transacción original fue de CONTADO puro. Impacta el total de CONTADO.
        totalNetSalesCash += invoiceTaxableBase * sign;
      }

      salesVat += inv.amounttax * sign;
      commissionsPayable +=
          (inv.collectionComision + inv.saleCommission) * sign;
      salesIvaWithheld += inv.ivaWithheld * sign;
      salesIslrWithheld += inv.islrWithheld * sign;
      costOfGoodsSold += invoiceItems
          .where((item) => item.docNumber == inv.docnumber)
          .fold(0.0, (sum, item) => sum + (item.cost * item.qty * sign));
    }

    final double totalNetSales = totalNetSalesCredit + totalNetSalesCash;
    final double grossProfit = totalNetSales - costOfGoodsSold;

    double purchasesVat = 0.0;
    for (final p in purchases) {
      purchasesVat += p.amountTax * p.sign;
    }
    final double currentInventory = products.fold(
      0.0,
      (previousValue, prod) => previousValue + (prod.cost * prod.stock),
    );
    final double inventoryCharges = inventoryOps
        .where((op) => op.type == 'O')
        .fold(0.0, (previousValue, op) => previousValue + op.amount);
    final double inventoryDischarges = inventoryOps
        .where((op) => op.type == 'P')
        .fold(0.0, (previousValue, op) => previousValue + op.amount);
    final double fixtureInventory = products
        .where((prod) => prod.isFixture == 1)
        .fold(0.0, (sum, prod) => sum + (prod.cost * prod.stock));
    final now = DateTime.now();
    final double overdueReceivables = receivables
        .where(
          (ar) => ar.balance > 0 && ar.dueDate.isBefore(now) && ar.type == '20',
        )
        .fold(0.0, (previousValue, ar) => previousValue + ar.balance);
    final double totalReceivables = receivables
        .where((ar) => ar.balance > 0 && ar.type != '50')
        .fold(0.0, (previousValue, ar) => previousValue + ar.balance);
    final double customerAdvances = receivables
        .where((ar) => ar.type == '50')
        .fold(0.0, (previousValue, ar) => previousValue + ar.balance);
    final double overduePayables = payables
        .where((ap) => ap.balance > 0 && ap.dueDate.isBefore(now))
        .fold(0.0, (previousValue, ap) => previousValue + ap.balance);
    final double totalPayables = payables
        .where((ap) => ap.balance > 0 && ap.type != '50')
        .fold(0.0, (previousValue, ap) => previousValue + ap.balance);
    final double supplierAdvances = payables
        .where((ap) => ap.type == '50')
        .fold(0.0, (previousValue, ap) => previousValue + ap.balance);
    double fixedCosts = 0.0;
    if (startDate != null && endDate != null) {
      final daysInPeriod = endDate.difference(startDate).inDays + 1;
      fixedCosts = (monthlyBudget / 30) * daysInPeriod;
    } else {
      fixedCosts = monthlyBudget;
    }
    final double costOfPurchasedServices = purchaseItems
        .where((item) => item.isService)
        .fold(0.0, (sum, item) => sum + (item.cost * item.qty));
    final double operatingExpenses =
        costOfPurchasedServices + commissionsPayable + fixedCosts;
    final double netProfitOrLoss =
        grossProfit - (fixedCosts + commissionsPayable);
    final double purchasesIvaWithheld = payables
        .where((ap) => ap.type == '81')
        .fold(0.0, (prev, ap) => prev + ap.amount);
    final double purchasesIslrWithheld = payables
        .where((ap) => ap.type == '21')
        .fold(0.0, (prev, ap) => prev + ap.amount);
    final double netDebitNotes = receivables
        .where((cxc) => cxc.type == '20')
        .fold(0.0, (sum, cxc) => sum + (cxc.amount));
    final double netCreditNotes = receivables
        .where((cxc) => cxc.type == '31')
        .fold(0.0, (sum, cxc) => sum + (cxc.amount));

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
      operatingExpenses: operatingExpenses,
      fixedCosts: fixedCosts,
      fixtureInventory: fixtureInventory,
      netCreditNotes: netCreditNotes,
      netDebitNotes: netDebitNotes,
    );
  }
}

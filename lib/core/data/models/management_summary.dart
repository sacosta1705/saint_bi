import 'package:equatable/equatable.dart';

class ManagementSummary extends Equatable {
  // --- SECCIÓN OPERACIONES ---
  final double totalNetSalesCredit;
  final double totalNetSalesCash;
  final double totalNetSales;
  final double costOfGoodsSold;
  final double grossProfit;
  final double inventoryCharges;
  final double inventoryDischarges;
  final double fixedCosts;
  final double commissionsPayable;
  final double operatingExpenses;
  final double netProfitOrLoss;
  final double grossProfitMargin;
  final double netProfitMargin;
  final double currentRatio;
  final double quickRatio;
  final double inventoryTurnover;
  final double daysSalesOutstanging;
  final double averageTicket;

  // --- SECCIÓN ACTIVOS Y PASIVOS ---
  final double currentInventory;
  final double fixtureInventory;
  final double overdueReceivables;
  final double totalReceivables;
  final double customerAdvances;
  final double supplierAdvances;
  final double overduePayables;
  final double totalPayables;
  final double netDebitNotes;
  final double netCreditNotes;

  // --- SECCIÓN IMPUESTOS ---
  final double salesVat;
  final double purchasesVat;

  // --- SECCIÓN RETENCIONES ---
  final double salesIvaWithheld;
  final double salesIslrWithheld;
  final double purchasesIvaWithheld;
  final double purchasesIslrWithheld;

  const ManagementSummary({
    this.totalNetSalesCredit = 0.0,
    this.totalNetSalesCash = 0.0,
    this.totalNetSales = 0.0,
    this.costOfGoodsSold = 0.0,
    this.grossProfit = 0.0,
    this.inventoryCharges = 0.0,
    this.inventoryDischarges = 0.0,
    this.fixedCosts = 0.0,
    this.commissionsPayable = 0.0,
    this.operatingExpenses = 0.0,
    this.netProfitOrLoss = 0.0,
    this.currentInventory = 0.0,
    this.overdueReceivables = 0.0,
    this.totalReceivables = 0.0,
    this.customerAdvances = 0.0,
    this.supplierAdvances = 0.0,
    this.overduePayables = 0.0,
    this.totalPayables = 0.0,
    this.salesVat = 0.0,
    this.purchasesVat = 0.0,
    this.salesIvaWithheld = 0.0,
    this.salesIslrWithheld = 0.0,
    this.purchasesIvaWithheld = 0.0,
    this.purchasesIslrWithheld = 0.0,
    this.netCreditNotes = 0.0,
    this.netDebitNotes = 0.0,
    this.fixtureInventory = 0.0,
    this.grossProfitMargin = 0.0,
    this.netProfitMargin = 0.0,
    this.currentRatio = 0.0,
    this.quickRatio = 0.0,
    this.inventoryTurnover = 0.0,
    this.averageTicket = 0.0,
    this.daysSalesOutstanging = 0.0,
  });

  @override
  List<Object?> get props => [
    totalNetSalesCredit,
    totalNetSalesCash,
    totalNetSales,
    costOfGoodsSold,
    grossProfit,
    inventoryCharges,
    inventoryDischarges,
    fixedCosts,
    commissionsPayable,
    operatingExpenses,
    netProfitOrLoss,
    currentInventory,
    fixtureInventory,
    overdueReceivables,
    totalReceivables,
    customerAdvances,
    supplierAdvances,
    overduePayables,
    totalPayables,
    netDebitNotes,
    netCreditNotes,
    salesVat,
    purchasesVat,
    salesIvaWithheld,
    salesIslrWithheld,
    purchasesIvaWithheld,
    purchasesIslrWithheld,
    grossProfitMargin,
    netProfitMargin,
    currentRatio,
    inventoryTurnover,
    averageTicket,
    daysSalesOutstanging,
  ];

  ManagementSummary copyWith({
    double? totalNetSalesCredit,
    double? totalNetSalesCash,
    double? totalNetSales,
    double? costOfGoodsSold,
    double? grossProfit,
    double? inventoryCharges,
    double? inventoryDischarges,
    double? fixedCosts,
    double? commissionsPayable,
    double? operatingExpenses,
    double? netProfitOrLoss,
    double? grossProfitMargin,
    double? netProfitMargin,
    double? currentInventory,
    double? fixtureInventory,
    double? overdueReceivables,
    double? totalReceivables,
    double? customerAdvances,
    double? supplierAdvances,
    double? overduePayables,
    double? totalPayables,
    double? netDebitNotes,
    double? netCreditNotes,
    double? salesVat,
    double? purchasesVat,
    double? salesIvaWithheld,
    double? salesIslrWithheld,
    double? purchasesIvaWithheld,
    double? purchasesIslrWithheld,
    double? currentRatio,
    double? quickRatio,
    double? inventoryTurnover,
    double? averageTicket,
    double? daysSalesOutstanging,
  }) {
    return ManagementSummary(
      totalNetSalesCredit: totalNetSalesCredit ?? this.totalNetSalesCredit,
      totalNetSalesCash: totalNetSalesCash ?? this.totalNetSalesCash,
      totalNetSales: totalNetSales ?? this.totalNetSales,
      costOfGoodsSold: costOfGoodsSold ?? this.costOfGoodsSold,
      grossProfit: grossProfit ?? this.grossProfit,
      inventoryCharges: inventoryCharges ?? this.inventoryCharges,
      inventoryDischarges: inventoryDischarges ?? this.inventoryDischarges,
      fixedCosts: fixedCosts ?? this.fixedCosts,
      commissionsPayable: commissionsPayable ?? this.commissionsPayable,
      operatingExpenses: operatingExpenses ?? this.operatingExpenses,
      netProfitOrLoss: netProfitOrLoss ?? this.netProfitOrLoss,
      grossProfitMargin: grossProfitMargin ?? this.grossProfitMargin,
      netProfitMargin: netProfitMargin ?? this.netProfitMargin,
      currentInventory: currentInventory ?? this.currentInventory,
      fixtureInventory: fixtureInventory ?? this.fixtureInventory,
      overdueReceivables: overdueReceivables ?? this.overdueReceivables,
      totalReceivables: totalReceivables ?? this.totalReceivables,
      customerAdvances: customerAdvances ?? this.customerAdvances,
      supplierAdvances: supplierAdvances ?? this.supplierAdvances,
      overduePayables: overduePayables ?? this.overduePayables,
      totalPayables: totalPayables ?? this.totalPayables,
      netDebitNotes: netDebitNotes ?? this.netDebitNotes,
      netCreditNotes: netCreditNotes ?? this.netCreditNotes,
      salesVat: salesVat ?? this.salesVat,
      purchasesVat: purchasesVat ?? this.purchasesVat,
      salesIvaWithheld: salesIvaWithheld ?? this.salesIvaWithheld,
      salesIslrWithheld: salesIslrWithheld ?? this.salesIslrWithheld,
      purchasesIvaWithheld: purchasesIvaWithheld ?? this.purchasesIvaWithheld,
      purchasesIslrWithheld:
          purchasesIslrWithheld ?? this.purchasesIslrWithheld,
      currentRatio: currentRatio ?? this.currentRatio,
      quickRatio: quickRatio ?? this.quickRatio,
      inventoryTurnover: inventoryTurnover ?? this.inventoryTurnover,
      averageTicket: averageTicket ?? this.averageTicket,
      daysSalesOutstanging: daysSalesOutstanging ?? this.daysSalesOutstanging,
    );
  }
}

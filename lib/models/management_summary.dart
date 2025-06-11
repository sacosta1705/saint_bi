// Archivo: lib/models/management_summary.dart

class ManagementSummary {
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
  final double netProfitOrLoss;

  // --- SECCIÓN ACTIVOS Y PASIVOS ---
  final double currentInventory;
  final double overdueReceivables;
  final double totalReceivables;
  final double cashAndBanks;
  final double customerAdvances;
  final double supplierAdvances;
  final double overduePayables;
  final double totalPayables;

  // --- SECCIÓN IMPUESTOS ---
  final double salesVat;
  final double purchasesVat;

  // --- CONSTRUCTOR ---
  ManagementSummary({
    // Inicializamos todos los valores en 0.0 por defecto
    this.totalNetSalesCredit = 0.0,
    this.totalNetSalesCash = 0.0,
    this.totalNetSales = 0.0,
    this.costOfGoodsSold = 0.0,
    this.grossProfit = 0.0,
    this.inventoryCharges = 0.0,
    this.inventoryDischarges = 0.0,
    this.fixedCosts = 0.0,
    this.commissionsPayable = 0.0,
    this.netProfitOrLoss = 0.0,
    this.currentInventory = 0.0,
    this.overdueReceivables = 0.0,
    this.totalReceivables = 0.0,
    this.cashAndBanks = 0.0,
    this.customerAdvances = 0.0,
    this.supplierAdvances = 0.0,
    this.overduePayables = 0.0,
    this.totalPayables = 0.0,
    this.salesVat = 0.0,
    this.purchasesVat = 0.0,
  });
}

class PurchaseSummary {
  final double totalPurchases;
  final double totalReturns;
  final double totalTax;
  final int purchasesCount;
  final int returnsCount;

  PurchaseSummary({
    this.totalPurchases = 0.0,
    this.totalReturns = 0.0,
    this.totalTax = 0.0,
    this.purchasesCount = 0,
    this.returnsCount = 0,
  });
}

class InvoiceSummary {
  final double totalSales;
  final double totalReturns;
  final double totalTax;
  final int salesCount;
  final int returnsCount;

  InvoiceSummary({
    this.totalSales = 0.0,
    this.totalReturns = 0.0,
    this.totalTax = 0.0,
    this.salesCount = 0,
    this.returnsCount = 0,
  });
}

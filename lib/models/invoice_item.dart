class InvoiceItem {
  final String docNumber;
  final String productCode;
  final double qty;
  final double cost;

  InvoiceItem({
    required this.docNumber,
    required this.productCode,
    required this.qty,
    required this.cost,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      docNumber: json['numerod'] as String,
      productCode: json['coditem'] as String,
      qty: (json['cantidad'] as num?)?.toDouble() ?? 0.0,
      cost: (json['costo'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

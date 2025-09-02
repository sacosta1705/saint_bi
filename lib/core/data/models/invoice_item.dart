class InvoiceItem {
  final String type;
  final String docNumber;
  final String productCode;
  final double qty;
  final double cost;
  final double price;
  final double tax;

  InvoiceItem({
    required this.type,
    required this.docNumber,
    required this.productCode,
    required this.qty,
    required this.cost,
    required this.price,
    required this.tax,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      type: json['tipofac']?.toString() ?? '',
      docNumber: json['numerod']?.toString() ?? '',
      productCode: json['coditem']?.toString() ?? '',
      qty: (json['cantidad'] as num?)?.toDouble() ?? 0.0,
      cost: (json['costo'] as num?)?.toDouble() ?? 0.0,
      price: (json['precio'] as num?)?.toDouble() ?? 0.0,
      tax: (json['mtotax'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipofac': type,
      'numerod': docNumber,
      'coditem': productCode,
      'cantidad': qty,
      'costo': cost,
      'precio': price,
      'mtotax': tax,
    };
  }
}

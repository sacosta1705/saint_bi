class PurchaseItem {
  final String docNumber;
  final String itemCode;
  final double qty;
  final double cost;
  final bool isService;

  PurchaseItem({
    required this.docNumber,
    required this.itemCode,
    required this.qty,
    required this.cost,
    required this.isService,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      docNumber: json['numerod']?.toString() ?? '',
      itemCode: json['coditem']?.toString() ?? '',
      qty: (json['cantidad'] as num?)?.toDouble() ?? 0.0,
      cost: (json['costo'] as num?)?.toDouble() ?? 0.0,
      isService: json['esserv'] == 1,
    );
  }
}

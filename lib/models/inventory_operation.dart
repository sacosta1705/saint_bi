class InventoryOperation {
  final double amount;
  final String type;

  InventoryOperation({
    required this.amount,
    required this.type,
  });

  factory InventoryOperation.fromJson(Map<String, dynamic> json) {
    return InventoryOperation(
      type: json['tipoopi'] as String,
      amount: (json['monto'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

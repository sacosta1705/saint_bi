var inventoryOperationTypes = {
  'O': 'Cargo de inventario',
  'P': 'Descargo de inventario',
  'Q': 'Ajuste de inventario',
  'N': 'Traslado de inventario, deposito origen',
  'T': 'Traslado de inventario, deposito destino',
};

class InventoryOperation {
  final double amount;
  final String type;

  InventoryOperation({required this.amount, required this.type});

  factory InventoryOperation.fromJson(Map<String, dynamic> json) {
    return InventoryOperation(
      type: json['tipoopi']?.toString() ?? '',
      amount: (json['monto'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

var accountPayableTypes = {
  '10': 'Factura a credito',
  '21': 'Nota de Débito',
  '35': 'Nota de Crédito',
  '30': 'Nota de Credito',
  '41': 'Pago',
  '50': 'Anticipo',
  '81': 'Retención IVA',
};

class AccountPayable {
  final String docNumber;
  final double amount;
  final double balance;
  final DateTime emissionDate;
  final DateTime dueDate;
  final String type;
  final double comission;

  AccountPayable({
    required this.docNumber,
    required this.amount,
    required this.balance,
    required this.emissionDate,
    required this.dueDate,
    required this.type,
    required this.comission,
  });

  factory AccountPayable.fromJson(Map<String, dynamic> json) {
    return AccountPayable(
      docNumber: json['numerod']?.toString() ?? '',
      amount: (json['monto'] as num?)?.toDouble() ?? 0.0,
      balance: (json['saldo'] as num?)?.toDouble() ?? 0.0,
      emissionDate: json['fechae'] != null
          ? DateTime.parse(json['fechav'])
          : DateTime(1900),
      dueDate: json['fechav'] != null
          ? DateTime.parse(json['fechav'])
          : DateTime(1900),
      type: json['tipocxp']?.toString() ?? '',
      comission: (json['comision'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

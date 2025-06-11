class AccountPayable {
  final String docNumber;
  final double balance;
  final DateTime emissionDate;
  final DateTime dueDate;
  final String type;
  final double comission;

  AccountPayable({
    required this.docNumber,
    required this.balance,
    required this.emissionDate,
    required this.dueDate,
    required this.type,
    required this.comission,
  });

  factory AccountPayable.fromJson(Map<String, dynamic> json) {
    return AccountPayable(
      docNumber: json['numerod'] as String,
      balance: (json['saldo'] as num?)?.toDouble() ?? 0.0,
      emissionDate: json['fechae'] != null
          ? DateTime.parse(json['fechav'])
          : DateTime(1900),
      dueDate: json['fechav'] != null
          ? DateTime.parse(json['fechav'])
          : DateTime(1900),
      type: json['tipocxp'] ?? '',
      comission: (json['comision'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

var purchaseTypes = {
  'H': 'Compra',
  'I': 'Devolución de compra',
  'J': 'Nota de entrega',
  'K': 'Devolución nota de entrega',
  'L': 'Orden de Compra',
  'S': 'Cotización',
};

class Purchase {
  final String uniqueNum;
  final String type;
  final String docNumber;
  final String date;
  final double exchange;
  final double amountEx;
  final double amount;
  final double amountTax;
  final double debit;
  final double credit;
  final double sign;

  Purchase({
    required this.uniqueNum,
    required this.type,
    required this.docNumber,
    required this.date,
    required this.exchange,
    required this.amountEx,
    required this.amount,
    required this.amountTax,
    required this.debit,
    required this.credit,
    required this.sign,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      uniqueNum: json['nrounico']?.toString() ?? '',
      type: json['tipofac']?.toString() ?? '',
      docNumber: json['numerod']?.toString() ?? '',
      date: json['fechae']?.toString() ?? '',
      exchange: (json['factor'] as num?)?.toDouble() ?? 0.0,
      amountEx: (json['montomex'] as num?)?.toDouble() ?? 0.0,
      amount: (json['monto'] as num?)?.toDouble() ?? 0.0,
      amountTax: (json['mtotax'] as num?)?.toDouble() ?? 0.0,
      debit: (json['contado'] as num?)?.toDouble() ?? 0.0,
      credit: (json['credito'] as num?)?.toDouble() ?? 0.0,
      sign: (json['signo'] as num?)?.toDouble() ?? 0,
    );
  }
}

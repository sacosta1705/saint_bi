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
      uniqueNum: json['nrounico'],
      type: json['tipofac'],
      docNumber: json['numerod'],
      date: json['fechae'],
      exchange: json['factor'],
      amountEx: json['montomex'],
      amount: json['monto'],
      amountTax: json['mtotax'],
      debit: json['contado'],
      credit: json['credito'],
      sign: json['signo'],
    );
  }
}

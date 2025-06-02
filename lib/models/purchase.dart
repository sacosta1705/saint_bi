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
  });
}

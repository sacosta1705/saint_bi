class Invoice {
  final String docnumber;
  final String type;
  final String clientid;
  final String client;
  final String salesperson;
  final double amount;
  final double amountex;
  final double amounttax;
  final double exchange;
  final String date;

  Invoice({
    required this.docnumber,
    required this.type,
    required this.clientid,
    required this.client,
    required this.salesperson,
    required this.amount,
    required this.amountex,
    required this.amounttax,
    required this.exchange,
    required this.date,
  });
}

var invoiceTypes = {
  'A': 'Factura',
  'B': 'Devolución',
  'C': 'Nota de Entrega',
  'E': 'Pedido',
  'F': 'Presupuesto',
  'G': 'Documento en espera',
};

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
  final double credit;
  final double cash;
  final double saleCommission;
  final double collectionComision;
  final double ivaWithheld;
  final double islrWithheld;
  final int sign;

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
    required this.credit,
    required this.cash,
    required this.saleCommission,
    required this.collectionComision,
    required this.ivaWithheld,
    required this.islrWithheld,
    required this.sign,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      docnumber: json['numerod']?.toString() ?? '',
      type: json['tipofac']?.toString() ?? '',
      clientid: json['codclie']?.toString() ?? '',
      client: json['descrip']?.toString() ?? '',
      salesperson: json['codvend']?.toString() ?? '',
      date: json['fechae']?.toString() ?? '',
      amount: (json['monto'] as num?)?.toDouble() ?? 0.0,
      amountex: (json['montomex'] as num?)?.toDouble() ?? 0.0,
      amounttax: (json['mtotax'] as num?)?.toDouble() ?? 0.0,
      exchange: (json['factor'] as num?)?.toDouble() ?? 0.0,
      credit: (json['credito'] as num?)?.toDouble() ?? 0.0,
      cash: (json['contado'] as num?)?.toDouble() ?? 0.0,
      saleCommission: (json['mtocomivta'] as num?)?.toDouble() ?? 0.0,
      collectionComision: (json['mtocomicob'] as num?)?.toDouble() ?? 0.0,
      ivaWithheld: (json['reteniva'] as num?)?.toDouble() ?? 0.0,
      islrWithheld: (json['canceli'] as num?)?.toDouble() ?? 0.0,
      sign: (json['signo'] as num?)?.toInt() ?? 0,
    );
  }
}

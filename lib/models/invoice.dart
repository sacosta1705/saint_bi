class Invoice {
  final String docnumber; // Numero de documento de la transaccion
  final String type; // Tipo de transaccion A: Factura, B: Devolucion
  final String clientid; // Codigo del cliente
  final String client; // Nombre del cliente
  final String salesperson; // Codigo del vendedor
  final double amount; // Base imponible de la transaccion
  final double amountex; // Base imponible en la moneda referencial
  final double amounttax; // Monto del impuesto
  final double exchange; // Tasa de cambio de la moneda referencial
  final String date; // Fecha de emision de la transaccion

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

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      docnumber: json['numerod'] as String,
      clientid: json['codclie'] as String,
      client: json['descrip'] as String,
      type: json['tipofac'] as String,
      salesperson: json['codvend'] as String,
      amount: json['monto'] as double,
      amountex: json['montomex'] as double,
      amounttax: json['mtotax'] as double,
      exchange: json['factor'] as double,
      date: json['fechae'] as String,
    );
  }
}

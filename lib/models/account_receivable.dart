/// Clase que representa una deuda de un cliente hacia la empresa.
///
/// El hecho de que exista un registro en este servicio representa una deuda
/// pendiente del cliente.
///
class AccountReceivable {
  /// El numero de la factura asociada a la cual esta relacionada la deuda.
  ///
  /// Ej: La factura 01 fue facturada a credito. El pago pendiente de esa factura
  /// estara en este servicio con el mismo numero de documento.
  final String docNumber;

  final double amount;

  final double netAmount;

  final double taxAmount;

  /// Monto de la deuda a cobrar
  final double balance;

  /// Fecha de emision de la deuda
  final DateTime emissionDate;

  /// Fecha de vencimiento de la deuda
  final DateTime dueDate;

  /// Tipo de operacion.
  /// Para conocer las opciones posibles visitar [https://documenter.getpostman.com/view/9183053/2s9YR83Cmq]
  final String type;

  /// Monto de la comision
  final double commission;

  /// Constructor de la clase. Crea una instancia de [AccountReceivable]
  AccountReceivable({
    required this.docNumber,
    required this.amount,
    required this.netAmount,
    required this.taxAmount,
    required this.balance,
    required this.emissionDate,
    required this.dueDate,
    required this.type,
    required this.commission,
  });

  /// Crea una instancia de [AccountReceivable] a partir de un `json`.
  /// Dicho `json` debe estar en formato [Map<String, dynamic>]
  factory AccountReceivable.fromJson(Map<String, dynamic> json) {
    return AccountReceivable(
      docNumber: json['numerod']?.toString() ?? '',
      amount: (json['monto'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['montoneto'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['mtotax'] as num?)?.toDouble() ?? 0.0,
      balance: (json['saldo'] as num?)?.toDouble() ?? 0.0,
      emissionDate: json['fechae'] != null
          ? DateTime.parse(json['fechae'])
          : DateTime(1900),
      dueDate: json['fechav'] != null
          ? DateTime.parse(json['fechav'])
          : DateTime(1900),
      type: json['tipocxc']?.toString() ?? '',
      commission: (json['comision'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

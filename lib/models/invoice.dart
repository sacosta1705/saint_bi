class Invoice {
  final String numerod;
  final String codclie;
  final double monto;
  final String fechae;

  Invoice({
    required this.numerod,
    required this.codclie,
    required this.monto,
    required this.fechae,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      numerod: json['numerod'] ?? 'N/A',
      codclie: json['codclie'] ?? 'N/A',
      monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
      fechae: json['fechae'] ?? 'N/A',
    );
  }
}

class Service {
  final int id;
  final String code;
  final String description;
  final double cost;
  final double price;

  Service({
    required this.id,
    required this.code,
    required this.description,
    required this.cost,
    required this.price,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      code: json['codserv']?.toString() ?? '',
      description: json['descrip']?.toString() ?? '',
      cost: (json['costo'] as num?)?.toDouble() ?? 0.0,
      price: (json['precio1'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

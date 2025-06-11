class Product {
  final String code;
  final String description;
  final double cost;
  final double stock;

  Product({
    required this.code,
    required this.description,
    required this.cost,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      code: json['codprod'],
      description: json['descrip'],
      cost: (json['costact'] as num?)?.toDouble() ?? 0.0,
      stock: (json['existen'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

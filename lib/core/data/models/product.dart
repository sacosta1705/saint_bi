class Product {
  final String code;
  final String description;
  final double cost;
  final double price1;
  final double price2;
  final double price3;
  final double stock;
  final int? isFixture;

  Product({
    required this.code,
    required this.description,
    required this.price1,
    required this.price2,
    required this.price3,
    required this.cost,
    required this.stock,
    this.isFixture,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      code: json['codprod']?.toString() ?? '',
      description: json['descrip']?.toString() ?? '',
      price1: (json['precio1'] as num?)?.toDouble() ?? 0.0,
      price2: (json['precio2'] as num?)?.toDouble() ?? 0.0,
      price3: (json['precio3'] as num?)?.toDouble() ?? 0.0,
      cost: (json['costact'] as num?)?.toDouble() ?? 0.0,
      stock: (json['existen'] as num?)?.toDouble() ?? 0.0,
      isFixture: (json['esenser'] as num?)?.toInt() ?? 0,
    );
  }
}

import 'dart:convert';

class Permissions {
  bool canViewSales;

  Permissions({
    this.canViewSales = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'canViewSales': canViewSales,
    };
  }

  factory Permissions.fromMap(Map<String, dynamic> map) {
    return Permissions(
      canViewSales: map['canViewSales'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());
  factory Permissions.fromJson(String source) =>
      Permissions.fromMap(json.decode(source));

  Permissions copyWith({
    bool? canViewSales,
  }) {
    return Permissions(
      canViewSales: canViewSales ?? this.canViewSales,
    );
  }
}

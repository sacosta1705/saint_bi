class Configuration {
  final int? id;
  final double monthlyBudget;

  Configuration({this.id, required this.monthlyBudget});

  factory Configuration.fromJson(Map<String, dynamic> json) {
    return Configuration(
      id: (json['id'] as num?)?.toInt() ?? 0,
      monthlyBudget: (json['montomes'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Configuration {
  final double monthlyBudget;

  Configuration({required this.monthlyBudget});

  factory Configuration.fromJson(Map<String, dynamic> json) {
    return Configuration(
      monthlyBudget: (json['montomes'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

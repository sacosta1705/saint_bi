part of 'monthly_sales_bloc.dart';

enum MonthlySalesStatus { initial, loading, success, failure }

class MonthlySalesState extends Equatable {
  final MonthlySalesStatus status;
  final int year;
  final Map<int, double> monthlySales;
  final String? error;

  const MonthlySalesState({
    this.status = MonthlySalesStatus.initial,
    required this.year,
    this.monthlySales = const {},
    this.error,
  });

  MonthlySalesState copyWith({
    MonthlySalesStatus? status,
    int? year,
    Map<int, double>? monthlySales,
    String? error,
  }) {
    return MonthlySalesState(
      status: status ?? this.status,
      year: year ?? this.year,
      monthlySales: monthlySales ?? this.monthlySales,
      error: error, // Limpiar el error si no se especifica uno nuevo
    );
  }

  @override
  List<Object?> get props => [status, year, monthlySales, error];
}

part of 'monthly_sales_bloc.dart';

abstract class MonthlySalesEvent extends Equatable {
  const MonthlySalesEvent();

  @override
  List<Object> get props => [];
}

class MonthlySalesYearChanged extends MonthlySalesEvent {
  final int year;

  const MonthlySalesYearChanged(this.year);

  @override
  List<Object> get props => [year];
}

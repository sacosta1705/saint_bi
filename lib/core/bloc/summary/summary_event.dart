part of 'summary_bloc.dart';

abstract class SummaryEvent extends Equatable {
  const SummaryEvent();

  @override
  List<Object?> get props => [];
}

class SummaryDataFetched extends SummaryEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const SummaryDataFetched({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class SummaryDateRangeChanged extends SummaryEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const SummaryDateRangeChanged({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class SummaryCleared extends SummaryEvent {}

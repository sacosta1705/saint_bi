import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:saint_bi/core/bloc/auth/auth_bloc.dart';
import 'package:saint_bi/core/bloc/connection/connection_bloc.dart';
import 'package:saint_bi/core/data/models/invoice.dart';
import 'package:saint_bi/core/data/repositories/summary_repository.dart';
import 'package:saint_bi/core/utils/constants.dart';

part 'monthly_sales_event.dart';
part 'monthly_sales_state.dart';

class MonthlySalesBloc extends Bloc<MonthlySalesEvent, MonthlySalesState> {
  final SummaryRepository _summaryRepository;
  final AuthBloc _authBloc;
  final ConnectionBloc _connectionBloc;

  MonthlySalesBloc({
    required SummaryRepository summaryRepository,
    required AuthBloc authBloc,
    required ConnectionBloc connectionBloc,
  }) : _summaryRepository = summaryRepository,
       _authBloc = authBloc,
       _connectionBloc = connectionBloc,
       super(MonthlySalesState(year: DateTime.now().year)) {
    on<MonthlySalesYearChanged>(_onYearChanged);
  }

  Future<void> _onYearChanged(
    MonthlySalesYearChanged event,
    Emitter<MonthlySalesState> emit,
  ) async {
    emit(state.copyWith(status: MonthlySalesStatus.loading, year: event.year));

    final authState = _authBloc.state;
    final connectionState = _connectionBloc.state;

    if (authState.status != AuthStatus.authenticated ||
        connectionState.activeConnection == null) {
      emit(
        state.copyWith(
          status: MonthlySalesStatus.failure,
          error: AppConstants.noConnectionSelectedMessage,
        ),
      );
      return;
    }

    try {
      final invoices = await _summaryRepository.fetchInvoicesForYear(
        baseUrl: connectionState.activeConnection!.baseUrl,
        authToken: authState.loginResponse!.authToken!,
        year: event.year,
      );

      final salesData = _calculateMonthlySales(invoices);

      emit(
        state.copyWith(
          status: MonthlySalesStatus.success,
          monthlySales: salesData,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: MonthlySalesStatus.failure, error: e.toString()),
      );
    }
  }

  Map<int, double> _calculateMonthlySales(List<Invoice> invoices) {
    final Map<int, double> monthlyTotals = {
      for (var i = 1; i <= 12; i++) i: 0.0,
    };

    final salesInvoices = invoices.where(
      (inv) => inv.type == AppConstants.invoiceTypeSale,
    );

    for (final invoice in salesInvoices) {
      try {
        final dateString = invoice.date.substring(0, 10);
        final date = DateFormat('yyyy-MM-dd').parse(dateString, true);
        final month = date.month;
        monthlyTotals.update(
          month,
          (value) => value + invoice.amount,
          ifAbsent: () => invoice.amount,
        );
      } catch (e) {}
    }

    return monthlyTotals;
  }
}

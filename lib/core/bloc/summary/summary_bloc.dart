import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:saint_bi/core/bloc/auth/auth_bloc.dart';
import 'package:saint_bi/core/bloc/connection/connection_bloc.dart';
import 'package:saint_bi/core/data/models/account_payable.dart';
import 'package:saint_bi/core/data/models/account_receivable.dart';
import 'package:saint_bi/core/data/models/invoice.dart';
import 'package:saint_bi/core/data/models/invoice_item.dart';
import 'package:saint_bi/core/data/models/management_summary.dart';
import 'package:saint_bi/core/data/models/product.dart';
import 'package:saint_bi/core/data/models/purchase.dart';
import 'package:saint_bi/core/data/repositories/summary_repository.dart';
import 'package:saint_bi/core/services/summary_calculator_service.dart';
import 'package:saint_bi/core/data/sources/remote/saint_api_exceptions.dart';
import 'package:saint_bi/core/utils/constants.dart';

part 'summary_event.dart';
part 'summary_state.dart';

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  final SummaryRepository _summaryRepository;
  final AuthBloc _authBloc;
  final ConnectionBloc _connectionBloc;
  final ManagementSummaryCalculator _calculator;

  SummaryBloc({
    required SummaryRepository summaryRepository,
    required AuthBloc authBloc,
    required ConnectionBloc connectionBloc,
    required ManagementSummaryCalculator calculator,
  }) : _summaryRepository = summaryRepository,
       _authBloc = authBloc,
       _connectionBloc = connectionBloc,
       _calculator = calculator,
       super(const SummaryState()) {
    on<SummaryDateRangeChanged>(_onDateRangeChanged);
    on<SummaryDataFetched>(_onDataFetched);
    on<SummaryCleared>(_onSummaryCleared);

    // Configurar el rango de fechas inicial
    final now = DateTime.now();
    add(
      SummaryDateRangeChanged(
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
      ),
    );
  }

  void _onDateRangeChanged(
    SummaryDateRangeChanged event,
    Emitter<SummaryState> emit,
  ) {
    emit(state.copyWith(startDate: event.startDate, endDate: event.endDate));
    // Disparamos el fetch con las nuevas fechas
    add(SummaryDataFetched(startDate: event.startDate, endDate: event.endDate));
  }

  void _onSummaryCleared(SummaryCleared event, Emitter<SummaryState> emit) {
    emit(const SummaryState());
  }

  Future<void> _onDataFetched(
    SummaryDataFetched event,
    Emitter<SummaryState> emit,
  ) async {
    final authState = _authBloc.state;
    final connectionState = _connectionBloc.state;

    if (authState.status == AuthStatus.consolidated) {
      emit(state.copyWith(status: SummaryStatus.loading));
      try {
        List<ManagementSummary> summaries = [];
        for (final connection in connectionState.availableConnections) {
          final token = authState.activeTokens[connection.id];
          if (token == null) continue;

          final summaryData = await _summaryRepository.fetchAllData(
            baseUrl: connection.baseUrl,
            authToken: token,
            configId: connection.configId,
            startDate: event.startDate,
            endDate: event.endDate,
          );

          final calculatedSummary = _calculator.calculate(
            invoices: summaryData.invoices,
            invoiceItems: summaryData.invoiceItems,
            products: summaryData.products,
            receivables: summaryData.receivables,
            payables: summaryData.payables,
            purchases: summaryData.purchases,
            inventoryOps: summaryData.inventoryOps,
            purchaseItems: summaryData.purchaseItems,
            monthlyBudget: summaryData.configuration?.monthlyBudget ?? 0.0,
            startDate: event.startDate,
            endDate: event.endDate,
          );
          summaries.add(calculatedSummary);
        }

        final consolidatedSummary = _consolidateSummaries(summaries);

        emit(
          state.copyWith(
            status: SummaryStatus.success,
            summary: consolidatedSummary,
            allInvoices: [],
            allReceivables: [],
            allPayables: [],
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(status: SummaryStatus.failure, error: e.toString()),
        );
      }
      return;
    }

    if (authState.status != AuthStatus.authenticated ||
        connectionState.activeConnection == null) {
      emit(
        state.copyWith(
          status: SummaryStatus.failure,
          error: AppConstants.noConnectionSelectedMessage,
        ),
      );
      return;
    }

    emit(state.copyWith(status: SummaryStatus.loading));

    try {
      DateTime? previousStartDate;
      DateTime? previousEndDate;

      if (event.startDate != null && event.endDate != null) {
        final duration = event.endDate!.difference(event.startDate!);
        previousEndDate = event.startDate!.subtract(const Duration(days: 1));
        previousStartDate = previousEndDate.subtract(duration);
      }

      final results = await Future.wait([
        _summaryRepository.fetchAllData(
          baseUrl: connectionState.activeConnection!.baseUrl,
          authToken: authState.loginResponse!.authToken!,
          configId: connectionState.activeConnection!.configId,
          startDate: event.startDate,
          endDate: event.endDate,
        ),

        if (previousEndDate != null && previousStartDate != null)
          _summaryRepository.fetchAllData(
            baseUrl: connectionState.activeConnection!.baseUrl,
            authToken: authState.loginResponse!.authToken!,
            configId: connectionState.activeConnection!.configId,
            startDate: previousStartDate,
            endDate: previousEndDate,
          ),
      ]);

      final summaryData = results[0];
      final calculatedSummary = _calculator.calculate(
        invoices: summaryData.invoices,
        invoiceItems: summaryData.invoiceItems,
        products: summaryData.products,
        receivables: summaryData.receivables,
        payables: summaryData.payables,
        purchases: summaryData.purchases,
        inventoryOps: summaryData.inventoryOps,
        purchaseItems: summaryData.purchaseItems,
        monthlyBudget: summaryData.configuration?.monthlyBudget ?? 0.0,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      ManagementSummary previousSummary = const ManagementSummary();
      if (results.length > 1) {
        final previousSummaryData = results[1];
        previousSummary = _calculator.calculate(
          invoices: previousSummaryData.invoices,
          invoiceItems: previousSummaryData.invoiceItems,
          products: previousSummaryData.products,
          receivables: previousSummaryData.receivables,
          payables: previousSummaryData.payables,
          purchases: previousSummaryData.purchases,
          inventoryOps: previousSummaryData.inventoryOps,
          purchaseItems: previousSummaryData.purchaseItems,
          monthlyBudget:
              previousSummaryData.configuration?.monthlyBudget ?? 0.0,
          startDate: previousStartDate!,
          endDate: previousEndDate!,
        );
      }

      emit(
        state.copyWith(
          status: SummaryStatus.success,
          summary: calculatedSummary,
          previousSummary: previousSummary,
          allInvoices: summaryData.invoices,
          allInvoiceItems: summaryData.invoiceItems,
          allReceivables: summaryData.receivables,
          allPayables: summaryData.payables,
          allProducts: summaryData.products,
          allPurchases: summaryData.purchases,
        ),
      );
    } on SessionExpiredException {
      _authBloc.add(AuthLogoutRequested());
      emit(
        state.copyWith(
          status: SummaryStatus.failure,
          error: AppConstants.sessionExpiredMessage,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: SummaryStatus.failure, error: e.toString()));
    }
  }

  ManagementSummary _consolidateSummaries(List<ManagementSummary> summaries) {
    if (summaries.isEmpty) return const ManagementSummary();

    return summaries.reduce((value, element) {
      return ManagementSummary(
        totalNetSalesCredit:
            value.totalNetSalesCredit + element.totalNetSalesCredit,
        totalNetSalesCash: value.totalNetSalesCash + element.totalNetSalesCash,
        totalNetSales: value.totalNetSales + element.totalNetSales,
        costOfGoodsSold: value.costOfGoodsSold + element.costOfGoodsSold,
        grossProfit: value.grossProfit + element.grossProfit,
        netProfitOrLoss: value.netProfitOrLoss + element.netProfitOrLoss,
        currentInventory: value.currentInventory + element.currentInventory,
        fixtureInventory: value.fixtureInventory + element.fixtureInventory,
        totalReceivables: value.totalReceivables + element.totalReceivables,
        totalPayables: value.totalPayables + element.totalPayables,
        overdueReceivables:
            value.overdueReceivables + element.overdueReceivables,
        overduePayables: value.overduePayables + element.overduePayables,
        salesVat: value.salesVat + element.salesVat,
        purchasesVat: value.purchasesVat + element.purchasesVat,
        commissionsPayable:
            value.commissionsPayable + element.commissionsPayable,
        customerAdvances: value.customerAdvances + element.customerAdvances,
        fixedCosts: value.fixedCosts + element.fixedCosts,
        inventoryCharges: value.inventoryCharges + element.inventoryCharges,
        inventoryDischarges:
            value.inventoryDischarges + element.inventoryDischarges,
        netCreditNotes: value.netCreditNotes + element.netCreditNotes,
        netDebitNotes: value.netDebitNotes + element.netDebitNotes,
        purchasesIslrWithheld:
            value.purchasesIslrWithheld + element.purchasesIslrWithheld,
        purchasesIvaWithheld:
            value.purchasesIvaWithheld + element.purchasesIvaWithheld,
        salesIslrWithheld: value.salesIslrWithheld + element.salesIslrWithheld,
        salesIvaWithheld: value.salesIvaWithheld + element.salesIvaWithheld,
        supplierAdvances: value.supplierAdvances + element.supplierAdvances,
      );
    });
  }
}

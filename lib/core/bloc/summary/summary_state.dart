part of 'summary_bloc.dart';

enum SummaryStatus { initial, loading, success, failure }

class SummaryState extends Equatable {
  final SummaryStatus status;
  final ManagementSummary summary;
  final ManagementSummary previousSummary;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? error;

  // Datos brutos para navegación a detalles
  final List<Invoice> allInvoices;
  final List<InvoiceItem> allInvoiceItems;
  final List<AccountReceivable> allReceivables;
  final List<AccountPayable> allPayables;
  final List<Product> allProducts;
  final List<Purchase> allPurchases;

  const SummaryState({
    this.status = SummaryStatus.initial,
    this.summary = const ManagementSummary(),
    this.previousSummary = const ManagementSummary(),
    this.startDate,
    this.endDate,
    this.error,
    this.allInvoices = const [],
    this.allInvoiceItems = const [],
    this.allReceivables = const [],
    this.allPayables = const [],
    this.allProducts = const [],
    this.allPurchases = const [],
  });

  SummaryState copyWith({
    SummaryStatus? status,
    ManagementSummary? summary,
    ManagementSummary? previousSummary,
    DateTime? startDate,
    DateTime? endDate,
    String? error,
    List<Invoice>? allInvoices,
    List<InvoiceItem>? allInvoiceItems,
    List<AccountReceivable>? allReceivables,
    List<AccountPayable>? allPayables,
    List<Product>? allProducts,
    List<Purchase>? allPurchases,
  }) {
    return SummaryState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      previousSummary: previousSummary ?? this.previousSummary,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      error: error,
      allInvoices: allInvoices ?? this.allInvoices,
      allInvoiceItems: allInvoiceItems ?? this.allInvoiceItems,
      allReceivables: allReceivables ?? this.allReceivables,
      allPayables: allPayables ?? this.allPayables,
      allProducts: allProducts ?? this.allProducts,
      allPurchases: allPurchases ?? this.allPurchases,
    );
  }

  @override
  List<Object?> get props => [
    status,
    summary,
    previousSummary,
    startDate,
    endDate,
    error,
    allInvoices,
    allInvoiceItems,
    allReceivables,
    allPayables,
    allProducts,
    allPurchases,
  ];
}

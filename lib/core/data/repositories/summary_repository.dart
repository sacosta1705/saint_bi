import 'package:saint_bi/core/data/sources/remote/saint_api.dart';
import 'package:saint_bi/core/data/models/account_payable.dart';
import 'package:saint_bi/core/data/models/account_receivable.dart';
import 'package:saint_bi/core/data/models/configuration.dart';
import 'package:saint_bi/core/data/models/invoice.dart';
import 'package:saint_bi/core/data/models/invoice_item.dart';
import 'package:saint_bi/core/data/models/inventory_operation.dart';
import 'package:saint_bi/core/data/models/product.dart';
import 'package:saint_bi/core/data/models/purchase.dart';
import 'package:saint_bi/core/data/models/purchase_item.dart';

class SummaryData {
  final List<Invoice> invoices;
  final List<InvoiceItem> invoiceItems;
  final List<Product> products;
  final List<AccountReceivable> receivables;
  final List<Purchase> purchases;
  final List<PurchaseItem> purchaseItems;
  final List<AccountPayable> payables;
  final List<InventoryOperation> inventoryOps;
  final Configuration? configuration;

  SummaryData({
    required this.invoices,
    required this.invoiceItems,
    required this.products,
    required this.receivables,
    required this.purchases,
    required this.purchaseItems,
    required this.payables,
    required this.inventoryOps,
    required this.configuration,
  });
}

class SummaryRepository {
  final SaintApi _apiClient;

  SummaryRepository({required SaintApi apiClient}) : _apiClient = apiClient;

  Future<SummaryData> fetchAllData({
    required String baseUrl,
    required String authToken,
    required int configId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Map<String, String>? dateParams;
    if (startDate != null && endDate != null) {
      final adjustedStartDate = startDate.subtract(const Duration(days: 1));
      final adjustedEndDate = endDate.add(const Duration(days: 1));
      dateParams = {
        'fechae>': adjustedStartDate.toIso8601String().substring(0, 10),
        'fechae<': adjustedEndDate.toIso8601String().substring(0, 10),
      };
    }

    final results = await Future.wait([
      _apiClient.getInvoices(
        baseUrl: baseUrl,
        authtoken: authToken,
        params: dateParams,
      ),
      _apiClient.getInvoiceItems(
        baseUrl: baseUrl,
        authtoken: authToken,
        params: dateParams,
      ),
      _apiClient.getPurchases(
        baseUrl: baseUrl,
        authtoken: authToken,
        params: dateParams,
      ),
      _apiClient.getPurchaseItems(
        baseUrl: baseUrl,
        authtoken: authToken,
        params: dateParams,
      ),
      _apiClient.getInventoryOperations(baseUrl: baseUrl, authtoken: authToken),
      _apiClient.getProducts(baseUrl: baseUrl, authtoken: authToken),
      _apiClient.getAccountsReceivable(baseUrl: baseUrl, authtoken: authToken),
      _apiClient.getAccountsPayable(baseUrl: baseUrl, authtoken: authToken),
      _apiClient.getConfiguration(
        id: configId,
        baseUrl: baseUrl,
        authtoken: authToken,
      ),
    ]);

    final invoices = List.from(
      results[0],
    ).map<Invoice>((e) => Invoice.fromJson(e)).toList();
    final invoiceItems = List.from(
      results[1],
    ).map<InvoiceItem>((e) => InvoiceItem.fromJson(e)).toList();
    final purchases = List.from(
      results[2],
    ).map<Purchase>((e) => Purchase.fromJson(e)).toList();
    final purchaseItems = List.from(
      results[3],
    ).map<PurchaseItem>((e) => PurchaseItem.fromJson(e)).toList();
    final inventoryOps = List.from(
      results[4],
    ).map<InventoryOperation>((e) => InventoryOperation.fromJson(e)).toList();
    final products = List.from(
      results[5],
    ).map<Product>((e) => Product.fromJson(e)).toList();
    final receivables = List.from(
      results[6],
    ).map<AccountReceivable>((e) => AccountReceivable.fromJson(e)).toList();
    final payables = List.from(
      results[7],
    ).map<AccountPayable>((e) => AccountPayable.fromJson(e)).toList();

    Configuration? configuration;
    final configResult = results[8];
    if (configResult is Map<String, dynamic>) {
      configuration = Configuration.fromJson(configResult);
    } else if (configResult is List && configResult.isNotEmpty) {
      configuration = Configuration.fromJson(configResult.first);
    }

    return SummaryData(
      invoices: invoices,
      invoiceItems: invoiceItems,
      products: products,
      receivables: receivables,
      purchases: purchases,
      purchaseItems: purchaseItems,
      payables: payables,
      inventoryOps: inventoryOps,
      configuration: configuration,
    );
  }
}

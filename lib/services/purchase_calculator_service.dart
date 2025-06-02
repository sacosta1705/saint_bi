import 'package:saint_bi/models/purchase.dart';
import 'package:saint_bi/models/purchase_summary.dart';

class PurchaseCalculatorService {
  PurchaseSummary calculateSummary({
    required List<Purchase> allPurchases,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    List<Purchase> purchasesToProcess = allPurchases;
    if (startDate != null || endDate != null) {
      purchasesToProcess = allPurchases.where((purchase) {
        try {
          DateTime purchaseDate = DateTime.parse(purchase.date);
          DateTime normalizedPurchaseDate = DateTime(
            purchaseDate.year,
            purchaseDate.month,
            purchaseDate.day,
          );

          bool isAfterOrOnStartDate = true;
          if (startDate != null) {
            DateTime normalizedStartDate = DateTime(
              startDate.year,
              startDate.month,
              startDate.day,
            );

            isAfterOrOnStartDate = !normalizedPurchaseDate.isBefore(
              normalizedStartDate,
            );
          }

          bool isBeforeOrOnEndDate = true;
          if (endDate != null) {
            DateTime normalizedEndDate = DateTime(
              endDate.year,
              endDate.month,
              endDate.day,
            );
            isBeforeOrOnEndDate = !normalizedPurchaseDate.isAfter(
              normalizedEndDate,
            );
          }
          return isAfterOrOnStartDate && isBeforeOrOnEndDate;
        } catch (e) {
          return false;
        }
      }).toList();
    }

    double tmpTotalPurchases = 0;
    double tmpTotalReturns = 0;
    double tmpTotalTax = 0;
    int tmpPurchasesCount = 0;
    int tmpReturnsCount = 0;

    List<Purchase> purchasesInvoices = [];
    List<Purchase> returnPurchases = [];
    Set<String> returnedDocNumbers = {};

    for (var purchase in purchasesToProcess) {
      if (purchase.type == 'H') purchasesInvoices.add(purchase);
      if (purchase.type == 'I') {
        returnPurchases.add(purchase);
        returnedDocNumbers.add(purchase.docNumber);
      }
    }

    for (var purchaseInvoice in purchasesInvoices) {
      if (!returnedDocNumbers.contains(purchaseInvoice.docNumber)) {
        tmpTotalPurchases += purchaseInvoice.amount;
        tmpTotalTax += purchaseInvoice.amountTax;
        tmpPurchasesCount++;
      }
    }

    for (var returnPurchase in returnPurchases) {
      tmpTotalReturns += returnPurchase.amount;
      tmpReturnsCount++;
    }

    return PurchaseSummary(
      totalPurchases: tmpTotalPurchases,
      totalReturns: tmpTotalReturns,
      totalTax: tmpTotalTax,
      purchasesCount: tmpPurchasesCount,
      returnsCount: tmpReturnsCount,
    );
  }
}

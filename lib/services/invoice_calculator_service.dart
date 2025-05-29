// lib/services/invoice_calculator_service.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:saint_bi/models/invoice.dart';
import 'package:saint_bi/models/invoice_summary.dart';

class InvoiceCalculator {
  InvoiceSummary calculateSummary({
    required List<Invoice> allInvoices,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    List<Invoice> invoicesToProcess = allInvoices;
    if (startDate != null || endDate != null) {
      invoicesToProcess = allInvoices.where((invoice) {
        try {
          DateTime invoiceDate = DateTime.parse(invoice.date);
          DateTime normalizedInvoiceDate = DateTime(
            invoiceDate.year,
            invoiceDate.month,
            invoiceDate.day,
          );

          bool isAfterOrOnStartDate = true;
          if (startDate != null) {
            DateTime normalizedStartDate = DateTime(
              startDate.year,
              startDate.month,
              startDate.day,
            );
            isAfterOrOnStartDate = !normalizedInvoiceDate.isBefore(
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
            isBeforeOrOnEndDate = !normalizedInvoiceDate.isAfter(
              normalizedEndDate,
            );
          }
          return isAfterOrOnStartDate && isBeforeOrOnEndDate;
        } catch (e) {
          debugPrint(
            'Error parseando fecha de factura: ${invoice.date} para filtrado de rango. Error: $e',
          );
          return false;
        }
      }).toList();
      String rangeStr =
          "${startDate != null ? DateFormat('dd/MM/yy').format(startDate) : 'Inicio'} - ${endDate != null ? DateFormat('dd/MM/yy').format(endDate) : 'Fin'}";
      debugPrint(
        'InvoiceCalculator: Después de filtrar por rango [$rangeStr], quedan ${invoicesToProcess.length} facturas.',
      );
    } else {
      debugPrint(
        'InvoiceCalculator: No hay rango de fecha seleccionado, procesando todas las ${allInvoices.length} facturas.',
      );
    }

    double tmpTotalSales = 0;
    double tmpTotalReturns = 0;
    double tmpTotalTax = 0;
    int tmpSalesCount = 0;
    int tmpReturnsCount = 0;

    List<Invoice> salesInvoices = [];
    List<Invoice> returnInvoices = [];
    Set<String> returnedDocNumbers = {};

    for (var invoice in invoicesToProcess) {
      if (invoice.type == 'A') {
        salesInvoices.add(invoice);
      } else if (invoice.type == 'B') {
        returnInvoices.add(invoice);
        returnedDocNumbers.add(invoice.docnumber);
      }
    }

    for (var saleInvoice in salesInvoices) {
      if (!returnedDocNumbers.contains(saleInvoice.docnumber)) {
        tmpTotalSales += saleInvoice.amount;
        tmpTotalTax += saleInvoice.amounttax;
        tmpSalesCount++;
      }
    }

    for (var returnInvoice in returnInvoices) {
      tmpTotalReturns += returnInvoice.amount;
      tmpReturnsCount++;
    }

    debugPrint(
      'InvoiceCalculator: Totales calculados - Ventas=$tmpTotalSales (Count:$tmpSalesCount), Dev=$tmpTotalReturns (Count:$tmpReturnsCount), Imp=$tmpTotalTax',
    );

    return InvoiceSummary(
      totalSales: tmpTotalSales,
      totalReturns: tmpTotalReturns,
      totalTax: tmpTotalTax,
      salesCount: tmpSalesCount,
      returnsCount: tmpReturnsCount,
    );
  }
}

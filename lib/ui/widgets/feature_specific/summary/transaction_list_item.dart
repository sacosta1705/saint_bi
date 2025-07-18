import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saint_bi/core/data/models/account_payable.dart';
import 'package:saint_bi/core/data/models/account_receivable.dart';
import 'package:saint_bi/core/data/models/invoice.dart';
import 'package:saint_bi/core/utils/formatters.dart';
import 'package:saint_bi/ui/pages/transaction_details/invoice_detail_screen.dart';
import 'package:saint_bi/ui/pages/transaction_details/payable_detail_screen.dart';
import 'package:saint_bi/ui/pages/transaction_details/receivable_detail_screen.dart';

Widget buildInvoiceListItem(BuildContext context, Invoice invoice) {
  final deviceLocale = Localizations.localeOf(context).toString();
  final date = DateFormat('yyyy-MM-dd').format(DateTime.parse(invoice.date));
  final isReturned = invoice.sign == -1;

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: ListTile(
      title: Row(
        children: [
          if (isReturned)
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          Expanded(
            child: Text('${invoice.client} - Doc: ${invoice.docnumber}'),
          ),
        ],
      ),
      subtitle: Text('Fecha de Emision: $date'),
      trailing: invoice.credit > 0
          ? Text(formatNumber(invoice.credit, deviceLocale))
          : Text(formatNumber(invoice.cash, deviceLocale)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InvoiceDetailScreen(invoice: invoice),
          ),
        );
      },
    ),
  );
}

Widget buildAccountReceivableListItem(
  BuildContext context,
  AccountReceivable ar,
) {
  final deviceLocale = Localizations.localeOf(context).toString();
  final date = DateFormat('yyyy-MM-dd').format(ar.emissionDate);

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: ListTile(
      title: Text('Cliente: ${ar.docNumber} - Doc: ${ar.docNumber}'),
      subtitle: Text('Fecha de Emision: $date'),
      trailing: Text(formatNumber(ar.balance, deviceLocale)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceivableDetailScreen(accountReceivable: ar),
          ),
        );
      },
    ),
  );
}

Widget buildAccountPayableListItem(BuildContext context, AccountPayable ap) {
  final deviceLocale = Localizations.localeOf(context).toString();
  final date = DateFormat('yyyy-MM-dd').format(ap.emissionDate);

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: ListTile(
      title: Text('Doc: ${ap.docNumber}'),
      subtitle: Text('Fecha de Emision: $date'),
      trailing: Text(formatNumber(ap.balance, deviceLocale)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PayableDetailScreen(accountPayable: ap),
          ),
        );
      },
    ),
  );
}

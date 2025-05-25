import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saint_bi/providers/invoice_notifier.dart';
import 'package:saint_bi/screens/invoice_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InvoiceNotifier(),
      child: MaterialApp(
        title: 'Saint BI',
        home: const InvoiceScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:saint_bi/providers/invoice_notifier.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          InvoiceNotifier(), // InvoiceNotifier ahora carga conexiones al inicio
      child: MaterialApp(
        title: 'Saint BI Multicompañía', // Título actualizado
        home: const InvoiceScreen(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'VE'), // Español Venezuela como preferido
          Locale('en', 'US'), // Inglés USA
        ],
        locale: const Locale('es', 'VE'), // Establecer locale por defecto
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

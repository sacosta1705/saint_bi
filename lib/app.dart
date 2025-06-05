// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale(
            'es',
            'VE',
          ), // Español Venezuela (o el que prefieras, ej: 'ES' para España)
          Locale('en', 'US'), // Inglés USA
        ],
        // locale: const Locale('es', 'VE'), // Opcional: establecer un locale por defecto
        debugShowCheckedModeBanner: false,
        // ThemeData ha sido eliminado de aquí para usar el default de Flutter.
      ),
    );
  }
}

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
      create: (context) =>
          InvoiceNotifier(), // InvoiceNotifier ahora carga conexiones al inicio
      child: MaterialApp(
        title: 'Saint BI Multicompañía', // Título actualizado
        theme: ThemeData(
          // Tema básico, puedes personalizarlo más
          primarySwatch: Colors.indigo, // Un color primario diferente
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.indigo.shade700, // Color del AppBar
            foregroundColor: Colors.white, // Color del texto e iconos en AppBar
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.indigo.shade600, // Color de fondo para ElevatedButton
              foregroundColor:
                  Colors.white, // Color de texto para ElevatedButton
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor:
                  Colors.indigo.shade700, // Color de texto para TextButton
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.indigo.shade700, width: 2.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        home: const InvoiceScreen(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'VE'), // Español Venezuela como preferido
          Locale('es', 'ES'), // Español España
          Locale('en', 'US'), // Inglés USA
        ],
        locale: const Locale('es', 'VE'), // Establecer locale por defecto
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

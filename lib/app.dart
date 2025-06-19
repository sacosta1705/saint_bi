// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:saint_intelligence/providers/managment_summary_notifier.dart';
import 'package:saint_intelligence/screens/loading_acreen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ManagementSummaryNotifier(),
      child: MaterialApp(
        title: 'Saint BI',
        home: const LoadingScreen(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'AR'),
          Locale('es', 'BO'),
          Locale('es', 'CL'),
          Locale('es', 'CO'),
          Locale('es', 'CR'),
          Locale('es', 'CU'),
          Locale('es', 'DO'),
          Locale('es', 'EC'),
          Locale('es', 'SV'),
          Locale('es', 'GT'),
          Locale('es', 'HN'),
          Locale('es', 'MX'),
          Locale('es', 'NI'),
          Locale('es', 'PA'),
          Locale('es', 'PY'),
          Locale('es', 'PE'),
          Locale('es', 'PR'),
          Locale('es', 'UY'),
          Locale('es', 'VE'),
          Locale('es', ''),
          Locale('pt', 'BR'),
          Locale('en', 'US'),
        ],
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

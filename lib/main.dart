// lib/main.dart
import 'package:flutter/material.dart';
// import 'dart:io'; // Solo si necesitas detectar la plataforma para sqflite_common_ffi
// import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Para desktop

import 'package:saint_bi/app.dart';
import 'package:intl/date_symbol_data_local.dart'; // Para inicializar formatos de fecha locales

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar datos de localización para intl (formato de fechas, etc.)
  await initializeDateFormatting('es_VE', null); // Para Venezuela
  await initializeDateFormatting('es_ES', null); // Para España
  // Puedes añadir más locales si los soportas

  // Configuración de sqflite para desktop (Windows, Linux, macOS) si es necesario:
  // if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
  //   sqfliteFfiInit();
  //   databaseFactory = databaseFactoryFfi;
  // }

  runApp(const App());
}

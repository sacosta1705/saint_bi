// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // IMPORTANTE para formatos de fecha locales

import 'package:saint_bi/app.dart';
// Descomenta las siguientes líneas si alguna vez necesitas sqflite_common_ffi para desktop
// import 'dart:io';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // Asegurar que los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar datos de localización para el paquete intl (para formatos de fecha)
  // Esto es importante si usas DateFormat con locales específicos.
  try {
    await initializeDateFormatting('es_VE', null); // Ejemplo para Venezuela
    await initializeDateFormatting('es_ES', null); // Ejemplo para España
    // Añade otros locales que planees soportar explícitamente.
  } catch (e) {
    debugPrint('Error inicializando formatos de fecha: $e');
    // Considera inicializar un locale por defecto en caso de error si es crítico.
    // await initializeDateFormatting('en_US', null);
  }

  // Configuración de sqflite para desktop (Windows, Linux, macOS) si es necesario en el futuro:
  // if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
  //   sqfliteFfiInit();
  //   databaseFactory = databaseFactoryFfi;
  // }

  runApp(const App());
}

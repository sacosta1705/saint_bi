// lib/screens/loading_screen.dart
import 'package:flutter/material.dart';
import 'package:saint_bi/config/app_colors.dart';
import 'package:saint_bi/screens/initial_setup_screen.dart';
import 'package:saint_bi/screens/invoice_screen.dart';
import 'package:saint_bi/services/database_service.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialSetup();
  }

  Future<void> _checkInitialSetup() async {
    await Future.delayed(const Duration(seconds: 2));

    final db = DatabaseService.instance;
    // CORRECCIÓN: Usar el nuevo método que devuelve un mapa
    final settings = await db.getAppSettings();
    final adminPassHash = settings[DatabaseService.columnAdminPasswordHash];
    final defaultApiUser = settings[DatabaseService.columnDefaultApiUser];

    if (!mounted) return;

    // Si alguno de los dos es nulo o vacío, ir a la configuración inicial
    if (adminPassHash == null ||
        adminPassHash.isEmpty ||
        defaultApiUser == null ||
        defaultApiUser.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InitialSetupScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InvoiceScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              'Inicializando...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/screens/loading_screen.dart
import 'package:flutter/material.dart';
import 'package:saint_intelligence/config/app_colors.dart';
import 'package:saint_intelligence/screens/initial_setup_screen.dart';
import 'package:saint_intelligence/screens/login_screen.dart';
import 'package:saint_intelligence/services/database_service.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/saint_logo_blanco.png'), context);
    precacheImage(const AssetImage('assets/saint_logo_azul.png'), context);
  }

  Future<void> _checkInitialSetup() async {
    await Future.delayed(const Duration(seconds: 2));

    final db = DatabaseService.instance;
    // CORRECCIÓN: Usar el nuevo método que devuelve un mapa
    final settings = await db.getAppSettings();
    final adminPassHash = settings[DatabaseService.columnAdminPasswordHash];
    final defaultApiUser = settings[DatabaseService.columnDefaultApiUser];

    if (!mounted) return;

    if (adminPassHash == null ||
        adminPassHash.isEmpty ||
        defaultApiUser == null ||
        defaultApiUser.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InitialSetupScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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

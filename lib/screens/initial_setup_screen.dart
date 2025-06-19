// lib/screens/initial_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // IMPORTANTE: Añadir para usar formatters
import 'package:saint_intelligence/config/app_colors.dart';
import 'package:saint_intelligence/screens/connection_settings_screen.dart';
import 'package:saint_intelligence/services/database_service.dart';
import 'package:saint_intelligence/utils/security_service.dart';

// --- NUEVO: Formatter para convertir texto a mayúsculas en tiempo real ---
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiUserControlller = TextEditingController();
  final _adminPassController = TextEditingController();
  final _confirmAdminPassController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // --- CORRECCIÓN: Asegurarse de guardar en mayúsculas ---
      final apiUser = _apiUserControlller.text.trim().toUpperCase();
      final adminPass = _adminPassController.text;
      final adminPassHash = SecurityService.hashPassword(adminPass);

      await DatabaseService.instance.saveAppSettings(
        defaultApiUser: apiUser,
        adminPasswordHash: adminPassHash,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada exitosamente.'),
          backgroundColor: AppColors.statusMessageSuccess,
        ),
      );

      // Navegamos a la pantalla de Login, que es el siguiente paso lógico
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ConnectionSettingsScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar configuración: $e'),
            backgroundColor: AppColors.statusMessageError,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _apiUserControlller.dispose();
    _adminPassController.dispose();
    _confirmAdminPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_rounded,
                        color: AppColors.primaryBlue, size: 50),
                    const SizedBox(height: 16),
                    Text(
                      'Configuración Inicial',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Estos datos se configurarán una sola vez.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _apiUserControlller,
                      // --- CORRECCIÓN: Aplicar el formatter y la capitalización ---
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Usuario por Defecto para la API',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, ingrese el usuario de la API';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _adminPassController,
                      decoration: const InputDecoration(
                        labelText:
                            'Contraseña de Administrador (para esta app)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingrese una contraseña';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmAdminPassController,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar Contraseña de Administrador',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value != _adminPassController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: AppColors.buttonPrimaryBackground,
                        foregroundColor: AppColors.buttonPrimaryText,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Guardar y Continuar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

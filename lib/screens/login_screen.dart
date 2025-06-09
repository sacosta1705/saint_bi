// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saint_bi/config/app_colors.dart';
import 'package:saint_bi/models/api_connection.dart';
import 'package:saint_bi/providers/invoice_notifier.dart';
import 'package:saint_bi/screens/invoice_screen.dart';
import 'package:saint_bi/services/database_service.dart';
import 'package:saint_bi/services/saint_api.dart';
import 'package:saint_bi/services/saint_api_exceptions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  final DatabaseService _dbService = DatabaseService.instance;
  final SaintApi _saintApi = SaintApi();

  List<ApiConnection> _savedConnections = [];
  ApiConnection? _selectedConnection;
  String? _defaultApiUser;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _dbService.getAppSettings();
      final connections = await _dbService.getAllConnections();
      connections.sort((a, b) =>
          a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()));

      if (mounted) {
        setState(() {
          _defaultApiUser = settings[DatabaseService.columnDefaultApiUser];
          _savedConnections = connections;
          if (_savedConnections.isNotEmpty) {
            _selectedConnection = _savedConnections.first;
          }
        });
      }
    } catch (e) {
      setState(() => _errorMessage = "Error al cargar datos: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedConnection == null) {
      setState(() => _errorMessage = "Por favor, seleccione una empresa.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final loginResponse = await _saintApi.login(
        baseurl: _selectedConnection!.baseUrl,
        username: _defaultApiUser!,
        password: _passwordController.text,
        terminal: _selectedConnection!.terminal,
      );

      if (loginResponse == null ||
          loginResponse.authToken == null ||
          loginResponse.authToken!.isEmpty) {
        throw AuthenticationException(
            "Respuesta de login inválida desde la API.");
      }

      if (mounted) {
        // Obtenemos el notifier y establecemos la conexión activa para que cargue los datos
        final notifier = Provider.of<InvoiceNotifier>(context, listen: false);
        await notifier.setActiveConnection(_selectedConnection!,
            fetchFullData: true);

        // Navegamos a la pantalla de reportes
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const InvoiceScreen()),
        );
      }
    } on SaintApiExceptions catch (e) {
      setState(() => _errorMessage = "Error de inicio de sesión: ${e.msg}");
    } catch (e) {
      setState(
          () => _errorMessage = "Ocurrió un error inesperado: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Inicio de Sesión'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.appBarForeground,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 5,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.security_rounded,
                        color: AppColors.primaryBlue, size: 50),
                    const SizedBox(height: 16),
                    const Text(
                      'Bienvenido',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue),
                    ),
                    const SizedBox(height: 24),

                    // --- Selector de Empresa (Dropdown) ---
                    if (_savedConnections.isNotEmpty)
                      DropdownButtonFormField<ApiConnection>(
                        value: _selectedConnection,
                        items: _savedConnections.map((conn) {
                          return DropdownMenuItem<ApiConnection>(
                            value: conn,
                            child: Text(conn.companyName),
                          );
                        }).toList(),
                        onChanged: (ApiConnection? newValue) {
                          setState(() => _selectedConnection = newValue);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Empresa',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business_rounded),
                        ),
                      )
                    else
                      Text(_isLoading
                          ? "Cargando conexiones..."
                          : "No hay conexiones configuradas."),

                    const SizedBox(height: 16),

                    // --- Campo de Usuario (Solo lectura) ---
                    TextFormField(
                      initialValue: _defaultApiUser ?? 'Cargando...',
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                        fillColor: Colors.black12,
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Campo de Contraseña ---
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Ingrese su contraseña'
                          : null,
                      onFieldSubmitted: (_) => _isLoading ? null : _login(),
                    ),
                    const SizedBox(height: 24),

                    // --- Mensaje de Error ---
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: AppColors.statusMessageError),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // --- Botón de Inicio de Sesión ---
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Ingresar',
                              style: TextStyle(fontSize: 16)),
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

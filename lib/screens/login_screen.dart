// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saint_bi/config/app_colors.dart';
import 'package:saint_bi/models/api_connection.dart';
import 'package:saint_bi/providers/invoice_notifier.dart';
import 'package:saint_bi/screens/connection_settings_screen.dart';
import 'package:saint_bi/screens/invoice_screen.dart';
import 'package:saint_bi/services/database_service.dart';
import 'package:saint_bi/services/saint_api.dart';
import 'package:saint_bi/services/saint_api_exceptions.dart';
import 'package:saint_bi/utils/security_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  // --- CORRECCIÓN: Añadir un controller para el usuario ---
  final _userController = TextEditingController();

  final DatabaseService _dbService = DatabaseService.instance;
  final SaintApi _saintApi = SaintApi();

  List<ApiConnection> _savedConnections = [];
  ApiConnection? _selectedConnection;
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
          // --- CORRECCIÓN: Usar el controller para actualizar el campo de texto ---
          _userController.text =
              settings[DatabaseService.columnDefaultApiUser] ??
                  "Usuario no encontrado";
          _savedConnections = connections;
          // Si hay conexiones, seleccionar la primera por defecto
          if (_savedConnections.isNotEmpty) {
            _selectedConnection = _savedConnections.first;
          } else {
            _selectedConnection = null;
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
        username: _userController.text, // Leer el usuario desde el controller
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
        final notifier = Provider.of<InvoiceNotifier>(context, listen: false);
        await notifier.setActiveConnection(_selectedConnection!,
            fetchFullData: true);

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

  // --- NUEVO: Métodos para navegar a configuración ---
  Future<void> _navigateToSettings(BuildContext context) async {
    final bool? isAuthenticated = await _showAdminPasswordDialog(context);

    if (isAuthenticated == true && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const ConnectionSettingsScreen()),
      );
      // Al volver, recargamos los datos por si se añadió/editó una conexión
      await _loadInitialData();
    }
  }

  Future<bool?> _showAdminPasswordDialog(BuildContext context) {
    final passController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            String? errorText;
            bool isLoading = false;

            return AlertDialog(
              backgroundColor: AppColors.dialogBackground,
              title: const Text('Acceso de Administrador'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: passController,
                  obscureText: true,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    errorText: errorText,
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Ingrese la contraseña'
                      : null,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar',
                      style: TextStyle(color: AppColors.textSecondary)),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setStateInDialog(() => isLoading = true);
                            try {
                              final db = DatabaseService.instance;
                              final settings = await db.getAppSettings();
                              final storedHash = settings[
                                  DatabaseService.columnAdminPasswordHash];

                              if (storedHash == null) {
                                setStateInDialog(() => errorText =
                                    'Error: No hay contraseña configurada.');
                                return;
                              }

                              final isValid = SecurityService.verifyPassword(
                                  passController.text, storedHash);

                              if (isValid) {
                                Navigator.of(dialogContext).pop(true);
                              } else {
                                setStateInDialog(
                                    () => errorText = 'Contraseña incorrecta.');
                              }
                            } catch (e) {
                              setStateInDialog(
                                  () => errorText = 'Error: ${e.toString()}');
                            } finally {
                              setStateInDialog(() => isLoading = false);
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Ingresar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _userController.dispose(); // --- CORRECCIÓN: Disponer el nuevo controller
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
        // --- NUEVO: Botón de acceso a la configuración ---
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurar Conexiones',
            onPressed: () => _navigateToSettings(context),
          )
        ],
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
                    if (_isLoading && _savedConnections.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Cargando conexiones..."),
                      )
                    else if (_savedConnections.isNotEmpty)
                      DropdownButtonFormField<ApiConnection>(
                        isExpanded: true,
                        value: _selectedConnection,
                        items: _savedConnections.map((conn) {
                          return DropdownMenuItem<ApiConnection>(
                            value: conn,
                            child: Text(
                              conn.companyName,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text(
                          "No hay conexiones configuradas. Por favor, añada una desde el menú de configuración (arriba a la derecha).",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _userController,
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

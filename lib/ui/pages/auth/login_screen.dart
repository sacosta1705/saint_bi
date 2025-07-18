import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:saint_bi/core/bloc/auth/auth_bloc.dart';

import 'package:saint_bi/core/bloc/connection/connection_bloc.dart'
    as conn_bloc;
import 'package:saint_bi/core/data/models/api_connection.dart';
import 'package:saint_bi/core/data/repositories/connection_repository.dart';
import 'package:saint_bi/ui/pages/connection/connection_settings_screen.dart';
import 'package:saint_bi/ui/pages/summary/managment_summary_screen.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';
import 'package:saint_bi/ui/widgets/common/admin_password_dialog.dart';
import 'package:saint_bi/core/data/sources/local/database_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _userController = TextEditingController();
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _loadVersionInfo();
    final repo = context.read<ConnectionRepository>();
    final settings = await repo.getAppSettings();
    if (mounted) {
      setState(() {
        _userController.text =
            settings[DatabaseService.columnDefaultApiUser] ?? '';
      });
    }
  }

  Future<void> _loadVersionInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = 'v${info.version}');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // Obtenemos la conexión activa desde el estado del ConnectionBloc
    final connection = context
        .read<conn_bloc.ConnectionBloc>()
        .state
        .activeConnection;

    if (connection == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Por favor, seleccione una conexión.'),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }

    // Despachamos el evento al AuthBloc
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        connection: connection,
        password: _passwordController.text,
      ),
    );
  }

  Future<void> _navigateToSettings(BuildContext context) async {
    final bool? isAuthenticated = await showAdminPasswordDialog(context);

    if (isAuthenticated == true && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ConnectionSettingsScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _userController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated ||
            state.status == AuthStatus.consolidated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ManagementSummaryScreen()),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inicio de Sesión'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Configurar Conexiones',
              onPressed: () => _navigateToSettings(context),
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        constraints: const BoxConstraints(
                          maxHeight: 120,
                          maxWidth: 400,
                        ),
                        child: Image.asset('assets/saint_logo_azul.png'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Bienvenido',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 24),

                      BlocBuilder<
                        conn_bloc.ConnectionBloc,
                        conn_bloc.ConnectionState
                      >(
                        builder: (context, state) {
                          if (state.status ==
                              conn_bloc.ConnectionStatus.loading) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (state.availableConnections.isNotEmpty) {
                            return DropdownButtonFormField<ApiConnection>(
                              isExpanded: true,
                              value: state.activeConnection,
                              items: state.availableConnections.map((conn) {
                                return DropdownMenuItem<ApiConnection>(
                                  value: conn,
                                  child: Text(
                                    conn.companyAlias,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (ApiConnection? newValue) {
                                context.read<conn_bloc.ConnectionBloc>().add(
                                  conn_bloc.ConnectionSelected(newValue),
                                );
                              },
                              decoration: const InputDecoration(
                                labelText: 'Conexión (Alias)',
                                prefixIcon: Icon(Icons.business_rounded),
                              ),
                            );
                          }

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red),
                            ),
                            child: const Text(
                              "No hay conexiones configuradas. Añada una desde el menú de configuración.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _userController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
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
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Ingrese su contraseña'
                            : null,
                        onFieldSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 24),

                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state.status == AuthStatus.unauthenticated &&
                              state.error != null) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                state.error!,
                                style: const TextStyle(
                                  color: AppColors.statusMessageError,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state.status == AuthStatus.loading;
                          final activeConnection = context
                              .watch<conn_bloc.ConnectionBloc>()
                              .state
                              .activeConnection;
                          return ElevatedButton(
                            onPressed: isLoading || activeConnection == null
                                ? null
                                : _login,
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text('Ingresar'),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      BlocBuilder<
                        conn_bloc.ConnectionBloc,
                        conn_bloc.ConnectionState
                      >(
                        builder: (context, state) {
                          final authState = context.watch<AuthBloc>().state;
                          final canConsolidate =
                              state.availableConnections.length > 1 &&
                              authState.status != AuthStatus.loading;

                          return TextButton.icon(
                            icon: const Icon(Icons.hub_outlined),
                            label: const Text('Ver Resumen Consolidado'),
                            onPressed: canConsolidate
                                ? () {
                                    if (_passwordController.text.isNotEmpty) {
                                      context.read<AuthBloc>().add(
                                        AuthConsolidatedRequested(
                                          password: _passwordController.text,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                        ..hideCurrentSnackBar()
                                        ..showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Ingrese la clave. Se asume que la clave de acceso sera igual para todas las conexiones',
                                            ),
                                            backgroundColor:
                                                AppColors.accentColor,
                                          ),
                                        );
                                    }
                                  }
                                : null,
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                      Text(
                        _version,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

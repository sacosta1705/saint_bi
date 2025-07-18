import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_bi/core/bloc/connection/connection_bloc.dart'
    as conn_bloc;
import 'package:saint_bi/core/data/sources/remote/saint_api.dart';
import 'package:saint_bi/core/data/sources/remote/saint_api_exceptions.dart';
import 'package:saint_bi/core/data/sources/local/database_service.dart';
import 'package:saint_bi/core/data/models/api_connection.dart';
import 'package:saint_bi/core/data/models/permissions.dart';
import 'package:saint_bi/core/data/repositories/connection_repository.dart';
import 'package:saint_bi/ui/pages/auth/login_screen.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';

class ConnectionSettingsScreen extends StatefulWidget {
  const ConnectionSettingsScreen({super.key});
  @override
  State<ConnectionSettingsScreen> createState() =>
      _ConnectionSettingsScreenState();
}

class _ConnectionSettingsScreenState extends State<ConnectionSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pollingIntervalController = TextEditingController(text: '300');
  final _terminalController = TextEditingController(text: 'terminal');
  final _companyNameController = TextEditingController();
  final _companyAliasController = TextEditingController();
  final _configIdController = TextEditingController(text: '1');
  final _userController = TextEditingController();

  ApiConnection? _connectionBeingEdited;
  bool _isTestingConnection = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultUser();
  }

  Future<void> _loadDefaultUser() async {
    final repo = context.read<ConnectionRepository>();
    final settings = await repo.getAppSettings();
    if (mounted) {
      setState(() {
        _userController.text =
            settings[DatabaseService.columnDefaultApiUser] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _passwordController.dispose();
    _pollingIntervalController.dispose();
    _terminalController.dispose();
    _companyNameController.dispose();
    _companyAliasController.dispose();
    _configIdController.dispose();
    _userController.dispose();
    super.dispose();
  }

  void _editConnection(ApiConnection connection) {
    setState(() {
      _connectionBeingEdited = connection;
      _baseUrlController.text = connection.baseUrl;
      _passwordController.text = connection.password;
      _pollingIntervalController.text = connection.pollingIntervalSeconds
          .toString();
      _terminalController.text = connection.terminal;
      _companyNameController.text = connection.companyName;
      _companyAliasController.text = connection.companyAlias;
      _configIdController.text = connection.configId.toString();
    });
  }

  void _clearForm() {
    setState(() {
      _formKey.currentState?.reset();
      _connectionBeingEdited = null;
      _baseUrlController.clear();
      _passwordController.clear();
      _pollingIntervalController.text = '300';
      _terminalController.text = 'terminal';
      _companyNameController.clear();
      _companyAliasController.clear();
      _configIdController.text = '1';
    });
  }

  Future<void> _testAndSaveConnection() async {
    if (!_formKey.currentState!.validate()) return;

    final bool isFirstConnection = context
        .read<conn_bloc.ConnectionBloc>()
        .state
        .availableConnections
        .isEmpty;

    setState(() => _isTestingConnection = true);

    final username = _userController.text;

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error crítico: No se encontró el usuario API por defecto. Reinstale la aplicación.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isTestingConnection = false);
      return;
    }

    final connectionData = ApiConnection(
      id: _connectionBeingEdited?.id,
      baseUrl: _baseUrlController.text.trim().replaceAll(RegExp(r'/$'), ''),
      username: username,
      password: _passwordController.text,
      pollingIntervalSeconds: int.parse(_pollingIntervalController.text.trim()),
      companyName: '',
      companyAlias: _companyAliasController.text.trim(),
      terminal: _terminalController.text.trim(),
      permissions: Permissions(canViewSales: true),
      configId: int.parse(_configIdController.text.trim()),
    );

    final saintApiClient = context.read<SaintApi>();
    try {
      final loginResponse = await saintApiClient.login(
        baseurl: connectionData.baseUrl,
        username: connectionData.username,
        password: connectionData.password,
        terminal: connectionData.terminal,
      );

      if (loginResponse == null || loginResponse.authToken == null) {
        throw AuthenticationException("La prueba de conexión falló.");
      }

      final finalConnection = connectionData.copyWith(
        companyName: loginResponse.company,
      );

      if (_connectionBeingEdited != null) {
        context.read<conn_bloc.ConnectionBloc>().add(
          conn_bloc.ConnectionUpdated(finalConnection),
        );
      } else {
        context.read<conn_bloc.ConnectionBloc>().add(
          conn_bloc.ConnectionAdded(finalConnection),
        );
      }

      if (!mounted) return;

      if (isFirstConnection && _connectionBeingEdited == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                '¡Conexión guardada! Redirigiendo al inicio de sesión...',
              ),
              backgroundColor: AppColors.statusMessageSuccess,
            ),
          );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Conexión para "${finalConnection.companyName}" guardada.',
            ),
            backgroundColor: AppColors.statusMessageSuccess,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.statusMessageError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTestingConnection = false);
    }
  }

  Future<void> _deleteConnection(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Seguro que quieres eliminar esta conexión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<conn_bloc.ConnectionBloc>().add(
        conn_bloc.ConnectionDeleted(id),
      );
      if (_connectionBeingEdited?.id == id) {
        _clearForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentlyEditing = _connectionBeingEdited != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCurrentlyEditing ? 'Editar Conexión' : 'Nueva Conexión'),
        actions: [
          if (isCurrentlyEditing)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Crear Nueva Conexión',
              onPressed: _isTestingConnection ? null : _clearForm,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey,
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        isCurrentlyEditing
                            ? 'Editando: "${_connectionBeingEdited?.companyAlias ?? ''}"'
                            : "Detalles de la Nueva Conexión",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _userController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Usuario API',
                          hintText: '',
                          prefixIcon: Icon(Icons.person_rounded),
                        ).copyWith(fillColor: Colors.grey.shade200),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _companyNameController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Nombre de Empresa',
                          hintText: 'Se completará al probar la conexión',
                          prefixIcon: Icon(Icons.business_center_outlined),
                        ).copyWith(fillColor: Colors.grey.shade200),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _baseUrlController,
                        decoration: InputDecoration(
                          labelText:
                              'URL del SAINT Enterprise Administrativo *',
                          hintText: 'ej: http://tu-servidor.com/api',
                          prefixIcon: Icon(Icons.http_rounded),
                        ),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa la URL base';
                          }
                          final uri = Uri.tryParse(value.trim());
                          if (uri == null || !uri.isAbsolute) {
                            return 'URL no válida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _companyAliasController,
                        decoration: InputDecoration(
                          labelText: 'Alias de la conexión *',
                          hintText: 'Ej: Sede principal',
                          prefixIcon: Icon(Icons.label_important),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, ingrese un alias.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Clave Enterprise Administrativo *',
                          hintText: 'Clave de acceso al Administrativo',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        obscureText: true,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Ingresa la clave'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pollingIntervalController,
                        decoration: InputDecoration(
                          labelText: 'Intervalo de refrescamiento (segundos) *',
                          hintText: 'Ej: 300',
                          prefixIcon: Icon(Icons.timer_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el intervalo';
                          }
                          final interval = int.tryParse(value.trim());
                          if (interval == null || interval < 0) {
                            return 'Debe ser >= 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _terminalController,
                        decoration: InputDecoration(
                          labelText: 'Nombre del Terminal *',
                          hintText: 'Ej: AppMovilVentas01',
                          prefixIcon: Icon(Icons.devices_other_rounded),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Ingresa el nombre del terminal'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _configIdController,
                        decoration: InputDecoration(
                          labelText: 'ID de la configuración *',
                          hintText: 'Ej: 1',
                          prefixIcon: Icon(Icons.settings_input_component),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el ID de la configuración';
                          }
                          final id = int.tryParse(value.trim());
                          if (id == null || id <= 0) {
                            return 'El ID debe ser un valor númerico mayor a cero (0).';
                          }
                          return null;
                        },
                      ),
                      const Divider(height: 32),
                      ElevatedButton.icon(
                        icon: _isTestingConnection
                            ? Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(right: 8),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                isCurrentlyEditing
                                    ? Icons.save_alt_rounded
                                    : Icons.add_link_rounded,
                                size: 20,
                              ),
                        label: Text(
                          _isTestingConnection
                              ? "Probando..."
                              : (isCurrentlyEditing
                                    ? 'Actualizar Conexión'
                                    : 'Probar y Guardar'),
                        ),
                        onPressed: _isTestingConnection
                            ? null
                            : _testAndSaveConnection,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          backgroundColor: isCurrentlyEditing
                              ? AppColors.primaryOrange
                              : AppColors.buttonPrimaryBackground,
                          foregroundColor: isCurrentlyEditing
                              ? AppColors.textOnPrimaryOrange
                              : AppColors.buttonPrimaryText,
                        ),
                      ),
                      if (isCurrentlyEditing) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            size: 20,
                          ),
                          label: const Text(
                            'Crear Nueva (Limpiar Formulario)',
                            style: TextStyle(fontSize: 15),
                          ),
                          onPressed: _isTestingConnection ? null : _clearForm,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Divider(thickness: 1),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "Conexiones Guardadas",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),

              BlocBuilder<conn_bloc.ConnectionBloc, conn_bloc.ConnectionState>(
                builder: (context, state) {
                  if (state.status == conn_bloc.ConnectionStatus.loading &&
                      state.availableConnections.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.availableConnections.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Aún no has guardado ninguna conexión.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.availableConnections.length,
                    itemBuilder: (context, index) {
                      final connection = state.availableConnections[index];
                      final bool isActive =
                          state.activeConnection?.id == connection.id;

                      return Card(
                        elevation: isActive ? 4 : 2,
                        margin: const EdgeInsets.symmetric(vertical: 7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isActive
                                ? AppColors.primaryBlue
                                : AppColors.dividerColor,
                            width: isActive ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 16.0,
                          ),
                          leading: Icon(
                            isActive ? Icons.lan_rounded : Icons.link_rounded,
                            color: isActive
                                ? AppColors.primaryOrange
                                : AppColors.primaryBlue,
                            size: 32,
                          ),
                          title: Text(
                            connection.companyAlias,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.5,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                connection.companyName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'Usuario: ${connection.username} | Terminal: ${connection.terminal}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_note_rounded,
                                  size: 28,
                                ),
                                tooltip: 'Editar esta conexión',
                                color: AppColors.primaryBlue,
                                onPressed: _isTestingConnection
                                    ? null
                                    : () => _editConnection(connection),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_forever_rounded,
                                  size: 28,
                                ),
                                tooltip: 'Eliminar esta conexión',
                                color: AppColors.statusMessageError,
                                onPressed: _isTestingConnection
                                    ? null
                                    : () => _deleteConnection(connection.id!),
                              ),
                            ],
                          ),
                          onTap: () {
                            context.read<conn_bloc.ConnectionBloc>().add(
                              conn_bloc.ConnectionSelected(connection),
                            );
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Conexión "${connection.companyAlias}" seleccionada.',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

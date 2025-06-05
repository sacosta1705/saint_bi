// lib/screens/connection_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:saint_bi/models/api_connection.dart';
import 'package:saint_bi/models/login_response.dart';
import 'package:saint_bi/services/database_service.dart';
import 'package:saint_bi/services/saint_api.dart';
import 'package:saint_bi/services/saint_api_exceptions.dart';
import 'package:saint_bi/providers/invoice_notifier.dart';
// import 'package:saint_bi/utils/debug_file_logger.dart'; // ELIMINADO
import 'package:saint_bi/config/app_colors.dart';

class ConnectionSettingsScreen extends StatefulWidget {
  final ApiConnection? connectionToEdit;
  const ConnectionSettingsScreen({super.key, this.connectionToEdit});

  @override
  State<ConnectionSettingsScreen> createState() =>
      _ConnectionSettingsScreenState();
}

class _ConnectionSettingsScreenState extends State<ConnectionSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pollingIntervalController = TextEditingController();
  final _terminalController = TextEditingController();
  final _companyNameController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  List<ApiConnection> _savedConnections = [];

  final SaintApi _saintApi = SaintApi();
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    // DebugFileLogger.log("[ConnectionSettingsScreen.initState] Iniciando pantalla."); // ELIMINADO
    debugPrint(
        "[ConnectionSettingsScreen.initState] Iniciando pantalla."); // Opcional: mantener debugPrint
    if (widget.connectionToEdit != null) {
      _isEditing = true;
      _populateFormForEditing(widget.connectionToEdit!);
      debugPrint(
          "[ConnectionSettingsScreen.initState] Editando conexión ID: ${widget.connectionToEdit!.id}, Empresa: ${widget.connectionToEdit!.companyName}");
    } else {
      _terminalController.text = 'saint_bi_flutter_app';
      _pollingIntervalController.text = '300';
      debugPrint(
          "[ConnectionSettingsScreen.initState] Creando nueva conexión.");
    }
    _loadSavedConnections();
  }

  void _populateFormForEditing(ApiConnection conn) {
    _baseUrlController.text = conn.baseUrl;
    _usernameController.text = conn.username;
    _passwordController.text = conn.password;
    _pollingIntervalController.text = conn.pollingIntervalSeconds.toString();
    _terminalController.text = conn.terminal;
    _companyNameController.text = conn.companyName;
  }

  Future<void> _loadSavedConnections() async {
    final String operation = "[ConnectionSettingsScreen._loadSavedConnections]";
    debugPrint(
        "$operation Iniciando carga de conexiones guardadas."); // Opcional
    if (!mounted) {
      debugPrint("$operation Abortado: Widget no montado."); // Opcional
      return;
    }
    setState(() => _isLoading = true);
    try {
      _savedConnections = await _dbService.getAllConnections();
      _savedConnections.sort((a, b) =>
          a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()));
      debugPrint(
          "$operation ${_savedConnections.length} conexiones cargadas."); // Opcional
    } catch (e) {
      debugPrint(
          "$operation Error cargando conexiones: ${e.toString()}"); // Opcional
      _setErrorMessage('Error al cargar conexiones: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setErrorMessage(String? message) {
    if (mounted) {
      if (message != null) {
        debugPrint(
            "[ConnectionSettingsScreen._setErrorMessage] Mostrando error en UI: $message"); // Opcional
      }
      setState(() {
        if (message != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message,
                  style: const TextStyle(color: AppColors.textOnPrimaryOrange)),
              backgroundColor: AppColors.primaryOrange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
    }
  }

  void _clearForm() {
    debugPrint(
        "[ConnectionSettingsScreen._clearForm] Limpiando formulario."); // Opcional
    _formKey.currentState?.reset();
    _baseUrlController.clear();
    _usernameController.clear();
    _passwordController.clear();
    _pollingIntervalController.text = '300';
    _terminalController.text = 'saint_bi_flutter_app';
    _companyNameController.clear();
    if (mounted) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _testAndSaveConnection() async {
    final String operation =
        "[ConnectionSettingsScreen._testAndSaveConnection]";
    debugPrint(
        "$operation Iniciando proceso de prueba y guardado."); // Opcional

    if (!_formKey.currentState!.validate()) {
      debugPrint("$operation Formulario no válido."); // Opcional
      return;
    }
    _setErrorMessage(null);
    if (mounted) setState(() => _isLoading = true);

    final baseUrl = _baseUrlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final pollingInterval =
        int.tryParse(_pollingIntervalController.text.trim());
    final terminal = _terminalController.text.trim();

    debugPrint(
        "$operation Datos del formulario: baseUrl=$baseUrl, username=$username, pollingInterval=$pollingInterval, terminal=$terminal, isEditing=$_isEditing"); // Opcional (no loguear password)

    if (pollingInterval == null || pollingInterval <= 0) {
      _setErrorMessage('El intervalo debe ser un número positivo.');
      debugPrint(
          "$operation Error: Intervalo no válido ($pollingInterval)."); // Opcional
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      debugPrint("$operation Llamando a _saintApi.login..."); // Opcional
      final LoginResponse? loginResponse = await _saintApi.login(
          baseurl: baseUrl,
          username: username,
          password: password,
          terminal: terminal);

      if (loginResponse == null ||
          loginResponse.authToken == null ||
          loginResponse.authToken!.isEmpty) {
        debugPrint(
            "$operation Login fallido o respuesta inválida de API."); // Opcional
        throw AuthenticationException(
            'Fallo el inicio de sesión. No se recibieron datos de empresa o token válidos de la API.');
      }

      final String companyNameFromApi = loginResponse.company;
      debugPrint(
          "$operation Login exitoso. Empresa API: \"$companyNameFromApi\", Token: \"${loginResponse.authToken}\""); // Opcional

      if (mounted) {
        _companyNameController.text = companyNameFromApi;
      }

      final connection = ApiConnection(
        id: _isEditing ? widget.connectionToEdit!.id : null,
        baseUrl: baseUrl,
        username: username,
        password: password,
        pollingIntervalSeconds: pollingInterval,
        companyName: companyNameFromApi,
        terminal: terminal,
      );
      // debugPrintMap("$operation Objeto ApiConnection a guardar/actualizar:", connection.toMap()..['password'] = '[OCULTO]'); // Opcional

      final notifier = Provider.of<InvoiceNotifier>(context, listen: false);
      ApiConnection? connectionForNavigationResult;

      if (_isEditing) {
        debugPrint(
            "$operation Modo edición: Intentando actualizar conexión ID ${connection.id}."); // Opcional
        final existingByName =
            await _dbService.getConnectionByCompanyName(companyNameFromApi);
        if (existingByName != null && existingByName.id != connection.id) {
          debugPrint(
              "$operation Error: Ya existe otra conexión con el nombre de empresa \"$companyNameFromApi\" (ID: ${existingByName.id})."); // Opcional
          throw Exception(
              'Ya existe otra conexión guardada para la empresa "$companyNameFromApi".');
        }
        await _dbService.updateConnection(connection);
        notifier.updateConnectionInList(connection);
        connectionForNavigationResult = connection;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Conexión para "${connection.companyName}" actualizada.'),
            backgroundColor: AppColors.statusMessageSuccess,
          ));
        }
      } else {
        debugPrint(
            "$operation Modo creación: Intentando insertar nueva conexión."); // Opcional
        final existingByName =
            await _dbService.getConnectionByCompanyName(companyNameFromApi);
        if (existingByName != null) {
          debugPrint(
              "$operation Error: Ya existe conexión para \"$companyNameFromApi\" (ID: ${existingByName.id})."); // Opcional
          throw Exception(
              'Ya existe una conexión guardada para la empresa "$companyNameFromApi".');
        }
        final newId = await _dbService.insertConnection(connection);
        final newSavedConnection = connection.copyWith(id: newId);
        notifier.addConnectionToList(newSavedConnection);
        connectionForNavigationResult = newSavedConnection;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Conexión para "${connection.companyName}" guardada.'),
            backgroundColor: AppColors.statusMessageSuccess,
          ));
        }
      }
      _clearForm();
      _loadSavedConnections();

      if (mounted) {
        Navigator.of(context).pop(connectionForNavigationResult);
      }
    } on AuthenticationException catch (e) {
      debugPrint("$operation AuthenticationException: ${e.msg}"); // Opcional
      _setErrorMessage('Error de Autenticación: ${e.msg}');
    } on NetworkException catch (e) {
      debugPrint("$operation NetworkException: ${e.msg}"); // Opcional
      _setErrorMessage('Error de Red: ${e.msg}');
    } on UnknownApiExpection catch (e) {
      debugPrint("$operation UnknownApiException: ${e.msg}"); // Opcional
      _setErrorMessage('Error de API: ${e.msg}');
    } catch (e, s) {
      debugPrint(
          "$operation Excepción General: ${e.toString()}\nStack: $s"); // Opcional
      _setErrorMessage('Error: ${e.toString()}');
    } finally {
      debugPrint(
          "$operation Proceso de prueba y guardado finalizado."); // Opcional
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteConnection(int id, String companyName) async {
    final String operation = "[ConnectionSettingsScreen._deleteConnection]";
    debugPrint(
        "$operation Solicitando confirmación para eliminar ID $id ($companyName)."); // Opcional

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.dialogBackground,
          title: const Text('Confirmar Eliminación',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Text(
              '¿Estás seguro de eliminar la conexión para "$companyName"?',
              style: const TextStyle(color: AppColors.textSecondary)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.primaryBlue)),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.statusMessageError),
              child: const Text('Eliminar'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      debugPrint("$operation Confirmado. Eliminando ID $id."); // Opcional
      if (mounted) setState(() => _isLoading = true);
      try {
        await _dbService.deleteConnection(id);
        if (_isEditing && widget.connectionToEdit?.id == id) {
          _clearForm();
        }
        if (mounted) {
          Provider.of<InvoiceNotifier>(context, listen: false)
              .removeConnectionFromList(id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Conexión para "$companyName" eliminada.'),
                backgroundColor: AppColors.primaryOrange),
          );
        }
        _loadSavedConnections();
      } catch (e) {
        debugPrint("$operation Error al eliminar: ${e.toString()}"); // Opcional
        _setErrorMessage('Error al eliminar: ${e.toString()}');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      debugPrint("$operation Eliminación cancelada para ID $id."); // Opcional
    }
  }

  void _editConnection(ApiConnection connection) {
    debugPrint(
        "[ConnectionSettingsScreen._editConnection] Cargando datos para editar conexión ID ${connection.id}."); // Opcional
    if (mounted) {
      setState(() {
        _isEditing = true;
        _populateFormForEditing(connection);
      });
    }
  }

  @override
  void dispose() {
    debugPrint(
        "[ConnectionSettingsScreen.dispose] Pantalla eliminada."); // Opcional
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pollingIntervalController.dispose();
    _terminalController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.primaryBlue),
      hintStyle: TextStyle(color: AppColors.textSecondary),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        borderSide: BorderSide(color: AppColors.inputBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        borderSide: BorderSide(color: AppColors.inputBorderColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        borderSide:
            BorderSide(color: AppColors.inputFocusedBorderColor, width: 2.0),
      ),
      prefixIcon: Icon(icon, color: AppColors.inputPrefixIconColor),
      filled: true,
      fillColor: AppColors.cardBackground,
    );
  }

  // El método build() se mantiene igual que en la versión anterior con colores,
  // ya que el logging estaba principalmente en los métodos de lógica.
  // Lo incluyo completo para evitar confusiones.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Conexión' : 'Nueva Conexión API',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
        elevation: 1,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Crear Nueva Conexión',
              onPressed: _isLoading ? null : _clearForm,
              color: AppColors.appBarForeground,
            )
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
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey,
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        )
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _isEditing
                            ? 'Editando: "${widget.connectionToEdit?.companyName}"'
                            : "Detalles de la Nueva Conexión",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _companyNameController,
                        readOnly: true,
                        decoration: _inputDecoration(
                                'Nombre de Empresa (obtenido de API)',
                                'Se completará al probar la conexión',
                                Icons.business_center_outlined)
                            .copyWith(fillColor: AppColors.inputBorderColor),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _baseUrlController,
                        decoration: _inputDecoration(
                            'URL Base de la API *',
                            'ej: http://tu-servidor.com/api',
                            Icons.http_rounded),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa la URL base';
                          }
                          final uri = Uri.tryParse(value.trim());
                          if (uri == null ||
                              !uri.isAbsolute ||
                              (uri.scheme != 'http' && uri.scheme != 'https')) {
                            return 'Ingresa una URL válida (ej: http://...)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        decoration: _inputDecoration('Nombre de Usuario API *',
                            'Usuario de API', Icons.person_outline_rounded),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el nombre de usuario';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: _inputDecoration('Contraseña API *',
                            'Contraseña', Icons.lock_outline_rounded),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa la contraseña';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pollingIntervalController,
                        decoration: _inputDecoration('Intervalo (segundos) *',
                            'Ej: 300', Icons.timer_outlined),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el intervalo';
                          }
                          final interval = int.tryParse(value.trim());
                          if (interval == null || interval <= 0) {
                            return 'Debe ser > 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _terminalController,
                        decoration: _inputDecoration(
                            'Nombre del Terminal *',
                            'Ej: AppMovilVentas01',
                            Icons.devices_other_rounded),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el nombre del terminal';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: _isLoading
                            ? Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(right: 8),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ))
                            : Icon(
                                _isEditing
                                    ? Icons.save_alt_rounded
                                    : Icons.add_link_rounded,
                                size: 20),
                        label: Text(
                            _isLoading
                                ? "Probando..."
                                : (_isEditing
                                    ? 'Actualizar Conexión'
                                    : 'Probar y Guardar'),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                        onPressed: _isLoading ? null : _testAndSaveConnection,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: _isEditing
                              ? AppColors.primaryOrange
                              : AppColors.buttonPrimaryBackground,
                          foregroundColor: _isEditing
                              ? AppColors.textOnPrimaryOrange
                              : AppColors.buttonPrimaryText,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                        ),
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add_circle_outline_rounded,
                              size: 20),
                          label: const Text('Crear Nueva (Limpiar Formulario)',
                              style: TextStyle(fontSize: 15)),
                          onPressed: _isLoading ? null : _clearForm,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            foregroundColor: AppColors.primaryBlue,
                            side: const BorderSide(
                                color: AppColors.primaryBlue, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Divider(thickness: 1, color: AppColors.dividerColor),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text("Conexiones Guardadas",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
              if (_isLoading && _savedConnections.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child:
                      CircularProgressIndicator(color: AppColors.primaryOrange),
                ))
              else if (_savedConnections.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Aún no has guardado ninguna conexión.',
                      style: TextStyle(
                          fontSize: 16, color: AppColors.textSecondary)),
                ))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _savedConnections.length,
                  itemBuilder: (context, index) {
                    final connection = _savedConnections[index];
                    final bool isCurrentlyEditingThis = _isEditing &&
                        widget.connectionToEdit?.id == connection.id;
                    final bool isActiveInNotifier =
                        Provider.of<InvoiceNotifier>(context, listen: false)
                                .activeConnection
                                ?.id ==
                            connection.id;

                    return Card(
                      elevation: isCurrentlyEditingThis
                          ? 5
                          : (isActiveInNotifier ? 3 : 1.5),
                      color: isCurrentlyEditingThis
                          ? AppColors.primaryOrange
                          : (isActiveInNotifier
                              ? AppColors.cardBackground
                              : AppColors.accentColor),
                      margin: const EdgeInsets.symmetric(vertical: 7),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isCurrentlyEditingThis
                                ? AppColors.primaryOrange
                                : (isActiveInNotifier
                                    ? AppColors.primaryBlue
                                    : AppColors.dividerColor),
                            width: isCurrentlyEditingThis || isActiveInNotifier
                                ? 1.5
                                : 1,
                          )),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 16.0),
                        leading: Icon(
                          isActiveInNotifier
                              ? Icons.lan_rounded
                              : Icons.link_rounded,
                          color: isActiveInNotifier
                              ? AppColors.primaryOrange
                              : AppColors.primaryBlue,
                          size: 32,
                        ),
                        title: Text(connection.companyName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.5,
                                color: AppColors.textPrimary)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(connection.baseUrl,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                            Text(
                                'Usuario: ${connection.username} | Terminal: ${connection.terminal}',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary)),
                            Text(
                                'Intervalo: ${connection.pollingIntervalSeconds} seg.',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.edit_note_rounded, size: 28),
                              tooltip: 'Editar esta conexión',
                              color: AppColors.primaryBlue,
                              onPressed: _isLoading
                                  ? null
                                  : () => _editConnection(connection),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever_rounded,
                                  size: 28),
                              tooltip: 'Eliminar esta conexión',
                              color: AppColors.statusMessageError,
                              onPressed: _isLoading
                                  ? null
                                  : () => _deleteConnection(
                                      connection.id!, connection.companyName),
                            ),
                          ],
                        ),
                        onTap: () {
                          final notifier = Provider.of<InvoiceNotifier>(context,
                              listen: false);
                          if (isActiveInNotifier && !notifier.isLoading) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '${connection.companyName} ya está activa.'),
                                  duration: const Duration(seconds: 2)),
                            );
                            Navigator.of(context).pop(connection);
                            return;
                          }
                          notifier.setActiveConnection(connection,
                              fetchFullData: true);
                          Navigator.of(context).pop(connection);
                        },
                      ),
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

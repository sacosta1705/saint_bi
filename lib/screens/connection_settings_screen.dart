import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:saint_intelligence/models/permissions.dart';
import 'package:saint_intelligence/models/api_connection.dart';
import 'package:saint_intelligence/models/login_response.dart';
import 'package:saint_intelligence/screens/login_screen.dart';
import 'package:saint_intelligence/services/database_service.dart';
import 'package:saint_intelligence/services/saint_api.dart';
import 'package:saint_intelligence/services/saint_api_exceptions.dart';
import 'package:saint_intelligence/providers/managment_summary_notifier.dart';
import 'package:saint_intelligence/config/app_colors.dart';

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
  final _pollingIntervalController = TextEditingController();
  final _terminalController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyAliasController = TextEditingController();
  final _configIdController = TextEditingController(text: '1');

  bool _canViewSales = true;
  // bool _canViewPurchases = true;
  // bool _canViewInventory = true;

  ApiConnection? _connectionBeingEdited;
  String? _defaultApiUser;
  bool _isLoading = false;
  List<ApiConnection> _savedConnections = [];

  final SaintApi _saintApi = SaintApi();
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadDefaultUser();
    await _loadSavedConnections();
  }

  Future<void> _loadDefaultUser() async {
    final settings = await _dbService.getAppSettings();
    if (mounted) {
      setState(() =>
          _defaultApiUser = settings[DatabaseService.columnDefaultApiUser]);
    }
  }

  void _populateFormForEditing(ApiConnection conn) {
    _baseUrlController.text = conn.baseUrl;
    _passwordController.text = conn.password;
    _pollingIntervalController.text = conn.pollingIntervalSeconds.toString();
    _terminalController.text = conn.terminal;
    _companyNameController.text = conn.companyName;
    _companyAliasController.text = conn.companyAlias;

    setState(() {
      _canViewSales = conn.permissions.canViewSales;
      // _canViewPurchases = conn.permissions.canViewPurchases;
      // _canViewInventory = conn.permissions.canViewInventory;
    });
  }

  Future<void> _loadSavedConnections() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final connections = await _dbService.getAllConnections();
      connections.sort((a, b) =>
          a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()));
      if (mounted) {
        setState(() {
          _savedConnections = connections;
        });
      }
    } catch (e) {
      _setErrorMessage('Error al cargar conexiones: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setErrorMessage(String? message) {
    if (mounted && message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message,
              style: const TextStyle(color: AppColors.textOnPrimaryOrange)),
          backgroundColor: AppColors.primaryOrange));
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _baseUrlController.clear();
    _passwordController.clear();
    _pollingIntervalController.text = '300';
    _terminalController.text = 'terminal';
    _companyNameController.clear();
    _companyAliasController.clear();
    _configIdController.text = '1';
    if (mounted) {
      setState(() {
        _connectionBeingEdited = null;
        _canViewSales = true;
        // _canViewPurchases = true;
        // _canViewInventory = true;
      });
    }
  }

  Future<void> _testAndSaveConnection() async {
    if (!_formKey.currentState!.validate()) return;
    if (_defaultApiUser == null || _defaultApiUser!.isEmpty) {
      _setErrorMessage(
          "Error crítico: No se encontró el usuario API por defecto. Reinstale la aplicación.");
      return;
    }

    setState(() => _isLoading = true);

    final baseUrlRaw = _baseUrlController.text.trim();
    final baseUrl = baseUrlRaw.endsWith('/')
        ? baseUrlRaw.substring(0, baseUrlRaw.length - 1)
        : baseUrlRaw;

    final password = _passwordController.text;
    final pollingInterval =
        int.tryParse(_pollingIntervalController.text.trim());
    final terminal = _terminalController.text.trim();
    final username = _defaultApiUser!;
    final configId = int.tryParse(_configIdController.text.trim());

    try {
      final LoginResponse? loginResponse = await _saintApi.login(
        baseurl: baseUrl,
        username: username,
        password: password,
        terminal: terminal,
      );

      if (loginResponse == null ||
          loginResponse.authToken == null ||
          loginResponse.authToken!.isEmpty) {
        throw AuthenticationException('Fallo el inicio de sesión.');
      }

      final String companyNameFromApi = loginResponse.company;
      final String companyAlias = _companyAliasController.text.trim();

      if (mounted) _companyNameController.text = companyNameFromApi;

      final permissionsToSave = Permissions(
        canViewSales: _canViewSales,
        // canViewPurchases: _canViewPurchases,
        // canViewInventory: _canViewInventory,
      );

      final existingAlias = await _dbService.getConnectionByAlias(companyAlias);

      if (_connectionBeingEdited != null) {
        if (existingAlias != null &&
            existingAlias.id != _connectionBeingEdited!.id) {
          throw Exception('Ya existe una conexion con ese alias.');
        }
      } else {
        if (existingAlias != null) {
          throw Exception('Ya existe una conexion con ese alias.');
        }
      }

      final connection = ApiConnection(
        id: _connectionBeingEdited?.id,
        baseUrl: baseUrl,
        username: username,
        password: password,
        pollingIntervalSeconds: pollingInterval!,
        companyName: companyNameFromApi,
        companyAlias: companyAlias,
        terminal: terminal,
        permissions: permissionsToSave,
        configId: configId!,
      );

      final notifier =
          Provider.of<ManagementSummaryNotifier>(context, listen: false);

      if (_connectionBeingEdited != null) {
        await _dbService.updateConnection(connection);
        notifier.updateConnectionInList(connection);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Conexión para "${connection.companyName}" actualizada.'),
              backgroundColor: AppColors.statusMessageSuccess));
        }
      } else {
        final newId = await _dbService.insertConnection(connection);
        final newSavedConnection = connection.copyWith(id: newId);
        notifier.addConnectionToList(newSavedConnection);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('Conexión para "${connection.companyName}" guardada.'),
              backgroundColor: AppColors.statusMessageSuccess));
        }
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _setErrorMessage('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteConnection(int id, String companyName) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
                backgroundColor: AppColors.dialogBackground,
                title: const Text('Confirmar Eliminación',
                    style: TextStyle(color: AppColors.textPrimary)),
                content: Text(
                    '¿Seguro que quieres eliminar la conexión para "$companyName"?',
                    style: const TextStyle(color: AppColors.textSecondary)),
                actions: <Widget>[
                  TextButton(
                      child: const Text('Cancelar',
                          style: TextStyle(color: AppColors.primaryBlue)),
                      onPressed: () => Navigator.of(dialogContext).pop(false)),
                  TextButton(
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.statusMessageError),
                      child: const Text('Eliminar'),
                      onPressed: () => Navigator.of(dialogContext).pop(true))
                ]));
    if (confirmed == true) {
      if (mounted) setState(() => _isLoading = true);
      try {
        await _dbService.deleteConnection(id);
        if (_connectionBeingEdited?.id == id) _clearForm();
        if (mounted) {
          Provider.of<ManagementSummaryNotifier>(context, listen: false)
              .removeConnectionFromList(id);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Conexión para "$companyName" eliminada.'),
              backgroundColor: AppColors.primaryOrange));
        }
        await _loadSavedConnections();
      } catch (e) {
        _setErrorMessage('Error al eliminar: ${e.toString()}');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _editConnection(ApiConnection connection) {
    if (mounted) {
      setState(() {
        _connectionBeingEdited = connection;
        _populateFormForEditing(connection);
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
    _configIdController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.primaryBlue),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0))),
        enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0))),
        focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            borderSide: BorderSide(
                color: AppColors.inputFocusedBorderColor, width: 2.0)),
        prefixIcon: Icon(icon, color: AppColors.inputPrefixIconColor),
        filled: true,
        fillColor: AppColors.cardBackground);
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentlyEditing = _connectionBeingEdited != null;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
          title: Text(isCurrentlyEditing ? 'Editar Conexión' : 'Nueva Conexión',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.appBarBackground,
          foregroundColor: AppColors.appBarForeground,
          elevation: 1,
          actions: [
            if (isCurrentlyEditing)
              IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  tooltip: 'Crear Nueva Conexión',
                  onPressed: _isLoading ? null : _clearForm,
                  color: AppColors.appBarForeground)
          ]),
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
                            offset: const Offset(0, 1))
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                          isCurrentlyEditing
                              ? 'Editando: "${_connectionBeingEdited?.companyName ?? ''}"'
                              : "Detalles de la Nueva Conexión",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue)),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: ValueKey(_defaultApiUser ?? 'loading_user'),
                        initialValue: _defaultApiUser ?? 'Cargando usuario...',
                        readOnly: true,
                        decoration: _inputDecoration(
                                'Usuario', '', Icons.person_rounded)
                            .copyWith(fillColor: Colors.grey.shade200),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _companyNameController,
                        readOnly: true,
                        decoration: _inputDecoration(
                                'Nombre de Empresa',
                                'Se completará al probar la conexión',
                                Icons.business_center_outlined)
                            .copyWith(fillColor: Colors.grey.shade200),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _baseUrlController,
                        decoration: _inputDecoration(
                            'URL del SAINT Enterprise Administrativo *',
                            'ej: http://tu-servidor.com/api',
                            Icons.http_rounded),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa la URL base';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _companyAliasController,
                        decoration: _inputDecoration(
                          'Alias de la conexión *',
                          'Ej: Sede principal, Sede Maracaibo...',
                          Icons.label_important,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, ingrese un alias a la conexión.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: _inputDecoration(
                            'Clave del Administrativo *',
                            'Clave',
                            Icons.lock_outline_rounded),
                        obscureText: true,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Ingresa la clave'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pollingIntervalController,
                        decoration: _inputDecoration(
                            'Intervalo de refrescamiento (segundos) *',
                            'Ej: 300',
                            Icons.timer_outlined),
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
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Ingresa el nombre del terminal'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _configIdController,
                        decoration: _inputDecoration('ID de la configuracion *',
                            'Ej: 1', Icons.settings_input_component),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
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
                      Text('Permisos para este equipo',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text("Ver Resumen de Ventas"),
                        value: _canViewSales,
                        onChanged: (bool value) =>
                            setState(() => _canViewSales = value),
                        secondary: const Icon(Icons.point_of_sale),
                      ),
                      // Aquí irían los otros SwitchListTile para compras, inventario, etc.
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: _isLoading
                            ? Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(right: 8),
                                child: const CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : Icon(
                                isCurrentlyEditing
                                    ? Icons.save_alt_rounded
                                    : Icons.add_link_rounded,
                                size: 20),
                        label: Text(
                            _isLoading
                                ? "Probando..."
                                : (isCurrentlyEditing
                                    ? 'Actualizar Conexión'
                                    : 'Probar y Guardar'),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                        onPressed: _isLoading ? null : _testAndSaveConnection,
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: isCurrentlyEditing
                                ? AppColors.primaryOrange
                                : AppColors.buttonPrimaryBackground,
                            foregroundColor: isCurrentlyEditing
                                ? AppColors.textOnPrimaryOrange
                                : AppColors.buttonPrimaryText,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 2),
                      ),
                      if (isCurrentlyEditing) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                            icon: const Icon(Icons.add_circle_outline_rounded,
                                size: 20),
                            label: const Text(
                                'Crear Nueva (Limpiar Formulario)',
                                style: TextStyle(fontSize: 15)),
                            onPressed: _isLoading ? null : _clearForm,
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                foregroundColor: AppColors.primaryBlue,
                                side: const BorderSide(
                                    color: AppColors.primaryBlue, width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)))),
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
                        child: CircularProgressIndicator(
                            color: AppColors.primaryOrange)))
              else if (_savedConnections.isEmpty)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Aún no has guardado ninguna conexión.',
                            style: TextStyle(
                                fontSize: 16, color: AppColors.textSecondary))))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _savedConnections.length,
                  itemBuilder: (context, index) {
                    final connection = _savedConnections[index];
                    final bool isActiveInNotifier =
                        Provider.of<ManagementSummaryNotifier>(context,
                                    listen: false)
                                .activeConnection
                                ?.id ==
                            connection.id;

                    return Card(
                      elevation: isActiveInNotifier ? 4 : 2,
                      color: AppColors.cardBackground,
                      margin: const EdgeInsets.symmetric(vertical: 7),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isActiveInNotifier
                                ? AppColors.primaryBlue
                                : AppColors.dividerColor,
                            width: isActiveInNotifier ? 1.5 : 1,
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
                            size: 32),
                        title: Text(connection.companyName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.5,
                                color: AppColors.textPrimary)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(connection.baseUrl,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                            Text(
                                'Usuario: ${connection.username} | Terminal: ${connection.terminal}',
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary)),
                            Text(
                                'Intervalo: ${connection.pollingIntervalSeconds} seg.',
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.edit_note_rounded,
                                    size: 28),
                                tooltip: 'Editar esta conexión',
                                color: AppColors.primaryBlue,
                                onPressed: _isLoading
                                    ? null
                                    : () => _editConnection(connection)),
                            IconButton(
                                icon: const Icon(Icons.delete_forever_rounded,
                                    size: 28),
                                tooltip: 'Eliminar esta conexión',
                                color: AppColors.statusMessageError,
                                onPressed: _isLoading
                                    ? null
                                    : () => _deleteConnection(connection.id!,
                                        connection.companyName)),
                          ],
                        ),
                        onTap: () {
                          final notifier =
                              Provider.of<ManagementSummaryNotifier>(context,
                                  listen: false);
                          if (isActiveInNotifier && !notifier.isLoading) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    '${connection.companyName} ya está activa.'),
                                duration: const Duration(seconds: 2)));
                            Navigator.of(context).pop(connection);
                            return;
                          }
                          notifier.setActiveConnection(connection,
                              fetchFullData: true);
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
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

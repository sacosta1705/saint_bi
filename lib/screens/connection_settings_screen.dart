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
  final _companyNameController =
      TextEditingController(); // Se llenará desde la API

  bool _isEditing = false;
  bool _isLoading = false;
  List<ApiConnection> _savedConnections = [];

  final SaintApi _saintApi = SaintApi();
  final DatabaseService _dbService =
      DatabaseService.instance; // Uso correcto de la instancia

  @override
  void initState() {
    super.initState();
    if (widget.connectionToEdit != null) {
      _isEditing = true;
      _populateFormForEditing(widget.connectionToEdit!);
    } else {
      _terminalController.text = 'saint_bi_flutter_app';
      _pollingIntervalController.text = '300';
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
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      _savedConnections = await _dbService.getAllConnections(); // Correcto
      _savedConnections.sort(
        (a, b) =>
            a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()),
      );
    } catch (e) {
      _setErrorMessage('Error al cargar conexiones: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setErrorMessage(String? message) {
    if (mounted) {
      setState(() {
        if (message != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
    }
  }

  void _clearForm() {
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _setErrorMessage(null);
    if (mounted) setState(() => _isLoading = true);

    final baseUrl = _baseUrlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final pollingInterval = int.tryParse(
      _pollingIntervalController.text.trim(),
    );
    final terminal = _terminalController.text.trim();

    if (pollingInterval == null || pollingInterval <= 0) {
      _setErrorMessage(
        'El intervalo de actualización debe ser un número positivo.',
      );
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Aunque el campo _companyNameController es de solo lectura una vez que se obtiene de la API,
    // si el usuario está creando una nueva y lo llenó, lo respetamos temporalmente.
    // La API es la fuente de verdad para el nombre de la empresa.
    // String companyNameUserInput = _companyNameController.text.trim(); // Ya no es necesario de esta forma

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
        throw AuthenticationException(
          'Fallo el inicio de sesión o no se recibió token/datos de empresa válidos.',
        );
      }

      final String companyNameFromApi = loginResponse.company;
      debugPrint(
        'Login exitoso. Empresa desde API: "$companyNameFromApi", Token: "${loginResponse.authToken}"',
      );

      if (mounted) {
        _companyNameController.text = companyNameFromApi;
        setState(() {});
      }

      final connection = ApiConnection(
        id: _isEditing ? widget.connectionToEdit!.id : null,
        baseUrl: baseUrl,
        username: username,
        password: password,
        pollingIntervalSeconds: pollingInterval,
        companyName: companyNameFromApi, // Usar el nombre validado por la API
        terminal: terminal,
      );

      final notifier = Provider.of<InvoiceNotifier>(context, listen: false);

      if (_isEditing) {
        // Al editar, companyName (que es UNIQUE) podría cambiar si la API lo devuelve diferente
        // O si el usuario lo cambió Y la API lo valida (menos probable y complejo).
        // Es más seguro que companyName (el identificador) no cambie fácilmente o se valide
        // que el nuevo nombre no colisione.
        final existingByName = await _dbService.getConnectionByCompanyName(
          companyNameFromApi,
        ); // Correcto
        if (existingByName != null && existingByName.id != connection.id) {
          // Hay otra conexión con el mismo nombre de empresa.
          throw Exception(
            'Ya existe otra conexión guardada para la empresa "$companyNameFromApi". No se puede actualizar a un nombre duplicado.',
          );
        }
        await _dbService.updateConnection(connection); // Correcto
        notifier.updateConnectionInList(connection);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Conexión para "${connection.companyName}" actualizada.',
              ),
            ),
          );
        }
      } else {
        // Para nueva conexión, chequear si ya existe por companyName (que es UNIQUE)
        final existingByName = await _dbService.getConnectionByCompanyName(
          companyNameFromApi,
        ); // Correcto
        if (existingByName != null) {
          throw Exception(
            'Ya existe una conexión guardada para la empresa "$companyNameFromApi".',
          );
        }
        final newId = await _dbService.insertConnection(connection); // Correcto
        notifier.addConnectionToList(connection.copyWith(id: newId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Conexión para "${connection.companyName}" guardada.',
              ),
            ),
          );
        }
      }

      _clearForm();
      _loadSavedConnections();
    } on AuthenticationException catch (e) {
      _setErrorMessage('Error de Autenticación: ${e.msg}');
    } on NetworkException catch (e) {
      _setErrorMessage('Error de Red: ${e.msg}');
    } on UnknownApiExpection catch (e) {
      _setErrorMessage('Error de API: ${e.msg}');
    } catch (e) {
      _setErrorMessage('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteConnection(int id, String companyName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text(
            '¿Estás seguro de eliminar la conexión para "$companyName"?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (mounted) setState(() => _isLoading = true);
      try {
        await _dbService.deleteConnection(id); // Correcto
        if (_isEditing && widget.connectionToEdit?.id == id) {
          _clearForm();
        }
        if (mounted) {
          Provider.of<InvoiceNotifier>(
            context,
            listen: false,
          ).removeConnectionFromList(id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Conexión para "$companyName" eliminada.')),
          );
        }
        _loadSavedConnections();
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
        _isEditing = true;
        _populateFormForEditing(connection);
      });
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pollingIntervalController.dispose();
    _terminalController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Conexión' : 'Configurar Conexión API'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Crear Nueva Conexión',
              onPressed: _isLoading ? null : _clearForm,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _isEditing
                          ? 'Editando Conexión Existente'
                          : "Nueva Conexión API",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      // Campo Nombre de Empresa
                      controller: _companyNameController,
                      readOnly:
                          true, // Se llena desde la API, por lo tanto, es de solo lectura.
                      decoration: InputDecoration(
                        labelText: 'Nombre de Empresa (obtenido de API)',
                        hintText: 'Se completará al probar la conexión',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        prefixIcon: Icon(
                          Icons.business_center_outlined,
                          color: Theme.of(
                            context,
                          ).inputDecorationTheme.prefixIconColor,
                        ),
                      ),
                      // No se necesita validador si es de solo lectura.
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      // Campo URL Base
                      controller: _baseUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Base de la API *',
                        hintText: 'ej: http://tu-servidor.com/api',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.http_rounded),
                      ),
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
                    const SizedBox(height: 12),
                    TextFormField(
                      // Campo Nombre de Usuario
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de Usuario API *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el nombre de usuario';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      // Campo Contraseña
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña API *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa la contraseña';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      // Campo Intervalo
                      controller: _pollingIntervalController,
                      decoration: const InputDecoration(
                        labelText: 'Intervalo de Actualización (segundos) *',
                        hintText: 'Ej: 300 (para 5 minutos)',
                        border: OutlineInputBorder(),
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
                        if (interval == null || interval <= 0) {
                          return 'Debe ser un número positivo mayor a 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      // Campo Terminal
                      controller: _terminalController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Terminal *',
                        hintText: 'Ej: SaintBiAppMovilClienteX',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.devices_other_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el nombre del terminal';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      // Botón Guardar/Actualizar
                      icon: Icon(
                        _isEditing
                            ? Icons.save_alt_rounded
                            : Icons.add_link_rounded,
                        size: 20,
                      ),
                      label: Text(
                        _isEditing
                            ? 'Actualizar Conexión'
                            : 'Probar y Guardar Conexión',
                        style: const TextStyle(fontSize: 16),
                      ),
                      onPressed: _isLoading ? null : _testAndSaveConnection,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: _isEditing
                            ? Colors.orange.shade800
                            : Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    if (_isEditing) ...[
                      // Botón para limpiar formulario si se está editando
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 20,
                        ),
                        label: const Text(
                          'Crear Nueva Conexión (Limpiar)',
                          style: TextStyle(fontSize: 15),
                        ),
                        onPressed: _isLoading ? null : _clearForm,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Divider(thickness: 1),
              Padding(
                // Título de la lista de conexiones
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "Conexiones Guardadas",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              // Lista de Conexiones Guardadas
              if (_isLoading && _savedConnections.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_savedConnections.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Aún no has guardado ninguna conexión.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _savedConnections.length,
                  itemBuilder: (context, index) {
                    final connection = _savedConnections[index];
                    final bool isCurrentlyEditingThis =
                        _isEditing &&
                        widget.connectionToEdit?.id == connection.id;
                    final bool isActiveInNotifier =
                        Provider.of<InvoiceNotifier>(
                          context,
                          listen: false,
                        ).activeConnection?.id ==
                        connection.id;

                    return Card(
                      elevation: isCurrentlyEditingThis
                          ? 6
                          : (isActiveInNotifier ? 4 : 2),
                      color: isCurrentlyEditingThis
                          ? Theme.of(
                              context,
                            ).colorScheme.primaryContainer.withOpacity(0.4)
                          : (isActiveInNotifier
                                ? Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer
                                      .withOpacity(0.3)
                                : null),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isCurrentlyEditingThis
                              ? Theme.of(context).colorScheme.primary
                              : (isActiveInNotifier
                                    ? Theme.of(context).colorScheme.secondary
                                    : Colors.grey.shade300),
                          width: isCurrentlyEditingThis || isActiveInNotifier
                              ? 1.5
                              : 0.8,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        leading: Icon(
                          isActiveInNotifier
                              ? Icons.lan_rounded
                              : Icons.link_off_rounded,
                          color: isActiveInNotifier
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade700,
                          size: 30,
                        ),
                        title: Text(
                          connection.companyName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              connection.baseUrl,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              'Usuario: ${connection.username}  |  Terminal: ${connection.terminal}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              'Intervalo: ${connection.pollingIntervalSeconds} seg.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit_note_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                              tooltip: 'Editar esta conexión',
                              onPressed: _isLoading
                                  ? null
                                  : () => _editConnection(connection),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_forever_rounded,
                                color: Theme.of(context).colorScheme.error,
                                size: 28,
                              ),
                              tooltip: 'Eliminar esta conexión',
                              onPressed: _isLoading
                                  ? null
                                  : () => _deleteConnection(
                                      connection.id!,
                                      connection.companyName,
                                    ),
                            ),
                          ],
                        ),
                        onTap: () {
                          final notifier = Provider.of<InvoiceNotifier>(
                            context,
                            listen: false,
                          );
                          if (isActiveInNotifier && !notifier.isLoading) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${connection.companyName} ya está activa.',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            Navigator.of(context).pop();
                            return;
                          }
                          notifier.setActiveConnection(
                            connection,
                            fetchFullData: true,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Cargando datos para ${connection.companyName}...',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          Navigator.of(context).pop();
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

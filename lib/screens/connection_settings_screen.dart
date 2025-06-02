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
  // El _companyNameController ahora se llenará desde la API o será para un "alias" si la API no lo devuelve
  final _companyNameController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<ApiConnection> _savedConnections = [];
  bool _isCompanyNameFromApi = false; // Para saber si el nombre vino de la API

  final SaintApi _saintApi = SaintApi();
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    if (widget.connectionToEdit != null) {
      _isEditing = true;
      _populateFormForEditing(widget.connectionToEdit!);
      _isCompanyNameFromApi =
          true; // Asumimos que el nombre guardado vino de la API
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
    _companyNameController.text = conn
        .companyName; // Este es el nombre que se guardó (idealmente de la API)
    _isCompanyNameFromApi =
        true; // Si estamos editando, el nombre ya fue validado por la API.
  }

  Future<void> _loadSavedConnections() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      _savedConnections = await _dbService.getAllConnections();
      _savedConnections.sort(
        (a, b) =>
            a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()),
      );
    } catch (e) {
      _setErrorMessage('Error al cargar conexiones guardadas: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setErrorMessage(String? message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
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
        _isCompanyNameFromApi = false;
        _errorMessage = null;
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
    // El companyNameInput se usa solo si la API no devuelve un nombre de empresa o como alias.
    // Pero ahora _saintApi.login() devuelve LoginResponse que contiene el companyName.
    // String companyNameInput = _companyNameController.text.trim();

    if (pollingInterval == null || pollingInterval <= 0) {
      _setErrorMessage(
        'El intervalo de actualización debe ser un número positivo mayor a 0.',
      );
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    // Ya no es necesario validar companyNameInput aquí si vamos a usar el de la API.

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
          'Fallo el inicio de sesión o no se recibió token/datos de empresa.',
        );
      }

      final String companyNameFromApi = loginResponse.company;
      debugPrint(
        'Login exitoso. Empresa desde API: $companyNameFromApi, Token: ${loginResponse.authToken}',
      );

      // Actualizar el campo _companyNameController con el nombre de la API
      // y marcar que viene de la API para hacerlo de solo lectura si es necesario.
      if (mounted) {
        _companyNameController.text = companyNameFromApi;
        setState(() {
          _isCompanyNameFromApi =
              true; // El nombre es ahora el validado por la API
        });
      }

      final connection = ApiConnection(
        id: _isEditing ? widget.connectionToEdit!.id : null,
        baseUrl: baseUrl,
        username: username,
        password: password,
        pollingIntervalSeconds: pollingInterval,
        companyName: companyNameFromApi, // Usar el nombre de la API
        terminal: terminal,
      );

      final notifier = Provider.of<InvoiceNotifier>(context, listen: false);

      if (_isEditing) {
        // Al editar, el ID ya existe. companyName (que es UNIQUE) podría cambiar si la API lo devuelve diferente
        // o si el usuario lo cambió Y la API lo valida (menos probable).
        // Es más seguro que companyName no cambie o se valide que no colisione.
        // Con ConflictAlgorithm.replace, si el companyName (UNIQUE) ya existe en otra fila, la reemplazaría.
        // Es mejor verificar primero.
        final existingByName = await _dbService.getConnectionByCompanyName(
          companyNameFromApi,
        );
        if (existingByName != null && existingByName.id != connection.id) {
          throw Exception(
            'Ya existe otra conexión guardada para la empresa "$companyNameFromApi".',
          );
        }
        await _dbService.updateConnection(connection);
        notifier.updateConnectionInList(
          connection,
        ); // Actualiza en la lista del notifier
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Conexión para "${connection.companyName}" actualizada exitosamente.',
              ),
            ),
          );
        }
      } else {
        // Para nueva conexión, chequear si ya existe por companyName (que es UNIQUE)
        final existingByName = await _dbService.getConnectionByCompanyName(
          companyNameFromApi,
        );
        if (existingByName != null) {
          throw Exception(
            'Ya existe una conexión guardada para la empresa "$companyNameFromApi".',
          );
        }
        await _dbService.insertConnection(connection);
        notifier.addConnectionToList(
          connection,
        ); // Añade a la lista del notifier
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Conexión para "${connection.companyName}" guardada exitosamente.',
              ),
            ),
          );
        }
      }

      _clearForm(); // Limpia el formulario para la próxima entrada
      _loadSavedConnections(); // Recarga la lista de conexiones mostradas
    } on AuthenticationException catch (e) {
      _setErrorMessage('Error de Autenticación: ${e.msg}');
    } on NetworkException catch (e) {
      _setErrorMessage('Error de Red: ${e.msg}');
    } on UnknownApiExpection catch (e) {
      _setErrorMessage('Error de API: ${e.msg}');
    } catch (e) {
      // Captura otras excepciones, incluyendo la de UNIQUE constraint de la DB
      _setErrorMessage('Error al guardar conexión: ${e.toString()}');
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
            '¿Estás seguro de que quieres eliminar la conexión para "$companyName"?',
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
        await _dbService.deleteConnection(id);
        if (_isEditing && widget.connectionToEdit?.id == id) {
          _clearForm(); // Si se eliminó la que se estaba editando, limpiar el formulario
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
        _loadSavedConnections(); // Recargar la lista
      } catch (e) {
        _setErrorMessage('Error al eliminar conexión: ${e.toString()}');
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
        _errorMessage = null;
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
              tooltip: 'Crear Nueva Conexión (Limpiar Formulario)',
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
                          ? 'Editando: "${widget.connectionToEdit?.companyName}"'
                          : "Nueva Conexión API",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Campo Nombre de Empresa/Conexión
                    TextFormField(
                      controller: _companyNameController,
                      readOnly:
                          _isEditing ||
                          _isCompanyNameFromApi, // Solo lectura si se edita o si el nombre vino de la API
                      decoration: InputDecoration(
                        labelText: _isCompanyNameFromApi
                            ? 'Nombre de Empresa (desde API)'
                            : 'Nombre Descriptivo para la Conexión *',
                        hintText: 'Ej: Mi Empresa Principal',
                        border: const OutlineInputBorder(),
                        filled: _isEditing || _isCompanyNameFromApi,
                        fillColor: (_isEditing || _isCompanyNameFromApi)
                            ? Colors.grey.shade200
                            : null,
                        prefixIcon: Icon(
                          Icons.business_center_outlined,
                          color: Theme.of(
                            context,
                          ).inputDecorationTheme.prefixIconColor,
                        ),
                      ),
                      validator: (value) {
                        // Solo es obligatorio si NO estamos editando Y el nombre no ha sido poblado por la API aún.
                        if (!_isEditing &&
                            !_isCompanyNameFromApi &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Ingresa un nombre para identificar esta conexión (se actualizará con el nombre de la API al guardar).';
                        }
                        return null;
                      },
                    ),
                    if (!_isCompanyNameFromApi &&
                        !_isEditing) // Mostrar ayuda solo si es nuevo y no se ha obtenido de la API
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 4.0,
                          left: 12.0,
                          bottom: 6.0,
                        ),
                        child: Text(
                          "Este nombre es un alias. Se actualizará con el nombre oficial de la empresa desde la API al probar/guardar.",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Campo URL Base
                    TextFormField(
                      controller: _baseUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Base de la API *',
                        hintText: 'http://tu-servidor.com/api',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.http_rounded),
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, ingresa la URL base';
                        }
                        final uri = Uri.tryParse(value.trim());
                        if (uri == null ||
                            !uri.isAbsolute ||
                            (uri.scheme != 'http' && uri.scheme != 'https')) {
                          return 'Ingresa una URL válida (ej: http://...)';
                        }
                        // La validación de /v1/ se hará al construir la URL completa en SaintApi
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Campo Nombre de Usuario
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de Usuario API *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, ingresa el nombre de usuario';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Campo Contraseña
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña API *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingresa la contraseña';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Campo Intervalo de Actualización
                    TextFormField(
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
                          return 'Ingresa el intervalo de actualización';
                        }
                        final interval = int.tryParse(value.trim());
                        if (interval == null || interval <= 0) {
                          return 'Debe ser un número positivo mayor a 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Campo Terminal
                    TextFormField(
                      controller: _terminalController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Terminal *',
                        hintText: 'Ej: SaintBiAppMovilClienteX',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.devices_other_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, ingresa el nombre del terminal';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Botón Guardar/Actualizar
                    ElevatedButton.icon(
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
                    // Botón para limpiar formulario y crear nueva (si está editando)
                    if (_isEditing) ...[
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
                    // Determinar si esta conexión es la activa en el notifier
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
                              : Icons
                                    .link_off_rounded, // Cambia el icono si está activa
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
                            // Si ya está activa y no está cargando, quizás no hacer nada o solo cerrar.
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${connection.companyName} ya está activa.',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            Navigator.of(
                              context,
                            ).pop(); // Cierra esta pantalla si se seleccionó la activa
                            return;
                          }
                          // Establecer como activa y recargar datos
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
                          Navigator.of(
                            context,
                          ).pop(); // Cierra esta pantalla y vuelve a la principal
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

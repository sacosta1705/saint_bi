// lib/providers/invoice_notifier.dart
import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

import 'package:saint_bi/services/saint_api.dart';
import 'package:saint_bi/models/invoice.dart';
import 'package:saint_bi/models/invoice_summary.dart';
import 'package:saint_bi/services/saint_api_exceptions.dart';
import 'package:saint_bi/services/invoice_calculator_service.dart';
import 'package:saint_bi/models/api_connection.dart';
import 'package:saint_bi/services/database_service.dart';
import 'package:saint_bi/models/login_response.dart';

// Constantes de mensajes para la UI
const String _uiAuthErrorMessage =
    'Error de autenticación. Revise credenciales o URL.';
const String _uiSessionExpiredMessage =
    'Sesión expirada. Intentando re-autenticar...';
const String _uiGenericErrorMessage = 'Error al comunicarse con el servidor.';
const String _uiNetworkErrorMessage =
    'Error de red. Verifique su conexión a internet.';
const String _uiNoConnectionSelectedMessage =
    'Seleccione o configure una conexión de empresa.';
const String _uiNoConnectionsAvailableMessage =
    'No hay conexiones configuradas. Por favor, añada una.';

class InvoiceNotifier extends ChangeNotifier {
  final SaintApi _api = SaintApi();
  final InvoiceCalculator _invoiceCalculator = InvoiceCalculator();
  final DatabaseService _dbService = DatabaseService.instance;

  InvoiceSummary _invoiceSummary = InvoiceSummary();
  bool _isLoading = false;
  String? _errorMsg;
  String? _authtoken; // Token de la sesión activa (valor del header Pragma)
  Timer? _timer;
  bool _isReAuthenticating = false;

  DateTime? _startDate;
  DateTime? _endDate;

  ApiConnection? _activeConnection;
  List<ApiConnection> _availableConnections = [];

  // Getters
  InvoiceSummary get invoiceSummary => _invoiceSummary;
  bool get isLoading => _isLoading;
  String? get errorMsg => _errorMsg;
  bool get isAuthenticated => _authtoken != null && _authtoken!.isNotEmpty;
  int get pollingIntervalSeconds =>
      _activeConnection?.pollingIntervalSeconds ??
      9999999; // Default alto si no hay conexión
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  ApiConnection? get activeConnection => _activeConnection;
  List<ApiConnection> get availableConnections => _availableConnections;

  InvoiceNotifier() {
    debugPrint('Inicializando InvoiceNotifier...');
    refreshAvailableConnections(); // Cargar conexiones al iniciar
  }

  Future<void> refreshAvailableConnections({
    ApiConnection? newlySelectedFromSettings,
  }) async {
    _isLoading = true;
    notifyListeners(); // Notificar que estamos cargando la lista
    try {
      _availableConnections = await _dbService.getAllConnections();
      _availableConnections.sort(
        (a, b) =>
            a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()),
      );
      debugPrint(
        'Conexiones disponibles cargadas: ${_availableConnections.length}',
      );

      if (_availableConnections.isEmpty) {
        _errorMsg =
            _uiNoConnectionsAvailableMessage; // Mensaje específico si no hay ninguna conexión en la BD
        clearActiveConnectionAndData(
          notify: false,
        ); // Limpiar, no notificar aun
      } else if (newlySelectedFromSettings != null) {
        // Si se pasa una conexión desde settings (recién guardada/editada), intentar seleccionarla
        final found = _availableConnections.firstWhere(
          (c) => c.id == newlySelectedFromSettings.id,
          orElse: () => _availableConnections.first,
        );
        await setActiveConnection(
          found,
          fetchFullData: true,
          isInitialLoad: true,
        );
      } else if (_activeConnection != null) {
        // Verificar si la conexión activa actual sigue existiendo en la lista
        final currentActiveStillExists = _availableConnections.any(
          (c) => c.id == _activeConnection!.id,
        );
        if (!currentActiveStillExists) {
          debugPrint(
            'La conexión activa (ID: ${_activeConnection!.id}) ya no existe. Limpiando.',
          );
          clearActiveConnectionAndData(
            notify: false,
          ); // Limpiar datos, no notificar aun
          _errorMsg =
              _uiNoConnectionSelectedMessage; // Pedir que seleccione una nueva
        } else {
          // La conexión activa sigue siendo válida, no es necesario hacer nada más aquí.
          // Limpiar el error si antes había uno de "no conexión"
          if (_errorMsg == _uiNoConnectionSelectedMessage ||
              _errorMsg == _uiNoConnectionsAvailableMessage) {
            _errorMsg = null;
          }
        }
      } else {
        // Hay conexiones, pero ninguna estaba activa (ej. primer inicio con conexiones existentes)
        _errorMsg = _uiNoConnectionSelectedMessage;
      }
    } catch (e) {
      _errorMsg =
          "Error crítico al cargar lista de conexiones: ${e.toString()}";
      clearActiveConnectionAndData(notify: false);
    } finally {
      _isLoading = false;
      notifyListeners(); // Notificar al final de la operación
    }
  }

  void addConnectionToList(ApiConnection connection) {
    if (!_availableConnections.any((c) => c.id == connection.id)) {
      _availableConnections.add(connection);
      _availableConnections.sort(
        (a, b) =>
            a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()),
      );
      notifyListeners();
    }
  }

  void updateConnectionInList(ApiConnection connection) {
    final index = _availableConnections.indexWhere(
      (c) => c.id == connection.id,
    );
    if (index != -1) {
      _availableConnections[index] = connection;
      _availableConnections.sort(
        (a, b) =>
            a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()),
      );
      if (_activeConnection?.id == connection.id) {
        _activeConnection = connection; // Actualizar la instancia activa
      }
      notifyListeners();
    }
  }

  void removeConnectionFromList(int connectionId) {
    _availableConnections.removeWhere((c) => c.id == connectionId);
    if (_activeConnection?.id == connectionId) {
      clearActiveConnectionAndData(); // Si se eliminó la activa
      if (_availableConnections.isEmpty) {
        _errorMsg = _uiNoConnectionsAvailableMessage;
      } else {
        _errorMsg = 'Conexión activa eliminada. Por favor, seleccione otra.';
      }
    } else if (_availableConnections.isEmpty) {
      _errorMsg = _uiNoConnectionsAvailableMessage;
      clearActiveConnectionAndData();
    }
    notifyListeners();
  }

  Future<void> setActiveConnection(
    ApiConnection? connection, {
    bool fetchFullData = true,
    bool isInitialLoad = false,
  }) async {
    if (connection == null) {
      clearActiveConnectionAndData();
      return;
    }

    if (_activeConnection?.id == connection.id &&
        !fetchFullData &&
        !isInitialLoad) {
      debugPrint(
        'setActiveConnection: Misma conexión (ID: ${connection.id}), no se fuerza recarga.',
      );
      if (_errorMsg == _uiNoConnectionSelectedMessage ||
          _errorMsg == _uiNoConnectionsAvailableMessage) {
        _errorMsg = null;
      }
      notifyListeners();
      return;
    }

    debugPrint(
      'Estableciendo conexión activa: ${connection.companyName} (ID: ${connection.id}), fetchFullData: $fetchFullData',
    );
    _activeConnection = connection;
    _authtoken = null;
    _invoiceSummary = InvoiceSummary();
    _startDate = null;
    _endDate = null;
    _errorMsg = null;
    _isLoading =
        fetchFullData; // Poner isLoading true solo si vamos a buscar datos
    _isReAuthenticating = false;
    _stopPolling();

    notifyListeners(); // Notificar el cambio de selección y el inicio de carga si fetchFullData es true

    if (fetchFullData) {
      await fetchInitialData();
    }
  }

  void clearActiveConnectionAndData({bool notify = true}) {
    debugPrint('Limpiando conexión activa y datos.');
    _activeConnection = null;
    _authtoken = null;
    _invoiceSummary = InvoiceSummary();
    _errorMsg = _availableConnections.isEmpty
        ? _uiNoConnectionsAvailableMessage
        : _uiNoConnectionSelectedMessage;
    _isLoading = false;
    _isReAuthenticating = false;
    _stopPolling();
    _startDate = null;
    _endDate = null;
    if (notify) notifyListeners();
  }

  void _handleError(
    String message, {
    bool isAuthenticationIssue = false,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _errorMsg = message;
    if (isAuthenticationIssue) {
      _authtoken = null;
      debugPrint(
        'Token invalidado para "${_activeConnection?.companyName}" por error de auth.',
      );
    }
    _isLoading = false;
    _isReAuthenticating = false;
    debugPrint(
      'Error en Notifier para "${_activeConnection?.companyName ?? "N/A"}": $message. Exc: $error, Stack: $stackTrace',
    );
    notifyListeners();
  }

  Future<void> filterByDateRange(DateTime? start, DateTime? end) async {
    if (_activeConnection == null) {
      _handleError(_uiNoConnectionSelectedMessage);
      return;
    }
    if (start != null && end != null && end.isBefore(start)) {
      _errorMsg = "La fecha final no puede ser anterior a la fecha de inicio.";
      _isLoading = false;
      notifyListeners();
      return;
    }

    _startDate = start;
    _endDate = end;
    _isLoading = true;
    _errorMsg = null;
    _invoiceSummary = InvoiceSummary(); // Resetear para nueva carga con filtro
    _stopPolling();
    notifyListeners();

    if (!isAuthenticated) {
      debugPrint(
        'No autenticado al filtrar por rango para "${_activeConnection!.companyName}". Intentando login.',
      );
      await fetchInitialData();
    } else {
      debugPrint(
        'Autenticado para "${_activeConnection!.companyName}". Obteniendo datos para rango: $_startDate - $_endDate',
      );
      await _fetchSummaryData(isInitialFetchForCurrentOp: true);
      if (isAuthenticated && _errorMsg == null) {
        _startPollingInvoices();
      }
    }
  }

  Future<void> fetchInitialData() async {
    if (_activeConnection == null) {
      _handleError(_uiNoConnectionSelectedMessage);
      if (_isLoading) _isLoading = false; // Asegurar que no se quede cargando
      notifyListeners();
      return;
    }

    debugPrint(
      'Iniciando fetchInitialData para "${_activeConnection!.companyName}". isLoading: $_isLoading, isReAuth: $_isReAuthenticating',
    );

    _isLoading = true; // Marcar como cargando desde el inicio de la operación
    if (!_isReAuthenticating) {
      _errorMsg = null;
      _authtoken = null;
      _invoiceSummary = InvoiceSummary();
      _stopPolling();
    }
    notifyListeners();

    try {
      final LoginResponse? loginResponse = await _api.login(
        baseurl: _activeConnection!.baseUrl,
        username: _activeConnection!.username,
        password: _activeConnection!.password,
        terminal: _activeConnection!.terminal,
      );

      if (loginResponse == null ||
          loginResponse.authToken == null ||
          loginResponse.authToken!.isEmpty) {
        throw AuthenticationException(
          "Login falló o no se recibió token/datos de empresa válidos.",
        );
      }

      _authtoken = loginResponse.authToken; // Guardar el token Pragma
      // Validar/actualizar el nombre de la empresa si es diferente al guardado
      if (loginResponse.company != _activeConnection!.companyName) {
        debugPrint(
          "Advertencia: Nombre de empresa en BD local ('${_activeConnection!.companyName}') difiere del de API ('${loginResponse.company}'). Actualizando local.",
        );
        _activeConnection = _activeConnection!.copyWith(
          companyName: loginResponse.company,
        );
        await _dbService.updateConnection(
          _activeConnection!,
        ); // Actualizar en BD
        // Refrescar la lista de conexiones disponibles para que la UI muestre el nombre correcto
        final currentSelectedId = _activeConnection!.id;
        _availableConnections = await _dbService.getAllConnections();
        _availableConnections.sort(
          (a, b) => a.companyName.toLowerCase().compareTo(
                b.companyName.toLowerCase(),
              ),
        );
        _activeConnection = _availableConnections.firstWhere(
          (c) => c.id == currentSelectedId,
          orElse: () => _activeConnection!,
        );
      }

      debugPrint(
        'Login exitoso para "${_activeConnection!.companyName}". Token: $_authtoken. Empresa API: "${loginResponse.company}"',
      );
      _isReAuthenticating = false;

      if (isAuthenticated) {
        // Doble chequeo por si _authtoken se volvió null
        _errorMsg = null;
        debugPrint(
          'Procediendo a _fetchSummaryData para "${_activeConnection!.companyName}"',
        );
        await _fetchSummaryData(isInitialFetchForCurrentOp: true);

        if (_errorMsg == null) {
          debugPrint(
            'fetchInitialData: _fetchSummaryData OK para "${_activeConnection!.companyName}", iniciando polling.',
          );
          _startPollingInvoices();
        } else {
          debugPrint(
            'fetchInitialData: _fetchSummaryData falló post-login para "${_activeConnection!.companyName}". Error: $_errorMsg',
          );
          _stopPolling();
        }
      } else {
        // Esto teóricamente no debería ocurrir si loginResponse.authToken es validado arriba.
        _handleError(
          _uiAuthErrorMessage,
          isAuthenticationIssue: true,
          error: "Token inválido post-procesamiento de login.",
        );
        _stopPolling();
      }
    } on AuthenticationException catch (e, stackTrace) {
      _handleError(
        _uiAuthErrorMessage,
        isAuthenticationIssue: true,
        error: e,
        stackTrace: stackTrace,
      );
      _stopPolling();
    } on NetworkException catch (e, stackTrace) {
      _handleError(_uiNetworkErrorMessage, error: e, stackTrace: stackTrace);
      // No detener polling, podría ser temporal
    } on UnknownApiExpection catch (e, stackTrace) {
      _handleError(_uiGenericErrorMessage, error: e, stackTrace: stackTrace);
      _stopPolling();
    } catch (e, stackTrace) {
      _handleError(_uiGenericErrorMessage, error: e, stackTrace: stackTrace);
      _stopPolling();
    } finally {
      if (_isLoading &&
          (_errorMsg != _uiSessionExpiredMessage || !_isReAuthenticating)) {
        _isLoading = false;
      }
      notifyListeners();
      debugPrint(
        'fetchInitialData finalizado para "${_activeConnection?.companyName}". isLoading: $_isLoading, isAuth: $isAuthenticated, error: $_errorMsg',
      );
    }
  }

  Future<void> _fetchSummaryData({
    bool isInitialFetchForCurrentOp = false,
  }) async {
    if (_activeConnection == null) {
      _handleError(
        _uiNoConnectionSelectedMessage,
        error: "Fetch abortado: Sin conexión activa.",
      );
      if (isInitialFetchForCurrentOp) _isLoading = false;
      notifyListeners();
      return;
    }
    if (!isAuthenticated) {
      _handleError(
        'No autenticado para "${_activeConnection!.companyName}".',
        isAuthenticationIssue: true,
        error: "Fetch abortado: Sin token.",
      );
      if (isInitialFetchForCurrentOp) _isLoading = false;
      notifyListeners();
      return;
    }

    if (!isInitialFetchForCurrentOp && _errorMsg != _uiSessionExpiredMessage) {
      _isLoading = true;
      if (_errorMsg != null && _errorMsg != _uiSessionExpiredMessage) {
        _errorMsg = null;
      }
      notifyListeners();
    }

    debugPrint(
      'Iniciando _fetchSummaryData para "${_activeConnection!.companyName}" (isInitialOp: $isInitialFetchForCurrentOp). Filtro: $_startDate - $_endDate',
    );

    try {
      final List<Invoice> allInvoices = await _api.getInvoices(
        baseUrl: _activeConnection!.baseUrl,
        authtoken: _authtoken!,
      );
      debugPrint(
        '_fetchSummaryData para "${_activeConnection!.companyName}": ${allInvoices.length} facturas de API.',
      );

      _invoiceSummary = _invoiceCalculator.calculateSummary(
        allInvoices: allInvoices,
        startDate: _startDate,
        endDate: _endDate,
      );
      debugPrint(
        '_fetchSummaryData para "${_activeConnection!.companyName}": Resumen. Ventas: ${_invoiceSummary.totalSales}',
      );

      if (_errorMsg != _uiSessionExpiredMessage) {
        _errorMsg = null;
      }
      _isReAuthenticating = false;
    } on SessionExpiredException catch (e, stackTrace) {
      debugPrint(
        '_fetchSummaryData para "${_activeConnection!.companyName}": Sesión Expirada. ${e.toString()}',
      );
      if (_isReAuthenticating) {
        _handleError(
          _uiAuthErrorMessage,
          isAuthenticationIssue: true,
          error: e,
          stackTrace: stackTrace,
        );
        _stopPolling();
        return;
      }
      _errorMsg = _uiSessionExpiredMessage;
      _authtoken = null;
      _isReAuthenticating = true;
      notifyListeners();

      _stopPolling();
      await Future.delayed(const Duration(seconds: 1));
      await fetchInitialData();
      return;
    } on AuthenticationException catch (e, stackTrace) {
      _handleError(
        _uiAuthErrorMessage,
        isAuthenticationIssue: true,
        error: e,
        stackTrace: stackTrace,
      );
      _stopPolling();
    } on NetworkException catch (e, stackTrace) {
      _handleError(_uiNetworkErrorMessage, error: e, stackTrace: stackTrace);
    } on UnknownApiExpection catch (e, stackTrace) {
      _handleError(_uiGenericErrorMessage, error: e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      _handleError(_uiGenericErrorMessage, error: e, stackTrace: stackTrace);
    } finally {
      if (_isLoading &&
          (_errorMsg != _uiSessionExpiredMessage || !_isReAuthenticating)) {
        _isLoading = false;
      }
      notifyListeners();
      debugPrint(
        '_fetchSummaryData finalizado para "${_activeConnection?.companyName}". isLoading: $_isLoading, error: $_errorMsg, summarySales: ${_invoiceSummary.totalSales}',
      );
    }
  }

  void _startPollingInvoices() {
    _stopPolling();
    if (isAuthenticated &&
        _activeConnection != null &&
        _activeConnection!.pollingIntervalSeconds > 0) {
      debugPrint(
        'Iniciando polling para "${_activeConnection!.companyName}" c/${_activeConnection!.pollingIntervalSeconds}s.',
      );
      _timer = Timer.periodic(
        Duration(seconds: _activeConnection!.pollingIntervalSeconds),
        (timer) {
          if (_activeConnection == null || !isAuthenticated) {
            _stopPolling();
            return;
          }
          debugPrint(
            'Ejecutando fetch por polling para "${_activeConnection!.companyName}"...',
          );
          _fetchSummaryData(isInitialFetchForCurrentOp: false);
        },
      );
    } else {
      debugPrint(
        'No se inicia polling: no auth, sin conexión activa, o intervalo <= 0.',
      );
    }
  }

  void _stopPolling() {
    if (_timer != null && _timer!.isActive) {
      debugPrint(
        'Deteniendo polling para "${_activeConnection?.companyName}".',
      );
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    debugPrint('Disposing InvoiceNotifier.');
    _stopPolling();
    super.dispose();
  }
}

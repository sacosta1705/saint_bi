// lib/providers/invoice_notifier.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:saint_bi/services/saint_api.dart';
import 'package:saint_bi/models/invoice.dart';
import 'package:saint_bi/models/invoice_summary.dart';
import 'package:saint_bi/services/saint_api_exceptions.dart';
import 'package:saint_bi/services/invoice_calculator_service.dart';
import 'package:saint_bi/models/api_connection.dart'; // NUEVO
import 'package:saint_bi/services/database_service.dart'; // NUEVO
import 'package:saint_bi/models/login_response.dart'; // NUEVO - Para el tipo de retorno de login

const String _uiAuthErrorMessage =
    'Error de autenticación. Revise credenciales o URL.';
const String _uiSessionExpiredMessage =
    'Sesión expirada. Intentando re-autenticar...';
const String _uiGenericErrorMessage = 'Error al comunicarse con el servidor.';
const String _uiNetworkErrorMessage =
    'Error de red. Verifique su conexión a internet.';
const String _uiNoConnectionSelectedMessage =
    'Seleccione o configure una conexión de empresa.';

class InvoiceNotifier extends ChangeNotifier {
  final SaintApi _api = SaintApi();
  final InvoiceCalculator _invoiceCalculator = InvoiceCalculator();
  final DatabaseService _dbService = DatabaseService.instance; // NUEVO

  InvoiceSummary _invoiceSummary = InvoiceSummary();
  bool _isLoading = false;
  String? _errorMsg;
  String? _authtoken; // El token de la sesión activa
  Timer? _timer;
  bool _isReAuthenticating = false;

  DateTime? _startDate;
  DateTime? _endDate;

  ApiConnection? _activeConnection; // MODIFICADO: Conexión actualmente en uso
  List<ApiConnection> _availableConnections =
      []; // MODIFICADO: Lista para el Dropdown

  // Las credenciales hardcodeadas y pollingInterval fijo se eliminan de aquí.
  // Se tomarán de _activeConnection.

  InvoiceSummary get invoiceSummary => _invoiceSummary;
  bool get isLoading => _isLoading;
  String? get errorMsg => _errorMsg;
  bool get isAuthenticated => _authtoken != null && _authtoken!.isNotEmpty;

  // MODIFICADO: El intervalo de sondeo ahora depende de la conexión activa
  int get pollingIntervalSeconds =>
      _activeConnection?.pollingIntervalSeconds ??
      9999999; // Un valor muy alto si no hay conexión

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  ApiConnection? get activeConnection => _activeConnection;
  List<ApiConnection> get availableConnections => _availableConnections;

  InvoiceNotifier() {
    debugPrint('Inicializando InvoiceNotifier...');
    refreshAvailableConnections(); // MODIFICADO: Cargar conexiones al inicio
    // Ya no se llama a fetchInitialData() aquí, se hará cuando se seleccione una conexión.
  }

  // NUEVO: Método para cargar/refrescar la lista de conexiones disponibles desde la BD
  Future<void> refreshAvailableConnections({
    ApiConnection? newlySelected,
  }) async {
    _isLoading = true;
    // _errorMsg = null; // No limpiar error aquí, podría haber uno de no conexión
    notifyListeners();
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
        _errorMsg = _uiNoConnectionSelectedMessage;
        clearActiveConnectionAndData(); // Limpiar todo si no hay conexiones
      } else if (newlySelected != null) {
        // Priorizar la recién seleccionada/guardada si viene de la pantalla de config
        final found = _availableConnections.firstWhere(
          (c) => c.id == newlySelected.id,
          orElse: () => _availableConnections.first,
        );
        await setActiveConnection(found, fetchFullData: true);
      } else if (_activeConnection != null) {
        // Verificar si la conexión activa actual sigue en la lista (podría haber sido eliminada)
        final currentActiveStillExists = _availableConnections.any(
          (c) => c.id == _activeConnection!.id,
        );
        if (!currentActiveStillExists) {
          // La conexión activa ya no está, limpiar o seleccionar la primera
          debugPrint(
            'La conexión activa (ID: ${_activeConnection!.id}) ya no existe en la lista.',
          );
          clearActiveConnectionAndData(); // Opcional: setActiveConnection(_availableConnections.first);
          _errorMsg =
              _uiNoConnectionSelectedMessage; // Indicar que se debe seleccionar una nueva
        } else {
          // La conexión activa sigue siendo válida, no es necesario recargar datos a menos que se fuerce.
          // Esto evita recargas innecesarias si solo se está refrescando la lista de conexiones.
          _errorMsg = null; // Limpiar error si la activa es válida
        }
      } else {
        // Hay conexiones disponibles, pero ninguna activa.
        _errorMsg = _uiNoConnectionSelectedMessage;
      }
    } catch (e) {
      _errorMsg = "Error al cargar lista de conexiones: ${e.toString()}";
      clearActiveConnectionAndData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // NUEVO: Métodos para que ConnectionSettingsScreen pueda notificar cambios en la lista
  void addConnectionToList(ApiConnection connection) {
    // Prevenir duplicados por si acaso, aunque la BD tiene constraint UNIQUE
    if (!_availableConnections.any(
      (c) =>
          c.companyName.toLowerCase() == connection.companyName.toLowerCase(),
    )) {
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
      // Si la conexión actualizada era la activa, actualizar la instancia de _activeConnection
      if (_activeConnection?.id == connection.id) {
        _activeConnection = connection;
      }
      notifyListeners();
    }
  }

  void removeConnectionFromList(int connectionId) {
    _availableConnections.removeWhere((c) => c.id == connectionId);
    if (_activeConnection?.id == connectionId) {
      // Si la conexión activa fue eliminada, limpiar todo.
      clearActiveConnectionAndData();
      if (_availableConnections.isEmpty) {
        _errorMsg = _uiNoConnectionSelectedMessage;
      } else {
        _errorMsg = 'Conexión activa eliminada. Por favor, seleccione otra.';
      }
    }
    notifyListeners();
  }

  // MODIFICADO: Para establecer la conexión activa
  Future<void> setActiveConnection(
    ApiConnection? connection, {
    bool fetchFullData = true,
  }) async {
    if (connection == null) {
      // Si se deselecciona explícitamente
      clearActiveConnectionAndData();
      return;
    }

    // Evitar recargas si se selecciona la misma conexión y no se fuerza el fetch
    if (_activeConnection?.id == connection.id && !fetchFullData) {
      debugPrint(
        'setActiveConnection: Misma conexión (ID: ${connection.id}), no se fuerza recarga de datos.',
      );
      // Asegurarse que el error se limpie si es relevante
      if (_errorMsg == _uiNoConnectionSelectedMessage) _errorMsg = null;
      notifyListeners();
      return;
    }

    debugPrint(
      'Estableciendo conexión activa: ${connection.companyName} (ID: ${connection.id}), fetchFullData: $fetchFullData',
    );
    _activeConnection = connection;
    _authtoken = null; // Forzar re-login para la nueva conexión
    _invoiceSummary = InvoiceSummary(); // Resetear resumen
    _startDate = null; // Resetear filtros de fecha
    _endDate = null;
    _errorMsg = null; // Limpiar errores previos
    _isLoading = false; // Se gestionará en fetchInitialData si es necesario
    _isReAuthenticating = false;
    _stopPolling(); // Detener polling de la conexión anterior

    if (fetchFullData) {
      await fetchInitialData(); // Obtener datos para la nueva conexión
    } else {
      // Solo se actualizó la conexión (ej. al volver de settings), pero no se piden datos.
      // Pero sí notificamos para que la UI refleje la selección.
      notifyListeners();
    }
  }

  // NUEVO: Para limpiar estado cuando se deselecciona o elimina una conexión
  void clearActiveConnectionAndData() {
    debugPrint('Limpiando conexión activa y datos.');
    _activeConnection = null;
    _authtoken = null;
    _invoiceSummary = InvoiceSummary();
    _errorMsg = _availableConnections.isEmpty
        ? _uiNoConnectionSelectedMessage
        : 'Por favor, seleccione una empresa del listado.';
    _isLoading = false;
    _isReAuthenticating = false;
    _stopPolling();
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  // MODIFICADO: Manejo de errores ahora más genérico y notifica
  void _handleError(
    String message, {
    bool isAuthenticationIssue = false,
    dynamic error, // Para loguear el error original
    StackTrace? stackTrace, // Para loguear el stacktrace
  }) {
    _errorMsg = message;
    if (isAuthenticationIssue) {
      _authtoken = null; // Invalidar token si es un problema de autenticación
      debugPrint(
        'Token invalidado para "${_activeConnection?.companyName}" debido a error de autenticación.',
      );
      // No limpiar _activeConnection aquí, para que el usuario sepa qué conexión falló.
    }
    _isLoading = false; // Siempre detener la carga en error
    _isReAuthenticating = false; // Detener intento de re-autenticación
    debugPrint(
      'Error manejado para "${_activeConnection?.companyName ?? "N/A"}": $message. Excepción: $error, StackTrace: $stackTrace',
    );
    notifyListeners(); // Notificar a la UI sobre el error
  }

  // MODIFICADO: Filtrar por rango de fechas
  Future<void> filterByDateRange(DateTime? start, DateTime? end) async {
    if (_activeConnection == null) {
      _handleError(
        _uiNoConnectionSelectedMessage,
      ); // Usa el método _handleError
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
    _errorMsg = null; // Limpiar error de rango si lo había
    _invoiceSummary = InvoiceSummary(); // Resetear resumen antes de filtrar
    _stopPolling(); // Detener polling mientras se filtran y cargan nuevos datos
    notifyListeners();

    if (!isAuthenticated) {
      debugPrint(
        'No autenticado al filtrar por rango para "${_activeConnection!.companyName}". Intentando login completo.',
      );
      await fetchInitialData(); // fetchInitialData manejará _isLoading y _errorMsg
    } else {
      debugPrint(
        'Autenticado para "${_activeConnection!.companyName}". Obteniendo datos para el rango: ${_startDate?.toIso8601String()} - ${_endDate?.toIso8601String()}',
      );
      await _fetchSummaryData(
        isInitialFetchForCurrentOp: true,
      ); // Indicar que es parte de una operación de carga principal
      if (isAuthenticated && _errorMsg == null) {
        // Re-verificar después de fetch
        _startPollingInvoices(); // Reiniciar polling con el nuevo filtro
      }
    }
  }

  // MODIFICADO: Obtener datos iniciales para la conexión activa
  Future<void> fetchInitialData() async {
    if (_activeConnection == null) {
      _handleError(_uiNoConnectionSelectedMessage);
      _isLoading = false; // Asegurar que no quede en true
      notifyListeners();
      return;
    }

    debugPrint(
      'Iniciando fetchInitialData para "${_activeConnection!.companyName}". isLoading: $_isLoading, isReAuth: $_isReAuthenticating, error: $_errorMsg',
    );

    _isLoading = true;
    if (!_isReAuthenticating) {
      // Si NO es un intento de re-autenticación, resetear estado
      _errorMsg = null;
      _authtoken = null;
      _invoiceSummary =
          InvoiceSummary(); // Siempre resetear resumen para nueva carga/conexión
      _stopPolling();
    }
    // Si _isReAuthenticating es true, _errorMsg ya está como "sesión expirada"
    // y _invoiceSummary no se limpia para mantener datos viejos visibles.
    notifyListeners();

    try {
      // La documentación de la API (Documentacion_Web_Api.json) indica que el login:
      // - Devuelve el token en el header "Pragma".
      // - Devuelve información del usuario/empresa en el cuerpo JSON, incluyendo "enterprise".
      // Modificamos SaintApi.login para que devuelva un objeto LoginResponse.
      final LoginResponse? loginResponse = await _api.login(
        baseurl: _activeConnection!.baseUrl,
        username: _activeConnection!.username,
        password: _activeConnection!.password,
        terminal: _activeConnection!.terminal,
      );

      // El token se obtiene del header pragma, y se maneja dentro de SaintApi
      // si SaintApi.login devuelve un objeto que contenga el token o si se hace una llamada posterior.
      // Para este caso, vamos a asumir que SaintApi.login() sigue devolviendo el token como String?
      // y que el companyName del _activeConnection es el que se validó/ingresó en ConnectionSettingsScreen.
      // PERO lo ideal es que loginResponse.company sea la fuente del nombre de la empresa.

      // *** AJUSTE SEGÚN NUEVA DOCUMENTACIÓN DE LA API ***
      // El endpoint de login devuelve el nombre de la empresa en el cuerpo de la respuesta (`"enterprise"`).
      // Necesitamos que `_api.login` nos dé acceso a ese nombre.
      // Asumimos que `SaintApi.login` ahora devuelve `LoginResponse?` que contiene el token y el nombre de la empresa.

      // Re-implementación de la lógica de login basada en `LoginResponse`
      _authtoken = await _api.loginAndGetToken(
        // Un nuevo método hipotético en SaintApi
        baseurl: _activeConnection!.baseUrl,
        username: _activeConnection!.username,
        password: _activeConnection!.password,
        terminal: _activeConnection!.terminal,
      );

      if (_authtoken == null || _authtoken!.isEmpty) {
        throw AuthenticationException("Login fallido o token no recibido.");
      }
      debugPrint(
        'Login API call completed para "${_activeConnection!.companyName}". Token: ${(_authtoken ?? "").isNotEmpty ? "OBTENIDO" : "NO OBTENIDO"}',
      );

      // Verificar si el nombre de la empresa en _activeConnection (ingresado por el usuario o de una sesión previa)
      // coincide con el que podría devolver la API. La documentación de la API indica que el login devuelve "enterprise".
      // Si SaintApi.login devolviera LoginResponse, haríamos:
      // if (loginResponse.company.toLowerCase() != _activeConnection!.companyName.toLowerCase()) {
      //   debugPrint("Advertencia: Nombre de empresa en BD local ('${_activeConnection!.companyName}') difiere del de API ('${loginResponse.company}'). Actualizando local.");
      //   _activeConnection = _activeConnection!.copyWith(companyName: loginResponse.company);
      //   _dbService.updateConnection(_activeConnection!); // Actualizar en BD
      //   // Es importante notificar este cambio a la UI si el nombre cambia.
      //   // La lista _availableConnections también necesitaría actualizarse.
      // }
      // Por ahora, seguimos confiando en el companyName de _activeConnection.

      _isReAuthenticating =
          false; // Se completó el intento de (re)autenticación

      if (isAuthenticated) {
        _errorMsg = null; // Limpiar errores si el login fue exitoso
        debugPrint(
          'Login exitoso para "${_activeConnection!.companyName}", procediendo a _fetchSummaryData',
        );
        await _fetchSummaryData(isInitialFetchForCurrentOp: true);

        if (_errorMsg == null) {
          // Si _fetchSummaryData también fue exitoso
          debugPrint(
            'fetchInitialData: _fetchSummaryData exitoso para "${_activeConnection!.companyName}", iniciando polling.',
          );
          _startPollingInvoices();
        } else {
          // _fetchSummaryData falló
          debugPrint(
            'fetchInitialData: _fetchSummaryData falló después de login para "${_activeConnection!.companyName}". Error: $_errorMsg',
          );
          _stopPolling(); // No iniciar polling si hay error
        }
      } else {
        // Este bloque es menos probable si _api.login lanza excepciones adecuadamente.
        _handleError(
          _uiAuthErrorMessage,
          isAuthenticationIssue: true,
          error:
              "Token nulo o vacío post-login sin excepción previa para ${_activeConnection!.companyName}.",
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
      _handleError(
        _uiNetworkErrorMessage, // Mantener error de red para reintentos
        error: e,
        stackTrace: stackTrace,
      );
      // _stopPolling(); // No detener polling por errores de red, para que pueda reintentar
    } on UnknownApiExpection catch (e, stackTrace) {
      _handleError(_uiGenericErrorMessage, error: e, stackTrace: stackTrace);
      _stopPolling();
    } catch (e, stackTrace) {
      // Captura general
      _handleError(_uiGenericErrorMessage, error: e, stackTrace: stackTrace);
      _stopPolling();
    } finally {
      // isLoading se maneja dentro del try/catch y en _fetchSummaryData.
      // Si _isLoading sigue true y no estamos en re-autenticación con error de sesión, lo ponemos false.
      if (_isLoading &&
          (_errorMsg != _uiSessionExpiredMessage || !_isReAuthenticating)) {
        _isLoading = false;
      }
      // _isReAuthenticating ya se maneja dentro del try/catch
      notifyListeners();
      debugPrint(
        'fetchInitialData finalizado para "${_activeConnection?.companyName}". isLoading: $_isLoading, isAuthenticated: $isAuthenticated, error: $_errorMsg',
      );
    }
  }

  // MODIFICADO: Obtener datos de resumen para la conexión activa
  Future<void> _fetchSummaryData({
    bool isInitialFetchForCurrentOp = false,
  }) async {
    if (_activeConnection == null) {
      _handleError(
        _uiNoConnectionSelectedMessage,
        error: "Intento de fetch sin conexión activa.",
      );
      if (isInitialFetchForCurrentOp)
        _isLoading = false; // Asegurar que el loader principal se quite
      notifyListeners();
      return;
    }
    if (!isAuthenticated) {
      _handleError(
        'No autenticado para "${_activeConnection!.companyName}".',
        isAuthenticationIssue: true,
        error:
            "Intento de fetch sin token para ${_activeConnection!.companyName}.",
      );
      if (isInitialFetchForCurrentOp) _isLoading = false;
      notifyListeners();
      return;
    }

    // Si es un fetch por polling (no parte de una carga inicial) y no hay error de sesión,
    // activamos _isLoading. Si es parte de una carga inicial, _isLoading ya está en true.
    if (!isInitialFetchForCurrentOp && _errorMsg != _uiSessionExpiredMessage) {
      _isLoading = true;
      // Limpiar error si no es de sesión, ya que estamos reintentando.
      if (_errorMsg != null && _errorMsg != _uiSessionExpiredMessage)
        _errorMsg = null; // No limpiar si es sesión expirada
      notifyListeners();
    }
    // Si es una carga inicial, _errorMsg ya debería estar limpio o ser null desde fetchInitialData o filterByDate.

    debugPrint(
      'Iniciando _fetchSummaryData para "${_activeConnection!.companyName}" (isInitialOp: $isInitialFetchForCurrentOp). Token: ${_authtoken!.substring(0, 10)}... Filtro: $_startDate - $_endDate',
    );

    try {
      final List<Invoice> allInvoices = await _api.getInvoices(
        baseUrl: _activeConnection!.baseUrl,
        authtoken: _authtoken!,
      );
      debugPrint(
        '_fetchSummaryData para "${_activeConnection!.companyName}": Recibidas ${allInvoices.length} facturas de la API.',
      );

      // El servicio _invoiceCalculator ya maneja el filtrado por fecha si _startDate y _endDate están seteados.
      _invoiceSummary = _invoiceCalculator.calculateSummary(
        allInvoices: allInvoices,
        startDate: _startDate,
        endDate: _endDate,
      );
      debugPrint(
        '_fetchSummaryData para "${_activeConnection!.companyName}": Resumen calculado. Ventas: ${_invoiceSummary.totalSales}, Devoluciones: ${_invoiceSummary.totalReturns}',
      );

      // Limpiar el mensaje de error si todo fue bien Y no era un mensaje de sesión expirada
      // (porque ese mensaje se gestiona en el bloque `on SessionExpiredException`)
      if (_errorMsg != _uiSessionExpiredMessage) {
        _errorMsg = null;
      }
      _isReAuthenticating =
          false; // Si llegamos aquí, la re-autenticación (si la hubo) fue implícitamente exitosa.
    } on SessionExpiredException catch (e, stackTrace) {
      debugPrint(
        '_fetchSummaryData para "${_activeConnection!.companyName}": Sesión Expirada. Error: ${e.toString()}',
      );
      if (_isReAuthenticating) {
        // Ya estábamos re-autenticando y falló de nuevo (el login en fetchInitialData falló)
        _handleError(
          _uiAuthErrorMessage, // Mostrar error de autenticación genérico
          isAuthenticationIssue: true, // Marcar como problema de autenticación
          error: e, // Error original
          stackTrace: stackTrace,
        );
        _stopPolling(); // Detener polling porque la autenticación falló persistentemente.
        // _isLoading ya se pondrá false en _handleError
        return; // Salir porque no podemos continuar.
      }
      // Primera vez que detectamos sesión expirada en este ciclo de fetch
      _errorMsg = _uiSessionExpiredMessage;
      _authtoken = null; // Invalidar token localmente
      _isReAuthenticating = true; // Marcar que necesitamos re-autenticar
      notifyListeners(); // Notificar UI sobre el estado de "sesión expirada"

      _stopPolling(); // Detener polling actual
      await Future.delayed(const Duration(seconds: 1)); // Pequeña pausa
      await fetchInitialData(); // Intentar re-autenticar y obtener datos de nuevo
      return; // Salir de este fetch, ya que fetchInitialData se encargará
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
      // No detener polling por error de red, se reintentará si el timer sigue activo.
      // Si es parte de una carga inicial, _isLoading se pondrá false en el finally.
    } on UnknownApiExpection catch (e, stackTrace) {
      _handleError(_uiGenericErrorMessage, error: e, stackTrace: stackTrace);
      _stopPolling(); // Errores desconocidos podrían ser persistentes.
    } catch (e, stackTrace) {
      // Otra excepción no esperada
      _handleError(_uiGenericErrorMessage, error: e, stackTrace: stackTrace);
      _stopPolling();
    } finally {
      // isLoading se pone a false si no estamos en medio de una re-autenticación por sesión expirada.
      // Si _isReAuthenticating es true y _errorMsg es _uiSessionExpiredMessage, fetchInitialData se encargará.
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

  // MODIFICADO: Iniciar polling para la conexión activa
  void _startPollingInvoices() {
    _stopPolling(); // Asegurarse de que no haya timers duplicados
    if (isAuthenticated &&
        _activeConnection != null &&
        _activeConnection!.pollingIntervalSeconds > 0) {
      debugPrint(
        'Iniciando polling para "${_activeConnection!.companyName}" cada ${_activeConnection!.pollingIntervalSeconds} segundos.',
      );
      _timer = Timer.periodic(
        Duration(seconds: _activeConnection!.pollingIntervalSeconds),
        (timer) {
          if (_activeConnection == null || !isAuthenticated) {
            // Doble chequeo de seguridad
            _stopPolling();
            return;
          }
          debugPrint(
            'Ejecutando fetch por polling para "${_activeConnection!.companyName}"...',
          );
          _fetchSummaryData(
            isInitialFetchForCurrentOp: false,
          ); // No es una operación "principal" de carga
        },
      );
    } else {
      debugPrint(
        'No se inicia polling: no autenticado, sin conexión activa, o intervalo de polling no positivo.',
      );
    }
  }

  // MODIFICADO: Detener polling
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

// NUEVO: Extensión en SaintApi para facilitar el flujo de login que devuelve token.
// Esto es un helper, la lógica principal de login está en SaintApi.
extension SaintApiLoginHelper on SaintApi {
  Future<String?> loginAndGetToken({
    required String baseurl,
    required String username,
    required String password,
    required String terminal,
  }) async {
    // Esta función asume que tu SaintApi.login ya devuelve LoginResponse?
    // y que LoginResponse tiene un campo para el token, o que puedes extraer el token
    // de alguna manera después de un login exitoso.
    // La implementación original de SaintApi.login devuelve String? (el token).
    // Por lo tanto, podemos usarla directamente.

    // Si SaintApi.login devuelve LoginResponse y este contiene el token:
    /*
    final LoginResponse? response = await login(
        baseurl: baseurl,
        username: username,
        password: password,
        terminal: terminal);
    return response?.authtoken; // Suponiendo que LoginResponse tiene 'authtoken'
    */

    // Usando la firma original de SaintApi.login que devuelve String? (el token)
    return await login(
      baseurl: baseurl,
      username: username,
      password: password,
      terminal: terminal,
    );
  }
}

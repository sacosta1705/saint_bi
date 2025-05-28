import 'dart:async';
import 'package:flutter/material.dart';

import 'package:saint_bi/services/saint_api.dart';
import 'package:saint_bi/models/invoice.dart';
import 'package:saint_bi/models/invoice_summary.dart';
import 'package:saint_bi/services/saint_api_exceptions.dart';

// Constantes para mensajes de UI (sin cambios)
const String _uiAuthErrorMessage =
    'Error de autenticacion. Revise el usuario y clave.'; //
const String _uiSessionExpiredMessage =
    'Sesion expirada. Intentando re-autenticar...'; //
const String _uiGenericErrorMessage =
    'Error al comunicarse con el servidor.'; //
const String _uiNetworkErrorMessage =
    'Error de red. Verifique su conexion a internet.'; //

class InvoiceNotifier extends ChangeNotifier {
  final SaintApi _api = SaintApi(); //

  InvoiceSummary _invoiceSummary = InvoiceSummary(); //
  bool _isLoading = false; //
  String? _errorMsg; //
  String? _authtoken; //
  Timer? _timer; //
  bool _isReAuthenticating = false; //

  // Credenciales y configuración (sin cambios)
  final String _baseurl = 'http://64.135.37.214:6163/api'; //
  final String _username = '001'; //
  final String _password = '12345'; //
  final String _terminal = 'simple bi'; //
  final int _pollingIntervalSeconds = 9999; //

  InvoiceSummary get invoiceSummary => _invoiceSummary; //
  bool get isLoading => _isLoading; //
  String? get errorMsg => _errorMsg; //
  bool get isAuthenticated => _authtoken != null && _authtoken!.isNotEmpty; //
  int get pollingIntervalSeconds => _pollingIntervalSeconds; //

  InvoiceNotifier() {
    debugPrint('Inicializando InvoiceNotifier...'); //
    fetchInitialData(); //
  }

  void _handleError(
    String message,
    bool isInitialFetchContext, {
    bool isAuthenticationIssue = false,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _errorMsg = message;
    if (isAuthenticationIssue) {
      _authtoken = null; // Invalidar token si es un problema de autenticación
      debugPrint('Token invalidado debido a error de autenticación.');
    }

    _isLoading = false; // Siempre se termina la carga, ya sea con éxito o error
    _isReAuthenticating =
        false; // Se termina el intento de re-autenticación (si lo hubo)

    debugPrint('Error manejado: $message');
  }

  Future<void> fetchInitialData() async {
    debugPrint(
      'Iniciando fetchInitialData. Estado actual: isLoading=$_isLoading, isReAuthenticating=$_isReAuthenticating, errorMsg=$_errorMsg',
    );

    _isLoading = true;
    if (!_isReAuthenticating) {
      // Si no estamos en medio de una re-autenticación, es un inicio fresco o un refresh manual
      _errorMsg = null;
      _authtoken = null; // Limpiar token para forzar nuevo login
      _invoiceSummary = InvoiceSummary(); // Resetear resumen para la UI
      _stopPolling();
    } else {
      // Si _isReAuthenticating es true, _errorMsg ya debería ser _uiSessionExpiredMessage.
      // No limpiamos _errorMsg aquí para que la UI pueda mostrar "Re-autenticando..."
      // El token no se limpia, se reusará el intento de login.
      // _invoiceSummary se resetea para mostrar carga limpia.
      _invoiceSummary = InvoiceSummary();
    }
    notifyListeners();

    try {
      _authtoken = await _api.login(
        baseurl: _baseurl,
        username: _username,
        password: _password,
        terminal: _terminal,
      ); //
      debugPrint(
        'Login API call completed. Token: ${(_authtoken ?? "").isNotEmpty ? "OBTENIDO" : "NO OBTENIDO"}',
      );

      _isReAuthenticating =
          false; // Ya sea éxito o fallo del login, el intento de re-autenticación (si lo hubo) ha terminado.

      if (isAuthenticated) {
        _errorMsg =
            null; // Login exitoso, limpiar cualquier mensaje de error previo.
        debugPrint('Login exitoso, procediendo a _fetchSummaryData');
        await _fetchSummaryData(
          isInitialFetch: true,
        ); // Tratar como carga inicial de datos post-login

        if (_errorMsg == null) {
          // Solo iniciar polling si fetchSummaryData fue completamente exitoso
          debugPrint(
            'fetchInitialData: _fetchSummaryData exitoso, iniciando polling.',
          );
          _startPollingInvoices();
        } else {
          debugPrint(
            'fetchInitialData: _fetchSummaryData falló después de login exitoso. Error: $_errorMsg',
          );
          _stopPolling(); // No iniciar polling si hubo error post-login
        }
      } else {
        // Esto teóricamente no debería pasar si _api.login lanza AuthenticationException en fallo.
        _handleError(
          _uiAuthErrorMessage,
          true,
          isAuthenticationIssue: true,
          error: "Token nulo o vacío post-login sin excepción previa.",
        );
        _stopPolling();
      }
    } on AuthenticationException catch (e, stackTrace) {
      _handleError(
        _uiAuthErrorMessage,
        true,
        isAuthenticationIssue: true,
        error: e,
        stackTrace: stackTrace,
      );
      _stopPolling();
    } on NetworkException catch (e, stackTrace) {
      _handleError(
        _uiNetworkErrorMessage,
        true,
        error: e,
        stackTrace: stackTrace,
      );
      _stopPolling();
    } on UnknownApiExpection catch (e, stackTrace) {
      _handleError(
        _uiGenericErrorMessage,
        true,
        error: e,
        stackTrace: stackTrace,
      );
      _stopPolling();
    } catch (e, stackTrace) {
      _handleError(
        _uiGenericErrorMessage,
        true,
        error: e,
        stackTrace: stackTrace,
      );
      _stopPolling();
    } finally {
      // isLoading debería haber sido seteado a false por _handleError en caso de error,
      // o por _fetchSummaryData en caso de éxito.
      if (_isLoading) {
        // Si por alguna razón sigue true (ej. _fetchSummaryData no lo cambió)
        _isLoading = false;
      }
      _isReAuthenticating = false; // Asegurar que este flag se limpie
      notifyListeners();
      debugPrint(
        'fetchInitialData finalizado. Estado: isLoading=$_isLoading, errorMsg=$_errorMsg',
      );
    }
  }

  Future<void> _fetchSummaryData({bool isInitialFetch = false}) async {
    if (!isAuthenticated) {
      _handleError(
        'No autenticado. No se puede obtener datos de facturas.',
        isInitialFetch,
        isAuthenticationIssue: true,
        error: "Intento de fetch sin token.",
      );
      return;
    }

    // Si es un fetch de polling y había un error no relacionado con sesión, limpiarlo
    // para indicar que se está reintentando.
    if (!isInitialFetch &&
        _errorMsg != null &&
        _errorMsg != _uiSessionExpiredMessage) {
      _errorMsg = null;
      notifyListeners(); // Actualizar UI para quitar error viejo durante el reintento de polling
    }

    // isLoading se maneja en fetchInitialData para la carga inicial.
    // Para polling, la UI puede mostrar un indicador sutil si se desea, pero no es un _isLoading principal.
    // Si es un fetch inicial post-login, isLoading ya es true.
    debugPrint(
      'Iniciando _fetchSummaryData (isInitialFetch: $isInitialFetch). Token: ${_authtoken?.substring(0, 10)}...',
    );

    try {
      final List<Invoice> allInvoices = await _api.getInvoices(
        baseUrl: _baseurl,
        authtoken: _authtoken!,
      ); //
      debugPrint(
        '_fetchSummaryData: Recibidas ${allInvoices.length} facturas de la API.',
      );

      double tmpTotalSales = 0;
      double tmpTotalReturns = 0;
      double tmpTotalTax = 0;
      int tmpSalesCount = 0;
      int tmpReturnsCount = 0;

      List<Invoice> salesInvoices = [];
      List<Invoice> returnInvoices = [];
      Set<String> returnedDocNumbers = {};

      // 1. Separar facturas y registrar los codigos de las devoluciones
      for (var invoice in allInvoices) {
        if (invoice.type == 'A') {
          salesInvoices.add(invoice);
        } else if (invoice.type == 'B') {
          returnInvoices.add(invoice);
          returnedDocNumbers.add(invoice.docnumber);
        }
      }

      // 2. Procesar Ventas
      for (var saleInvoice in salesInvoices) {
        if (!returnedDocNumbers.contains(saleInvoice.docnumber)) {
          tmpTotalSales += saleInvoice.amount;
          tmpTotalTax += saleInvoice.amounttax;
          tmpSalesCount++;
        }
      }
      // 3. Procesar devoluciones
      for (var returnedInvoice in returnInvoices) {
        tmpTotalReturns += returnedInvoice.amount;
        tmpReturnsCount++;
      }

      debugPrint(
        '_fetchSummaryData: Totales calculados - Ventas=$tmpTotalSales (Count:$tmpSalesCount), Dev=$tmpTotalReturns (Count:$tmpReturnsCount), Imp=$tmpTotalTax',
      );

      _invoiceSummary = InvoiceSummary(
        totalSales: tmpTotalSales,
        totalReturns: tmpTotalReturns,
        totalTax: tmpTotalTax,
        salesCount: tmpSalesCount,
        returnsCount: tmpReturnsCount,
      ); //

      // Limpiar error solo si el error actual no es el de intento de re-autenticación.
      if (_errorMsg != _uiSessionExpiredMessage) {
        _errorMsg = null;
      }
      // _isReAuthenticating se limpiará en fetchInitialData si la re-autenticación fue exitosa.
      // Aquí, si llegamos sin SessionExpiredException, el ciclo de re-auth (si lo hubo) terminó.
      _isReAuthenticating = false;
    } on SessionExpiredException catch (e, stackTrace) {
      debugPrint('_fetchSummaryData: Sesión Expirada: ${e.toString()}');
      if (_isReAuthenticating) {
        // Ya estábamos re-autenticando y falló de nuevo con sesión expirada. Tratar como Auth error.
        _handleError(
          _uiAuthErrorMessage,
          isInitialFetch,
          isAuthenticationIssue: true,
          error: e,
          stackTrace: stackTrace,
        );
        _stopPolling();
        return; // Salir, _handleError ya notificó y actualizó isLoading.
      }
      // Primera vez que se detecta sesión expirada en este ciclo de fetch.
      _errorMsg = _uiSessionExpiredMessage;
      _isReAuthenticating = true;
      notifyListeners(); // Notificar para mostrar "Re-autenticando..."

      _stopPolling();
      await Future.delayed(const Duration(seconds: 1));
      await fetchInitialData(); // Esto intentará loguearse y luego hacer fetchSummaryData de nuevo.
      // No necesitamos más lógica aquí porque fetchInitialData manejará el estado final.
      return;
    } on AuthenticationException catch (e, stackTrace) {
      _handleError(
        _uiAuthErrorMessage,
        isInitialFetch,
        isAuthenticationIssue: true,
        error: e,
        stackTrace: stackTrace,
      );
      _stopPolling();
    } on NetworkException catch (e, stackTrace) {
      _handleError(
        _uiNetworkErrorMessage,
        isInitialFetch,
        error: e,
        stackTrace: stackTrace,
      );
      // No detenemos el polling aquí; podría ser un problema temporal de red.
    } on UnknownApiExpection catch (e, stackTrace) {
      _handleError(
        _uiGenericErrorMessage,
        isInitialFetch,
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      // Errores de parseo de Invoice.fromJson, u otros no esperados.
      _handleError(
        _uiGenericErrorMessage,
        isInitialFetch,
        error: e,
        stackTrace: stackTrace,
      );
      // Considera resetear _invoiceSummary si el error es crítico para los datos
      // _invoiceSummary = InvoiceSummary();
    } finally {
      // Si isInitialFetch es true, isLoading se manejará al final de fetchInitialData.
      // Si no es isInitialFetch (es un polling), no hay un _isLoading principal que gestionar aquí.
      if (isInitialFetch) {
        _isLoading =
            false; // La carga inicial de datos (post-login) ha terminado.
      }
      // _isReAuthenticating debería ser false aquí a menos que se haya lanzado SessionExpiredException y estemos a punto de re-llamar a fetchInitialData.
      notifyListeners();
      debugPrint(
        '_fetchSummaryData finalizado. Estado: isLoading=$_isLoading, errorMsg=$_errorMsg',
      );
    }
  }

  void _startPollingInvoices() {
    _stopPolling(); //
    if (isAuthenticated) {
      //
      debugPrint('Iniciando polling cada $_pollingIntervalSeconds segundos.');
      _timer = Timer.periodic(Duration(seconds: _pollingIntervalSeconds), (
        timer,
      ) {
        //
        debugPrint('Ejecutando fetch por polling...');
        _fetchSummaryData(isInitialFetch: false); // No es una carga inicial
      });
    } else {
      debugPrint('No se inicia polling: no autenticado.');
    }
  }

  void _stopPolling() {
    if (_timer != null && _timer!.isActive) {
      //
      debugPrint('Deteniendo polling.');
      _timer!.cancel(); //
      _timer = null; //
    }
  }

  @override
  void dispose() {
    debugPrint('Disposing InvoiceNotifier.');
    _stopPolling(); //
    super.dispose(); //
  }
}

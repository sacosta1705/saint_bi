import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:saint_bi/services/saint_api.dart';
import 'package:saint_bi/models/invoice.dart';
import 'package:saint_bi/models/invoice_summary.dart';
import 'package:saint_bi/services/saint_api_exceptions.dart';

const String _uiAuthErrorMessage =
    'Error de autenticacion. Revise el usuario y clave.';
const String _uiSessionExpiredMessage =
    'Sesion expirada. Intentando re-autenticar...';
const String _uiGenericErrorMessage = 'Error al comunicarse con el servidor.';
const String _uiNetworkErrorMessage =
    'Error de red. Verifique su conexion a internet.';

class InvoiceNotifier extends ChangeNotifier {
  final SaintApi _api = SaintApi();

  InvoiceSummary _invoiceSummary = InvoiceSummary();
  bool _isLoading = false;
  String? _errorMsg;
  String? _authtoken;
  Timer? _timer;
  bool _isReAuthenticating = false;

  DateTime? _startDate; // Nuevo: para fecha de inicio del filtro
  DateTime? _endDate; // Nuevo: para fecha de fin del filtro

  final String _baseurl = 'http://64.135.37.214:6163/api';
  final String _username = '001';
  final String _password = '12345';
  final String _terminal = 'simple bi';
  final int _pollingIntervalSeconds = 9999;

  InvoiceSummary get invoiceSummary => _invoiceSummary;
  bool get isLoading => _isLoading;
  String? get errorMsg => _errorMsg;
  bool get isAuthenticated => _authtoken != null && _authtoken!.isNotEmpty;
  int get pollingIntervalSeconds => _pollingIntervalSeconds;
  DateTime? get startDate => _startDate; // Nuevo getter
  DateTime? get endDate => _endDate; // Nuevo getter

  InvoiceNotifier() {
    debugPrint('Inicializando InvoiceNotifier...');
    fetchInitialData();
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
      _authtoken = null;
      debugPrint('Token invalidado debido a error de autenticación.');
    }
    _isLoading = false;
    _isReAuthenticating = false;
    debugPrint(
      'Error manejado: $message. Error: $error, StackTrace: $stackTrace',
    );
  }

  // Modificado para aceptar un rango de fechas
  Future<void> filterByDateRange(DateTime? start, DateTime? end) async {
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
    _invoiceSummary = InvoiceSummary();
    _stopPolling();
    notifyListeners();

    if (!isAuthenticated) {
      debugPrint(
        'No autenticado al filtrar por rango. Intentando login completo.',
      );
      await fetchInitialData();
    } else {
      debugPrint(
        'Autenticado. Obteniendo datos para el rango: ${_startDate?.toIso8601String()} - ${_endDate?.toIso8601String()}',
      );
      await _fetchSummaryData(isInitialFetch: true);
      if (isAuthenticated && _errorMsg == null) {
        _startPollingInvoices();
      }
    }
  }

  Future<void> fetchInitialData() async {
    debugPrint(
      'Iniciando fetchInitialData. isLoading: $_isLoading, isReAuth: $_isReAuthenticating, error: $_errorMsg, startDate: $_startDate, endDate: $_endDate',
    );

    _isLoading = true;
    if (!_isReAuthenticating) {
      _errorMsg = null;
      _authtoken = null;
      _invoiceSummary = InvoiceSummary();
      _stopPolling();
    } else {
      _invoiceSummary = InvoiceSummary();
    }
    notifyListeners();

    try {
      _authtoken = await _api.login(
        baseurl: _baseurl,
        username: _username,
        password: _password,
        terminal: _terminal,
      );
      debugPrint(
        'Login API call completed. Token: ${(_authtoken ?? "").isNotEmpty ? "OBTENIDO" : "NO OBTENIDO"}',
      );
      _isReAuthenticating = false;

      if (isAuthenticated) {
        _errorMsg = null;
        debugPrint('Login exitoso, procediendo a _fetchSummaryData');
        await _fetchSummaryData(isInitialFetch: true);

        if (_errorMsg == null) {
          debugPrint(
            'fetchInitialData: _fetchSummaryData exitoso, iniciando polling.',
          );
          _startPollingInvoices();
        } else {
          debugPrint(
            'fetchInitialData: _fetchSummaryData falló después de login. Error: $_errorMsg',
          );
          _stopPolling();
        }
      } else {
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
      if (_isLoading) {
        _isLoading = false;
      }
      _isReAuthenticating = false;
      notifyListeners();
      debugPrint(
        'fetchInitialData finalizado. isLoading: $_isLoading, error: $_errorMsg',
      );
    }
  }

  Future<void> _fetchSummaryData({bool isInitialFetch = false}) async {
    if (!isAuthenticated) {
      _handleError(
        'No autenticado. No se puede obtener datos.',
        isInitialFetch,
        isAuthenticationIssue: true,
        error: "Intento de fetch sin token.",
      );
      return;
    }

    if (!isInitialFetch &&
        _errorMsg != null &&
        _errorMsg != _uiSessionExpiredMessage) {
      _errorMsg = null;
      notifyListeners();
    }

    debugPrint(
      'Iniciando _fetchSummaryData (isInitialFetch: $isInitialFetch). Token: ${_authtoken?.substring(0, 10)}... Rango Filtro: $_startDate - $_endDate',
    );

    try {
      final List<Invoice> allInvoices = await _api.getInvoices(
        baseUrl: _baseurl,
        authtoken: _authtoken!,
      );
      debugPrint(
        '_fetchSummaryData: Recibidas ${allInvoices.length} facturas de la API.',
      );

      // --- INICIO DEL FILTRADO POR RANGO DE FECHA ---
      List<Invoice> invoicesToProcess = allInvoices;
      if (_startDate != null || _endDate != null) {
        invoicesToProcess = allInvoices.where((invoice) {
          try {
            DateTime invoiceDate = DateTime.parse(invoice.date);
            // Normalizar fecha de factura a medianoche para comparación correcta
            DateTime normalizedInvoiceDate = DateTime(
              invoiceDate.year,
              invoiceDate.month,
              invoiceDate.day,
            );

            bool isAfterOrOnStartDate = true;
            if (_startDate != null) {
              DateTime normalizedStartDate = DateTime(
                _startDate!.year,
                _startDate!.month,
                _startDate!.day,
              );
              isAfterOrOnStartDate = !normalizedInvoiceDate.isBefore(
                normalizedStartDate,
              );
            }

            bool isBeforeOrOnEndDate = true;
            if (_endDate != null) {
              DateTime normalizedEndDate = DateTime(
                _endDate!.year,
                _endDate!.month,
                _endDate!.day,
              );
              isBeforeOrOnEndDate = !normalizedInvoiceDate.isAfter(
                normalizedEndDate,
              );
            }
            return isAfterOrOnStartDate && isBeforeOrOnEndDate;
          } catch (e) {
            debugPrint(
              'Error parseando fecha de factura: ${invoice.date} para filtrado de rango. Error: $e',
            );
            return false;
          }
        }).toList();
        String rangeStr =
            "${_startDate != null ? DateFormat('dd/MM/yy').format(_startDate!) : 'Inicio'} - ${_endDate != null ? DateFormat('dd/MM/yy').format(_endDate!) : 'Fin'}";
        debugPrint(
          '_fetchSummaryData: Después de filtrar por rango [$rangeStr], quedan ${invoicesToProcess.length} facturas.',
        );
      } else {
        debugPrint(
          '_fetchSummaryData: No hay rango de fecha seleccionado, procesando todas las ${allInvoices.length} facturas.',
        );
      }
      // --- FIN DEL FILTRADO POR RANGO DE FECHA ---

      // ... (la lógica de cálculo de totales con salesInvoices, returnInvoices, etc. permanece igual pero usa invoicesToProcess)
      double tmpTotalSales = 0;
      double tmpTotalReturns = 0;
      double tmpTotalTax = 0;
      int tmpSalesCount = 0;
      int tmpReturnsCount = 0;

      List<Invoice> salesInvoices = [];
      List<Invoice> returnInvoices = [];
      Set<String> returnedDocNumbers = {};

      for (var invoice in invoicesToProcess) {
        // Usar la lista ya filtrada por fecha (o no)
        if (invoice.type == 'A') {
          salesInvoices.add(invoice);
        } else if (invoice.type == 'B') {
          returnInvoices.add(invoice);
          returnedDocNumbers.add(invoice.docnumber);
        }
      }

      for (var saleInvoice in salesInvoices) {
        if (!returnedDocNumbers.contains(saleInvoice.docnumber)) {
          tmpTotalSales += saleInvoice.amount;
          tmpTotalTax += saleInvoice.amounttax;
          tmpSalesCount++;
        }
      }

      for (var returnInvoice in returnInvoices) {
        tmpTotalReturns += returnInvoice.amount;
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
      );

      if (_errorMsg != _uiSessionExpiredMessage) {
        _errorMsg = null;
      }
      _isReAuthenticating = false;
    } on SessionExpiredException catch (e, stackTrace) {
      debugPrint('_fetchSummaryData: Sesión Expirada: ${e.toString()}');
      if (_isReAuthenticating) {
        _handleError(
          _uiAuthErrorMessage,
          isInitialFetch,
          isAuthenticationIssue: true,
          error: e,
          stackTrace: stackTrace,
        );
        _stopPolling();
        return;
      }
      _errorMsg = _uiSessionExpiredMessage;
      _isReAuthenticating = true;
      notifyListeners();

      _stopPolling();
      await Future.delayed(const Duration(seconds: 1));
      await fetchInitialData();
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
    } on UnknownApiExpection catch (e, stackTrace) {
      _handleError(
        _uiGenericErrorMessage,
        isInitialFetch,
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      _handleError(
        _uiGenericErrorMessage,
        isInitialFetch,
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      if (isInitialFetch) {
        _isLoading = false;
      }
      notifyListeners();
      debugPrint(
        '_fetchSummaryData finalizado. isLoading: $_isLoading, error: $_errorMsg',
      );
    }
  }

  void _startPollingInvoices() {
    _stopPolling();
    if (isAuthenticated) {
      debugPrint(
        'Iniciando polling cada $_pollingIntervalSeconds segundos. Rango filtro: $_startDate - $_endDate',
      );
      _timer = Timer.periodic(Duration(seconds: _pollingIntervalSeconds), (
        timer,
      ) {
        debugPrint(
          'Ejecutando fetch por polling... Rango filtro: $_startDate - $_endDate',
        );
        _fetchSummaryData(isInitialFetch: false);
      });
    } else {
      debugPrint('No se inicia polling: no autenticado.');
    }
  }

  void _stopPolling() {
    if (_timer != null && _timer!.isActive) {
      debugPrint('Deteniendo polling.');
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

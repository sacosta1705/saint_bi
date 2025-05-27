import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';

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

  final String _baseurl = 'http://64.135.37.214:6163/api';
  final String _username = '001';
  final String _password = '12345';
  final String _terminal = 'simple bi';
  final int _pollingIntervalSeconds = 60;

  InvoiceSummary get invoiceSummary => _invoiceSummary;
  bool get isLoading => _isLoading;
  String? get errorMsg => _errorMsg;
  bool get isAuthenticated => _authtoken != null && _authtoken!.isNotEmpty;
  int get pollingIntervalSeconds => _pollingIntervalSeconds;

  InvoiceNotifier() {
    developer.log('Inicializando notifier...', name: 'InvoiceNotifier');
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    _isLoading = true;
    _errorMsg = null;

    if (!_isReAuthenticating) {
      _authtoken = null;
    }

    _invoiceSummary = InvoiceSummary();
    _stopPolling();

    notifyListeners();

    try {
      _authtoken = await _api.login(
        baseurl: _baseurl,
        username: _username,
        password: _password,
        terminal: _terminal,
      );

      if (isAuthenticated) {
        _isReAuthenticating = false;
        await _fetchSummaryData(isInitialFetch: true);

        if (_errorMsg == null) {
          _startPollingInvoices();
        }
      } else {
        _errorMsg = _uiAuthErrorMessage;
      }
    } on AuthenticationException catch (e) {
      _errorMsg = _uiAuthErrorMessage;
      developer.log(e.toString());
    } on NetworkException catch (e) {
      _errorMsg = _uiNetworkErrorMessage;
      developer.log(e.toString());
    } on UnknownApiExpection catch (e) {
      _errorMsg = _uiGenericErrorMessage;
      developer.log(e.toString());
    } catch (e) {
      _errorMsg = _uiGenericErrorMessage;
      developer.log(e.toString());
    }

    _isLoading = false;
    _isReAuthenticating = false;
    notifyListeners();
  }

  Future<void> _fetchSummaryData({bool isInitialFetch = false}) async {
    if (!isAuthenticated) {
      _errorMsg = 'No autenticado. No se puede obtener datos.';
      if (isInitialFetch || _isReAuthenticating) _isLoading = false;
      _isReAuthenticating = false;
      notifyListeners();
      return;
    }

    if (isInitialFetch && !_isReAuthenticating) {
      _isLoading = true;
      _errorMsg = null;
      notifyListeners();
    } else if (!_isReAuthenticating) {
      _errorMsg = null;
      notifyListeners();
    }

    try {
      final List<Invoice> invoices = await _api.getInvoices(
        baseUrl: _baseurl,
        authtoken: _authtoken!,
      );

      double tmpTotalSales = 0;
      double tmpTotalReturns = 0;
      double tmpTotalTax = 0;
      int tmpSalesCount = 0;
      int tmpReturnsCount = 0;

      for (var invoice in invoices) {
        if (invoice.type == 'A') {
          tmpTotalSales += invoice.amount;
          tmpTotalTax += invoice.amounttax;
          tmpSalesCount++;
        } else if (invoice.type == 'B') {
          tmpTotalReturns += invoice.amount;
          tmpTotalTax += invoice.amounttax;
          tmpReturnsCount++;
        }
      }

      if (_invoiceSummary.totalSales != tmpTotalSales ||
          _invoiceSummary.totalReturns != tmpTotalReturns ||
          _invoiceSummary.totalTax != tmpTotalTax ||
          _invoiceSummary.salesCount != tmpSalesCount ||
          _invoiceSummary.returnsCount != tmpReturnsCount) {
        _invoiceSummary = InvoiceSummary(
          totalSales: tmpTotalSales,
          totalReturns: tmpTotalReturns,
          totalTax: tmpTotalTax,
          salesCount: tmpSalesCount,
          returnsCount: tmpReturnsCount,
        );
      }

      _errorMsg = null;
      _isReAuthenticating = false;
    } on SessionExpiredException catch (e) {
      developer.log(e.toString());
      if (_isReAuthenticating) {
        _errorMsg = _uiAuthErrorMessage;
        _stopPolling();
        _isLoading = false;
        _isReAuthenticating = false;
        notifyListeners();
        return;
      }

      _errorMsg = _uiSessionExpiredMessage;
      _isReAuthenticating = true;
      notifyListeners();
      _stopPolling();
      await Future.delayed(const Duration(seconds: 1));
      await fetchInitialData();
      return;
    } on NetworkException catch (e) {
      _errorMsg = _uiNetworkErrorMessage;
      developer.log(e.toString());
    } on AuthenticationException catch (e) {
      _errorMsg = _uiAuthErrorMessage;
      developer.log(e.toString());
    } on UnknownApiExpection catch (e) {
      _errorMsg = _uiGenericErrorMessage;
      developer.log(e.toString());
    } catch (e) {
      _errorMsg = _uiGenericErrorMessage;
      developer.log(e.toString());
    } finally {
      if (!_isReAuthenticating) {
        if (isInitialFetch) _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _startPollingInvoices() {
    _stopPolling();
    if (isAuthenticated) {
      _timer = Timer.periodic(Duration(seconds: _pollingIntervalSeconds), (
        timer,
      ) {
        _fetchSummaryData(); //
      });
    }
  }

  void _stopPolling() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}

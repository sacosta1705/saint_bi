import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:saint_bi/services/saint_api.dart';

class InvoiceNotifier extends ChangeNotifier {
  final SaintApi _api = SaintApi();

  int _invoiceCount = 0;
  bool _isLoading = false;
  String? _errorMsg;
  String? _authtoken;
  Timer? _timer;

  final String _baseurl = 'http://64.135.37.214:6163/api';
  final String _username = '001';
  final String _password = '12345';
  final String _terminal = 'simple bi';

  int get invoiceCount => _invoiceCount;
  bool get isLoading => _isLoading;
  String? get errorMsg => _errorMsg;
  bool get isAuthenticated => _authtoken != null && _authtoken!.isNotEmpty;

  InvoiceNotifier() {
    developer.log(
      'InvoiceNotifier initialized. Calling fetchInitialData...',
      name: 'InvoiceNotifier',
    );
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    developer.log('fetchInitialData called.', name: 'InvoiceNotifier'); //
    _isLoading = true;
    _errorMsg = null;
    _authtoken = null;
    _stopPolling();
    notifyListeners();

    developer.log(
      'Attempting login with: username: $_username, terminal: $_terminal',
      name: 'InvoiceNotifier',
    );
    _authtoken = await _api.login(
      baseurl: _baseurl,
      username: _username,
      password: _password,
      terminal: _terminal,
    );

    if (isAuthenticated) {
      developer.log(
        'Login successful. Pragma token stored: $_authtoken. Fetching initial invoice count...',
        name: 'InvoiceNotifier',
      );
      await _fetchInvoiceCount(isInitialFetch: true); //
      if (_errorMsg == null) {
        developer.log(
          'Initial invoice count successful. Starting polling.',
          name: 'InvoiceNotifier',
        );
        _startPollingInvoices();
      } else {
        developer.log(
          'Initial invoice count failed. Polling NOT started.',
          name: 'InvoiceNotifier',
          error: _errorMsg,
        );
      }
    } else {
      _errorMsg = 'Error de autenticacion. Revisa logs de SaintApi.login.'; //
      developer.log(
        'Login failed in InvoiceNotifier.',
        name: 'InvoiceNotifier',
        error: _errorMsg,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchInvoiceCount({bool isInitialFetch = false}) async {
    developer.log(
      '_fetchInvoiceCount called. isInitialFetch: $isInitialFetch',
      name: 'InvoiceNotifier',
    );
    if (!isAuthenticated) {
      _errorMsg = 'No autenticado. No se puede obtener datos.'; //
      developer.log(_errorMsg!, name: 'InvoiceNotifier', error: _errorMsg);
      if (isInitialFetch) notifyListeners();
      return;
    }

    if (isInitialFetch) {
      _isLoading = true;
    }

    if (_errorMsg != 'Sesion expirada o acceso negado.') {
      _errorMsg = null;
    }

    developer.log(
      'Fetching invoice count using Pragma: $_authtoken',
      name: 'InvoiceNotifier',
    );
    try {
      final count = await _api.getInvoiceCount(
        baseUrl: _baseurl,
        authtoken: _authtoken!,
      );

      if (count != null) {
        if (_invoiceCount != count) {
          _invoiceCount = count;
          developer.log(
            'Invoice count updated to: $_invoiceCount',
            name: 'InvoiceNotifier',
          );
        }
        _errorMsg = null;
      } else {
        if (isInitialFetch || _errorMsg == null) {
          _errorMsg = 'No se pudo obtener el conteo de facturas.';
        }
        developer.log(_errorMsg!, name: 'InvoiceNotifier', error: _errorMsg);
      }
    } on Exception catch (e, stackTrace) {
      developer.log(
        'Exception during _fetchInvoiceCount',
        name: 'InvoiceNotifier',
        error: e,
        stackTrace: stackTrace,
      );
      if (e.toString().contains('Sesion expirada.')) {
        _errorMsg =
            'Sesion expirada o acceso negado. Intentando re-autenticar...';
        developer.log(_errorMsg!, name: 'InvoiceNotifier', error: _errorMsg);
        notifyListeners();
        _stopPolling();
        await Future.delayed(const Duration(seconds: 1));
        await fetchInitialData();
        return;
      } else {
        if (isInitialFetch || _errorMsg == null) {
          _errorMsg =
              'Error al obtener conteo de facturas: ${e.toString().substring(0, (e.toString().length > 100) ? 100 : e.toString().length)}...'; //
        }
        developer.log(
          'Otro error al obtener conteo',
          name: 'InvoiceNotifier',
          error: _errorMsg,
        );
      }
    } finally {
      if (isInitialFetch) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  void _startPollingInvoices() {
    _stopPolling();
    if (isAuthenticated) {
      developer.log(
        'Starting polling timer. Interval: 15 seconds.',
        name: 'InvoiceNotifier',
      );
      _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
        developer.log(
          'Polling tick - calling _fetchInvoiceCount.',
          name: 'InvoiceNotifier',
        );
        _fetchInvoiceCount(); //
      });
    } else {
      developer.log(
        'Not authenticated. Polling not started.',
        name: 'InvoiceNotifier',
      );
    }
  }

  void _stopPolling() {
    if (_timer != null && _timer!.isActive) {
      developer.log('Stopping polling timer.', name: 'InvoiceNotifier'); //
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    developer.log(
      'InvoiceNotifier disposed. Stopping polling.',
      name: 'InvoiceNotifier',
    ); //
    _stopPolling(); //
    super.dispose();
  }
}

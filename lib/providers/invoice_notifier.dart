import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saint_bi/services/saint_api.dart';

class InvoiceNotifier extends ChangeNotifier {
  final SaintApi _api = SaintApi();

  int _invoiceCount = 0;
  bool _isLoading = false;
  String? _errorMsg;
  String? _authtoken;
  Timer? _timer;

  final String _baseurl = 'http://64.135.37.214:6163/api/v1';
  final String _username = '001';
  final String _password = '12345';
  final String _terminal = 'simple bi';

  int get invoiceCount => _invoiceCount;
  bool get isLoading => _isLoading;
  String? get errorMsg => _errorMsg;
  bool get isAuthenticated => _authtoken != null && _authtoken!.isNotEmpty;

  InvoiceNotifier() {
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    _isLoading = true;
    _errorMsg = null;
    _authtoken = null;
    _stopPolling();
    notifyListeners();

    _authtoken = await _api.login(
      baseurl: _baseurl,
      username: _username,
      password: _password,
      terminal: _terminal,
    );

    if (isAuthenticated) {
      await _fetchInvoiceCount(isInitialFetch: true);
      if (_errorMsg == null) {
        _startPollingInvoices();
      }
    } else {
      _errorMsg = 'Error de autenticacion.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchInvoiceCount({bool isInitialFetch = false}) async {
    if (!isAuthenticated) {
      _errorMsg = 'No autenticado. No se puede obtener datos.';
      if (isInitialFetch) notifyListeners();
      return;
    }

    if (isInitialFetch) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final count = await _api.getInvoiceCount(
        baseUrl: _baseurl,
        authtoken: _authtoken!,
      );

      if (count != null) {
        if (_invoiceCount != count) {
          _invoiceCount = count;
        }

        _errorMsg = null;
      } else {
        if (isInitialFetch || _errorMsg == null) {
          _errorMsg = 'No se pudo obtener el conteo de facturas.';
        }
      }
    } on Exception catch (e) {
      if (e.toString().contains('Session Expired or Forbidden')) {
        _errorMsg = 'Sesion expirada o acceso negado.';
        notifyListeners();
        _stopPolling();
        await Future.delayed(const Duration(seconds: 1));
        await fetchInitialData();
        return;
      } else {
        if (isInitialFetch || _errorMsg == null) {
          _errorMsg = 'Error al obtener conteo de facturas';
        }
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
      _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
        _fetchInvoiceCount();
      });
    }
  }

  void _stopPolling() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}

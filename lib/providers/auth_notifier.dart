import 'package:flutter/material.dart';
import 'package:saint_intelligence/models/api_connection.dart';
import 'package:saint_intelligence/models/login_response.dart';
import 'package:saint_intelligence/services/saint_api.dart';
import 'package:saint_intelligence/services/saint_api_exceptions.dart';

class AuthNotifier extends ChangeNotifier {
  final SaintApi _api;
  AuthNotifier(this._api);

  String? _authtoken;
  LoginResponse? _loginResponse;
  bool _isLoading = true;
  String? _errorMsg;
  bool _isReAuthenticating = false;

  String? get authtoken => _authtoken;
  LoginResponse? get loginResponse => _loginResponse;
  bool get isLoading => _isLoading;
  String? get errorMsg => _errorMsg;
  bool get isAuthenticated => _authtoken != null && _authtoken!.isNotEmpty;

  Future<void> logout() async {
    _authtoken = null;
    _loginResponse = null;
    _errorMsg = null;
  }

  void clearError() {
    _errorMsg = null;
    notifyListeners();
  }

  Future<bool> login(ApiConnection conn, String password) async {
    _isLoading = true;
    _errorMsg = null;
    notifyListeners();

    try {
      final response = await _api.login(
        baseurl: conn.baseUrl,
        username: conn.username,
        password: conn.password,
        terminal: conn.terminal,
      );

      if (response == null ||
          response.authToken == null ||
          response.authToken!.isEmpty) {
        throw AuthenticationException(
            'Respuesta del inicio de sesion invalida.');
      }

      _authtoken = response.authToken;
      _loginResponse = response;
      _errorMsg = null;
      return true;
    } on SaintApiExceptions catch (e) {
      _errorMsg = 'Error de inicio de sesion. ${e.msg}';
      return false;
    } catch (e) {
      _errorMsg = 'Error inesperado: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reAuthenticate(ApiConnection conn) async {
    if (_isReAuthenticating) return false;

    _isReAuthenticating = true;
    _errorMsg = 'Sesion expirada. Intentando re-iniciar sesión.';
    notifyListeners();

    try {
      final response = await _api.login(
        baseurl: conn.baseUrl,
        username: conn.username,
        password: conn.password,
        terminal: conn.terminal,
      );

      if (response != null &&
          response.authToken != null &&
          response.authToken!.isNotEmpty) {
        _authtoken = response.authToken;
        _loginResponse = response;
        _errorMsg = null;
        _isReAuthenticating = false;
        notifyListeners();
        return true;
      } else {
        throw AuthenticationException("Fallo la re-autenticación.");
      }
    } catch (e) {
      await logout();
      _errorMsg = "Su sesión ha expirado. Por favor, inicie sesión de nuevo.";
      _isReAuthenticating = false;
      notifyListeners();
      return false;
    }
  }
}

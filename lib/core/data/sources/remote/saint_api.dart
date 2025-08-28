import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:saint_bi/core/data/sources/remote/saint_api_exceptions.dart';
import 'package:saint_bi/core/data/models/login_response.dart';

class SaintApi {
  final String apikey = 'B5D31933-C996-476C-B116-EF212A41479A';
  final int apiid = 1093;

  Future<dynamic> _fetchData(
    String endpoint, {
    required String baseUrl,
    required String authtoken,
    Map<String, String>? params,
  }) async {
    String url = '$baseUrl/v1/adm/$endpoint';

    if (params != null) {
      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      url += '?$queryString';
    }
    final Uri uri = Uri.parse(url);

    // developer.log('Enviando request a $uri con $authtoken.');
    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json', 'Pragma': authtoken},
      );
      // developer.log(response.body);
      return _handleResponse(response);
    } catch (e) {
      throw SaintApiExceptions('No fue posible conectarse al servidor: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    try {
      final responseBody = utf8.decode(response.bodyBytes);
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonData;
      } else {
        final String message =
            (jsonData as Map<String, dynamic>)['message'] ??
            'Error desconocido desde el API.';
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw SessionExpiredException(message);
        }
        throw UnknownApiExpection('Error: ${response.statusCode}: $message');
      }
    } on FormatException {
      throw UnknownApiExpection('Error al procesar la respuesta del servidor');
    }
  }

  Future<LoginResponse?> login({
    required String baseurl,
    required String username,
    required String password,
    required String terminal,
  }) async {
    final String credentials = '$username:$password';
    final String basicauth = 'Basic ${base64Encode(utf8.encode(credentials))}';

    final Uri loginUrl = Uri.parse('$baseurl/v1/main/login');

    try {
      final response = await http.post(
        loginUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': basicauth,
          'x-api-key': apikey,
          'x-api-id': apiid.toString(),
        },
        body: jsonEncode({'terminal': terminal}),
      );

      if (response.statusCode == 200) {
        final String? authtoken = response.headers['pragma'];
        if (authtoken == null || authtoken.isEmpty) {
          throw AuthenticationException(
            "Token Pragma nulo o vacío después del login.",
          );
        }

        try {
          final responseBody = utf8.decode(response.bodyBytes);
          final jsonData = jsonDecode(responseBody) as Map<String, dynamic>;

          final loginData = LoginResponse.fromJson(
            jsonData,
            pragmaToken: authtoken,
          );

          return loginData;
        } catch (e) {
          throw UnknownApiExpection(
            'Error al procesar la respuesta del servidor (datos de login).',
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthenticationException(
          'Credenciales inválidas, API Key/ID incorrecta o acceso denegado (Status: ${response.statusCode}).',
        );
      } else {
        throw UnknownApiExpection(
          'Error desconocido durante el login (Status: ${response.statusCode}).',
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException("Error de red durante el login: ${e.message}");
    } on SocketException catch (e) {
      throw NetworkException(
        "Error de conexión durante el login: ${e.message}",
      );
    } catch (e) {
      if (e is SaintApiExceptions) rethrow;
      throw UnknownApiExpection(
        'Excepción no controlada durante el login: ${e.toString()}',
      );
    }
  }

  Future<List<dynamic>> getInvoices({
    required String baseUrl,
    required String authtoken,
    Map<String, String>? params,
  }) async {
    // developer.log('Leyendo Ventas con datos: URL:$baseUrl Pragma:$authtoken');
    return await _fetchData(
      'invoices',
      baseUrl: baseUrl,
      authtoken: authtoken,
      params: params,
    );
  }

  Future<dynamic> getConfiguration({
    required int id,
    required String baseUrl,
    required String authtoken,
    Map<String, String>? params,
  }) async {
    return await _fetchData(
      'config/$id',
      baseUrl: baseUrl,
      authtoken: authtoken,
    );
  }

  Future<List<dynamic>> getPurchases({
    required String baseUrl,
    required String authtoken,
    Map<String, String>? params,
  }) async {
    return await _fetchData(
      'purchases',
      baseUrl: baseUrl,
      authtoken: authtoken,
      params: params,
    );
  }

  Future<List<dynamic>> getInvoiceItems({
    required String baseUrl,
    required String authtoken,
    Map<String, String>? params,
  }) async {
    return await _fetchData(
      'invoiceitems',
      baseUrl: baseUrl,
      authtoken: authtoken,
      params: params,
    );
  }

  Future<List<dynamic>> getAccountsReceivable({
    required String baseUrl,
    required String authtoken,
    Map<String, String>? params,
  }) async {
    return await _fetchData(
      'accreceivables',
      baseUrl: baseUrl,
      authtoken: authtoken,
      params: params,
    );
  }

  Future<List<dynamic>> getAccountsPayable({
    required String baseUrl,
    required String authtoken,
    Map<String, String>? params,
  }) async {
    return await _fetchData(
      'accpayables',
      baseUrl: baseUrl,
      authtoken: authtoken,
      params: params,
    );
  }

  Future<List<dynamic>> getProducts({
    required String baseUrl,
    required String authtoken,
    Map<String, String>? params,
  }) async {
    return await _fetchData(
      'products',
      baseUrl: baseUrl,
      authtoken: authtoken,
      params: params,
    );
  }

  Future<List<dynamic>> getPurchaseItems({
    required String baseUrl,
    required String authtoken,
    Map<String, String>? params,
  }) async {
    return await _fetchData(
      'purchaseitems',
      baseUrl: baseUrl,
      authtoken: authtoken,
      params: params,
    );
  }

  Future<List<dynamic>> getInventoryOperations({
    required String baseUrl,
    required String authtoken,
    Map<String, String>? params,
  }) async {
    return await _fetchData(
      'stocks',
      baseUrl: baseUrl,
      authtoken: authtoken,
      params: params,
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:saint_bi/services/saint_api_exceptions.dart';
import 'package:saint_bi/models/login_response.dart';

class SaintApi {
  final String apikey = 'B5D31933-C996-476C-B116-EF212A41479A';
  final int apiid = 1093;

  Future<dynamic> _fetchData(
    String endpoint, {
    required String baseUrl,
    required String authtoken,
    Map<String, String>? params,
  }) async {
    final Uri uri =
        Uri.parse('$baseUrl/v1/adm/$endpoint').replace(queryParameters: params);

    try {
      final response = await http.get(uri, headers: {
        'Contenty-Type': 'application/json',
        'Authorization': 'Basic $authtoken',
      });
      return _handleResponse(response);
    } catch (e) {
      throw SaintApiExceptions('No fue posible conectarse al servidor: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw SaintApiExceptions(error['message'] ?? 'Error desconocido');
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
    return await _fetchData(
      'invoices',
      baseUrl: baseUrl,
      authtoken: authtoken,
      params: params,
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

  Future<List<dynamic>> getInventoryOperations({
    required String baseUrl,
    required String authtoken,
    Map<String, String>? params,
  }) async {
    return await _fetchData(
      'inventories',
      baseUrl: baseUrl,
      authtoken: authtoken,
      params: params,
    );
  }

  Future<Map<String, dynamic>> getConfig({
    required String baseUrl,
    required String authtoken,
    Map<String, String>? params,
  }) async {
    return await _fetchData(
      'config',
      baseUrl: baseUrl,
      authtoken: authtoken,
      params: params,
    );
  }

  // Future<List<Purchase>> getPurchases({
  //   required String baseUrl,
  //   required String authToken,
  // }) async {
  //   final Uri uri = Uri.parse('$baseUrl/v1/adm/purchases');

  //   try {
  //     final response = await http.get(uri, headers: {'pragma': authToken});

  //     if (response.statusCode == 200) {
  //       final String responseBody = utf8.decode(response.bodyBytes);
  //       final List<dynamic> data = jsonDecode(responseBody);

  //       if (data.isEmpty) {
  //         return [];
  //       }

  //       List<Purchase> purchases = [];
  //       for (var item in data) {
  //         try {
  //           purchases.add(
  //             PurchaseParser.fromJson(item as Map<String, dynamic>),
  //           );
  //         } catch (e) {
  //           debugPrint('Error al parsear un objeto Purchase: $e. JSON: $item');
  //         }
  //       }
  //       return purchases;
  //     } else if (response.statusCode == 403) {
  //       throw SessionExpiredException(
  //         'Sesión expirada o acceso denegado al obtener compras (Status: 403).',
  //       );
  //     } else {
  //       throw UnknownApiExpection(
  //         'Error desconocido al obtener compras (Status: ${response.statusCode}). Body: ${response.body}',
  //       );
  //     }
  //   } on http.ClientException catch (e) {
  //     throw NetworkException("Error de red al obtener compras: ${e.message}");
  //   } on SocketException catch (e) {
  //     throw NetworkException(
  //       "Error de conexión al obtener compras: ${e.message}",
  //     );
  //   } on FormatException catch (e) {
  //     throw UnknownApiExpection(
  //       'Error al procesar la respuesta del servidor (compras - JSON inválido): ${e.message}',
  //     );
  //   } catch (e) {
  //     if (e is SaintApiExceptions) rethrow;
  //     throw UnknownApiExpection(
  //       'Excepción no controlada al obtener compras: ${e.toString()}',
  //     );
  //   }
  // }

  // Future<List<Invoice>> getInvoices({
  //   required String baseUrl,
  //   required String authtoken,
  // }) async {
  //   final Uri uri = Uri.parse('$baseUrl/v1/adm/invoices');

  //   try {
  //     final response = await http.get(uri, headers: {'pragma': authtoken});

  //     if (response.statusCode == 200) {
  //       final String responseBody = utf8.decode(response.bodyBytes);
  //       final List<dynamic> data = jsonDecode(responseBody);

  //       if (data.isEmpty) {
  //         return [];
  //       }

  //       List<Invoice> invoices = [];
  //       for (var jsonItem in data) {
  //         try {
  //           invoices.add(
  //             InvoiceParser.fromJson(jsonItem as Map<String, dynamic>),
  //           );
  //         } catch (e) {
  //           debugPrint(
  //             'Error al parsear un objeto Invoice individual. Se omitirá este objeto. JSON: $jsonItem. Error: $e',
  //           );
  //         }
  //       }
  //       return invoices;
  //     } else if (response.statusCode == 403) {
  //       throw SessionExpiredException(
  //         "Sesión expirada o acceso negado al obtener facturas (Status: 403).",
  //       );
  //     } else {
  //       throw UnknownApiExpection(
  //         'Error desconocido al obtener facturas (Status: ${response.statusCode}). Body: ${response.body}',
  //       );
  //     }
  //   } on http.ClientException catch (e) {
  //     throw NetworkException("Error de red al obtener facturas: ${e.message}");
  //   } on SocketException catch (e) {
  //     throw NetworkException(
  //       "Error de conexión al obtener facturas: ${e.message}",
  //     );
  //   } on FormatException catch (e) {
  //     throw UnknownApiExpection(
  //       'Error al procesar la respuesta del servidor (facturas - JSON inválido): ${e.message}',
  //     );
  //   } catch (e) {
  //     if (e is SaintApiExceptions) rethrow;
  //     throw UnknownApiExpection(
  //       'Excepción no controlada al obtener facturas: ${e.toString()}',
  //     );
  //   }
  // }
}

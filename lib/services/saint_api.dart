// lib/services/saint_api.dart
import 'dart:convert';
import 'dart:io'; // Para SocketException
import 'package:flutter/material.dart'; // Para debugPrint
import 'package:http/http.dart' as http;
import 'package:saint_bi/models/invoice.dart';
import 'package:saint_bi/models/invoice_parser.dart';
import 'package:saint_bi/models/purchase.dart';
import 'package:saint_bi/models/purchase_parser.dart';
import 'package:saint_bi/services/saint_api_exceptions.dart';
import 'package:saint_bi/models/login_response.dart'; // Asegúrate que este modelo exista

class SaintApi {
  final String apikey = 'B5D31933-C996-476C-B116-EF212A41479A'; // Tu API Key
  final int apiid = 1093; // Tu API ID

  // MODIFICADO: login ahora devuelve LoginResponse? que puede incluir el token y datos de la empresa
  Future<LoginResponse?> login({
    required String baseurl,
    required String username,
    required String password,
    required String terminal,
  }) async {
    final String credentials = '$username:$password';
    final String basicauth = 'Basic ${base64Encode(utf8.encode(credentials))}';
    // La documentación indica que la URL incluye /v1/
    final Uri loginUrl = Uri.parse('$baseurl/v1/main/login');

    debugPrint('Intentando login en: $loginUrl');
    debugPrint(
      'Login Headers: x-api-key: $apikey, x-api-id: $apiid, Authorization: $basicauth',
    );
    debugPrint('Login Body: ${jsonEncode({'terminal': terminal})}');

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

      debugPrint(
        'Respuesta de Login - Status: ${response.statusCode}, Headers: ${response.headers}',
      );
      // debugPrint('Respuesta de Login - Body: ${response.body}');

      if (response.statusCode == 200) {
        final String? authtoken =
            response.headers['pragma']; // El token de sesión está en 'Pragma'
        if (authtoken == null || authtoken.isEmpty) {
          debugPrint('Token Pragma (sesión) nulo o vacío después del login.');
          throw AuthenticationException(
            "Token Pragma nulo o vacío después del login.",
          );
        }

        try {
          final responseBody = utf8.decode(response.bodyBytes);
          final jsonData = jsonDecode(responseBody) as Map<String, dynamic>;

          // Pasar el token al constructor de LoginResponse
          // LoginResponse.fromJson ha sido ajustado para recibir pragmaToken
          final loginData = LoginResponse.fromJson(
            jsonData,
            pragmaToken: authtoken,
          );

          debugPrint(
            'Login exitoso. Token Pragma: ${loginData.authToken}, Empresa desde API: ${loginData.company}',
          );
          return loginData; // Devolver el objeto LoginResponse completo
        } catch (e) {
          debugPrint(
            'Error parseando LoginResponse JSON: $e. Body: ${response.body}',
          );
          throw UnknownApiExpection(
            'Error al procesar la respuesta del servidor (datos de login).',
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint(
          'Error de autenticación en login: ${response.statusCode}. Body: ${response.body}',
        );
        throw AuthenticationException(
          'Credenciales inválidas, API Key/ID incorrecta o acceso denegado (Status: ${response.statusCode}).',
        );
      } else {
        debugPrint(
          'Error desconocido durante el login: ${response.statusCode}, Body: ${response.body}',
        );
        throw UnknownApiExpection(
          'Error desconocido durante el login (Status: ${response.statusCode}).',
        );
      }
    } on http.ClientException catch (e) {
      debugPrint(
        "Error de red durante el login (ClientException): ${e.toString()}",
      );
      throw NetworkException("Error de red durante el login: ${e.message}");
    } on SocketException catch (e) {
      debugPrint(
        "Error de conexión durante el login (SocketException): ${e.toString()}",
      );
      throw NetworkException(
        "Error de conexión durante el login: ${e.message}",
      );
    } catch (e) {
      debugPrint('Excepción no controlada durante el login: ${e.toString()}');
      if (e is SaintApiExceptions) rethrow;
      throw UnknownApiExpection(
        'Excepción no controlada durante el login: ${e.toString()}',
      );
    }
  }

  // loginAndGetToken ya no es necesario si login() devuelve LoginResponse con el token.
  // Se puede eliminar o dejar si se usa en otro contexto. Por ahora lo comentaré.
  /*
  Future<String?> loginAndGetToken({
    required String baseurl,
    required String username,
    required String password,
    required String terminal,
  }) async {
    final LoginResponse? loginResponse = await login(
        baseurl: baseurl,
        username: username,
        password: password,
        terminal: terminal);
    return loginResponse?.authToken;
  }
  */

  Future<List<Purchase>> getPurchases({
    required String baseUrl,
    required String authToken,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/v1/adm/purchases');
    debugPrint('Solicitando compras desde: $uri usando Pragma: $authToken');

    try {
      final response = await http.get(uri, headers: {'pragma': authToken});
      debugPrint('Respuesta de GetPurchases - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = jsonDecode(responseBody);

        if (data.isEmpty) {
          debugPrint('GetPurchases devolvió una lista vacía.');
          return [];
        }

        List<Purchase> purchases = [];
        for (var item in data) {
          try {
            purchases.add(
              PurchaseParser.fromJson(item as Map<String, dynamic>),
            );
          } catch (e) {
            debugPrint('Error al parsear un objeto Purchase: $e. JSON: $item');
          }
        }
        debugPrint(
          'Compras parseadas exitosamente: ${purchases.length} de ${data.length} objetos recibidos.',
        );
        return purchases;
      } else if (response.statusCode == 403) {
        debugPrint(
          'Error de sesión/acceso en GetPurchases (403). Body: ${response.body}',
        );
        throw SessionExpiredException(
          'Sesión expirada o acceso denegado al obtener compras (Status: 403).',
        );
      } else {
        debugPrint(
          'Error desconocido al obtener compras: ${response.statusCode}, Body: ${response.body}',
        );
        throw UnknownApiExpection(
          'Error desconocido al obtener compras (Status: ${response.statusCode}). Body: ${response.body}',
        );
      }
    } on http.ClientException catch (e) {
      debugPrint(
        "Error de red al obtener compras (ClientException): ${e.toString()}",
      );
      throw NetworkException("Error de red al obtener compras: ${e.message}");
    } on SocketException catch (e) {
      debugPrint(
        "Error de conexión al obtener compras (SocketException): ${e.toString()}",
      );
      throw NetworkException(
        "Error de conexión al obtener compras: ${e.message}",
      );
    } on FormatException catch (e) {
      debugPrint(
        'Error al procesar la respuesta del servidor (compras - JSON inválido): ${e.toString()}',
      );
      throw UnknownApiExpection(
        'Error al procesar la respuesta del servidor (compras - JSON inválido): ${e.message}',
      );
    } catch (e) {
      debugPrint('Excepción no controlada en GetPurchases: ${e.toString()}');
      if (e is SaintApiExceptions) rethrow;
      throw UnknownApiExpection(
        'Excepción no controlada al obtener compras: ${e.toString()}',
      );
    }
  }

  Future<List<Invoice>> getInvoices({
    required String baseUrl,
    required String authtoken,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/v1/adm/invoices');
    debugPrint('Solicitando facturas desde: $uri usando Pragma: $authtoken');

    try {
      final response = await http.get(uri, headers: {'pragma': authtoken});

      debugPrint('Respuesta de GetInvoices - Status: ${response.statusCode}');
      // if (response.statusCode == 200) {
      //   debugPrint('GetInvoices Response Body: ${utf8.decode(response.bodyBytes)}');
      // } else {
      //   debugPrint('GetInvoices Error Body: ${response.body}');
      // }

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = jsonDecode(responseBody);

        if (data.isEmpty) {
          debugPrint('GetInvoices devolvió una lista vacía.');
          return [];
        }

        List<Invoice> invoices = [];
        for (var jsonItem in data) {
          try {
            invoices.add(
              InvoiceParser.fromJson(jsonItem as Map<String, dynamic>),
            );
          } catch (e) {
            debugPrint(
              'Error al parsear un objeto Invoice individual. Se omitirá este objeto. JSON: $jsonItem. Error: $e',
            );
          }
        }
        debugPrint(
          'Facturas parseadas exitosamente: ${invoices.length} de ${data.length} objetos recibidos.',
        );
        return invoices;
      } else if (response.statusCode == 403) {
        debugPrint(
          'Error de sesión/acceso en GetInvoices (403). Body: ${response.body}',
        );
        throw SessionExpiredException(
          "Sesión expirada o acceso negado al obtener facturas (Status: 403).",
        );
      } else {
        debugPrint(
          'Error desconocido al obtener facturas: ${response.statusCode}, Body: ${response.body}',
        );
        throw UnknownApiExpection(
          'Error desconocido al obtener facturas (Status: ${response.statusCode}). Body: ${response.body}',
        );
      }
    } on http.ClientException catch (e) {
      debugPrint(
        "Error de red al obtener facturas (ClientException): ${e.toString()}",
      );
      throw NetworkException("Error de red al obtener facturas: ${e.message}");
    } on SocketException catch (e) {
      debugPrint(
        "Error de conexión al obtener facturas (SocketException): ${e.toString()}",
      );
      throw NetworkException(
        "Error de conexión al obtener facturas: ${e.message}",
      );
    } on FormatException catch (e) {
      debugPrint(
        'Error al procesar la respuesta del servidor (facturas - JSON inválido): ${e.toString()}',
      );
      throw UnknownApiExpection(
        'Error al procesar la respuesta del servidor (facturas - JSON inválido): ${e.message}',
      );
    } catch (e) {
      debugPrint('Excepción no controlada en GetInvoices: ${e.toString()}');
      if (e is SaintApiExceptions) rethrow;
      throw UnknownApiExpection(
        'Excepción no controlada al obtener facturas: ${e.toString()}',
      );
    }
  }
}

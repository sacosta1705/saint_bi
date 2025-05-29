import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:saint_bi/models/invoice.dart';
import 'package:saint_bi/models/invoice_parser.dart';
import 'package:saint_bi/services/saint_api_exceptions.dart';

class SaintApi {
  final String apikey = 'B5D31933-C996-476C-B116-EF212A41479A'; //
  final int apiid = 1093; //

  Future<String?> login({
    required String baseurl,
    required String username,
    required String password,
    required String terminal,
  }) async {
    final String credentials = '$username:$password'; //
    final String basicauth =
        'Basic ${base64Encode(utf8.encode(credentials))}'; //
    final Uri loginUrl = Uri.parse('$baseurl/v1/main/login'); //

    debugPrint('Intentando login en: $loginUrl');
    debugPrint(
      'Login Headers: x-api-key: $apikey, x-api-id: $apiid, Authorization: $basicauth',
    );
    debugPrint('Login Body: ${jsonEncode({'terminal': terminal})}');

    try {
      final response = await http.post(
        //
        loginUrl,
        headers: {
          //
          'Content-Type': 'application/json', //
          'Authorization': basicauth, //
          'x-api-key': apikey, //
          'x-api-id': apiid.toString(), //
        },
        body: jsonEncode({'terminal': terminal}), //
      );

      debugPrint(
        'Respuesta de Login - Status: ${response.statusCode}, Headers: ${response.headers}',
      );
      // debugPrint('Respuesta de Login - Body: ${response.body}', name: 'SaintApi.login');

      if (response.statusCode == 200) {
        //
        final authtoken = response.headers['pragma']; //
        if (authtoken != null && authtoken.isNotEmpty) {
          //
          debugPrint('Login exitoso. Token Pragma: $authtoken');
          return authtoken; //
        } else {
          debugPrint('Token Pragma nulo o vacío después del login.');
          throw AuthenticationException(
            //
            "Token Pragma nulo o vacío después del login.",
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        //
        debugPrint(
          'Error de autenticación en login: ${response.statusCode}. Body: ${response.body}',
        );
        throw AuthenticationException(
          //
          'Credenciales inválidas, API Key/ID incorrecta o acceso denegado (Status: ${response.statusCode}).',
        );
      } else {
        debugPrint(
          'Error desconocido durante el login: ${response.statusCode}, Body: ${response.body}',
        );
        throw UnknownApiExpection(
          'Error desconocido durante el login (Status: ${response.statusCode}).',
        ); //
      }
    } on http.ClientException catch (e) {
      //
      debugPrint(
        "Error de red durante el login (ClientException): ${e.toString()}",
      );
      throw NetworkException("Error de red durante el login: ${e.message}"); //
    } on SocketException catch (e) {
      //
      debugPrint(
        "Error de conexión durante el login (SocketException): ${e.toString()}",
      );
      throw NetworkException(
        //
        "Error de conexión durante el login: ${e.message}",
      );
    } catch (e) {
      // Captura cualquier otra cosa, como errores de codificación de base64 si las credenciales son extrañas.
      debugPrint('Excepción no controlada durante el login: ${e.toString()}');
      throw UnknownApiExpection(
        //
        'Excepción no controlada durante el login: ${e.toString()}',
      );
    }
  }

  Future<List<Invoice>> getInvoices({
    required String baseUrl,
    required String authtoken,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/v1/adm/invoices'); //
    debugPrint('Solicitando facturas desde: $uri usando Pragma: $authtoken');

    try {
      final response = await http.get(uri, headers: {'pragma': authtoken}); //

      debugPrint('Respuesta de GetInvoices - Status: ${response.statusCode}');
      // Descomentar para depuración intensiva del cuerpo de la respuesta:
      // if (response.statusCode == 200) {
      //   debugPrint('GetInvoices Response Body: ${utf8.decode(response.bodyBytes)}', name: 'SaintApi.getInvoices.Body');
      // } else {
      //   debugPrint('GetInvoices Error Body: ${response.body}', name: 'SaintApi.getInvoices.ErrorBody');
      // }

      if (response.statusCode == 200) {
        //
        final String responseBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = jsonDecode(responseBody); //

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
            // Loguea el error de parseo para ESTE item, pero continúa con los demás
            debugPrint(
              'Error al parsear un objeto Invoice individual. Se omitirá este objeto. JSON: $jsonItem',
            );
          }
        }
        debugPrint(
          'Facturas parseadas exitosamente: ${invoices.length} de ${data.length} objetos recibidos.',
        );
        return invoices;
      } else if (response.statusCode == 403) {
        //
        debugPrint(
          'Error de sesión/acceso en GetInvoices (403). Body: ${response.body}',
        );
        throw SessionExpiredException(
          "Sesión expirada o acceso negado (Status: 403).",
        ); //
      } else {
        debugPrint(
          'Error desconocido al obtener facturas: ${response.statusCode}, Body: ${response.body}',
        );
        throw UnknownApiExpection(
          //
          'Error desconocido al obtener facturas (Status: ${response.statusCode}).',
        );
      }
    } on http.ClientException catch (e) {
      //
      debugPrint(
        "Error de red al obtener facturas (ClientException): ${e.toString()}",
      );
      throw NetworkException(
        "Error de red al obtener facturas: ${e.message}",
      ); //
    } on SocketException catch (e) {
      //
      debugPrint(
        "Error de conexión al obtener facturas (SocketException): ${e.toString()}",
      );
      throw NetworkException(
        //
        "Error de conexión al obtener facturas: ${e.message}",
      );
    } on FormatException catch (e) {
      // Error de parseo JSON del cuerpo completo de la respuesta
      debugPrint(
        'Error al procesar la respuesta del servidor (FormatException - JSON inválido): ${e.toString()}',
      );
      throw UnknownApiExpection(
        //
        'Error al procesar la respuesta del servidor (JSON inválido): ${e.message}',
      );
    } catch (e) {
      // Cualquier otra excepción no manejada arriba (esto podría incluir errores de Invoice.fromJson si no se manejan internamente allí y se relanzan)
      debugPrint('Excepción no controlada en GetInvoices: ${e.toString()}');
      if (e is SaintApiExceptions) rethrow; //
      throw UnknownApiExpection(
        //
        'Excepción no controlada al obtener facturas: ${e.toString()}',
      );
    }
  }
}

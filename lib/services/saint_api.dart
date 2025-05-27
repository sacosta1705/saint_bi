// lib/services/saint_api.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:saint_bi/models/invoice.dart';
import 'package:saint_bi/services/saint_api_exceptions.dart';

class SaintApi {
  final String apikey = 'B5D31933-C996-476C-B116-EF212A41479A';
  final int apiid = 1093;

  Future<String?> login({
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
        final authtoken = response.headers['pragma'];
        if (authtoken != null && authtoken.isNotEmpty) {
          return authtoken;
        } else {
          throw AuthenticationException(
            "Token Pragma nulo o vacío después del login.",
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthenticationException(
          'Credenciales inválidas, API Key/ID incorrecta o acceso denegado.',
        );
      } else {
        throw UnknownApiExpection('Error desconocido durante el login.');
      }
    } on http.ClientException catch (e) {
      throw NetworkException("Error de red durante el login: ${e.toString()}");
    } on SocketException catch (e) {
      throw NetworkException(
        "Error de conexión durante el login: ${e.toString()}",
      );
    } catch (e) {
      throw UnknownApiExpection(
        'Excepción no controlada durante el login: ${e.toString()}',
      );
    }
  }

  Future<List<Invoice>> getInvoices({
    required String baseUrl,
    required String authtoken,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/v1/adm/invoices');

    try {
      final response = await http.get(uri, headers: {'pragma': authtoken});

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((jsonItem) => Invoice.fromJson(jsonItem)).toList();
      } else if (response.statusCode == 403) {
        throw SessionExpiredException("Sesión expirada o acceso negado.");
      } else {
        throw UnknownApiExpection(
          'Error desconocido al obtener facturas (${response.statusCode}).',
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(
        "Error de red al obtener facturas: ${e.toString()}",
      );
    } on SocketException catch (e) {
      throw NetworkException(
        "Error de conexión al obtener facturas: ${e.toString()}",
      );
    } on FormatException catch (e) {
      throw UnknownApiExpection(
        'Error al procesar la respuesta del servidor (JSON inválido): ${e.toString()}',
      );
    } catch (e) {
      if (e is SaintApiExceptions) rethrow;
      throw UnknownApiExpection(
        'Excepción no controlada al obtener facturas: ${e.toString()}',
      );
    }
  }
}

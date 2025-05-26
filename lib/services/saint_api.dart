import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

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

    developer.log('Attempting login...', name: 'SaintApi.login');
    developer.log('URL: ${loginUrl.toString()}', name: 'SaintApi.login');
    developer.log('Method: POST', name: 'SaintApi.login');
    developer.log('Headers: {', name: 'SaintApi.login');
    developer.log('  Content-Type: application/json', name: 'SaintApi.login');
    developer.log('  Authorization: $basicauth', name: 'SaintApi.login');
    developer.log('  x-api-key: $apikey', name: 'SaintApi.login');
    developer.log('  x-api-id: ${apiid.toString()}', name: 'SaintApi.login');
    developer.log('}', name: 'SaintApi.login');
    developer.log(
      'Body: ${jsonEncode({'terminal': terminal})}',
      name: 'SaintApi.login',
    );

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

      developer.log(
        'Login Response Status Code: ${response.statusCode}',
        name: 'SaintApi.login',
      );
      developer.log(
        'Login Response Headers: ${response.headers}',
        name: 'SaintApi.login',
      );
      developer.log(
        'Login Response Body: ${response.body}',
        name: 'SaintApi.login',
      );

      if (response.statusCode == 200) {
        final authtoken = response.headers['pragma'];
        if (authtoken != null && authtoken.isNotEmpty) {
          developer.log(
            'Login successful. Pragma token: $authtoken',
            name: 'SaintApi.login',
          );
          return authtoken;
        } else {
          developer.log(
            'Login successful, but Pragma token is missing or empty.',
            name: 'SaintApi.login',
            error: "Pragma token nulo o vacío",
          );
          debugPrint('Status code (int): ${response.statusCode}');
          debugPrint('Response body for missing pragma: ${response.body}');
          return null;
        }
      } else {
        developer.log(
          'Login failed. Status Code: ${response.statusCode}',
          name: 'SaintApi.login',
          error: response.body,
        );
        return null;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Exception during login',
        name: 'SaintApi.login',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<int?> getInvoiceCount({
    required String baseUrl,
    required String authtoken,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/v1/adm/invoices');

    developer.log(
      'Attempting to get invoice count...',
      name: 'SaintApi.getInvoiceCount',
    );
    developer.log('URL: ${uri.toString()}', name: 'SaintApi.getInvoiceCount');
    developer.log('Method: GET', name: 'SaintApi.getInvoiceCount');
    developer.log(
      'Headers: { pragma: $authtoken }',
      name: 'SaintApi.getInvoiceCount',
    );

    try {
      final response = await http.get(uri, headers: {'pragma': authtoken});

      developer.log(
        'GetInvoiceCount Response Status Code: ${response.statusCode}',
        name: 'SaintApi.getInvoiceCount',
      );
      developer.log(
        'GetInvoiceCount Response Body: ${response.body}',
        name: 'SaintApi.getInvoiceCount',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        developer.log(
          'Invoice count received: ${data.length}',
          name: 'SaintApi.getInvoiceCount',
        );
        return data.length;
      } else {
        developer.log(
          'Failed to get invoice count. Status Code: ${response.statusCode}',
          name: 'SaintApi.getInvoiceCount',
          error: response.body,
        );
        if (response.statusCode == 403) {
          developer.log(
            'Error 403: Sesion vencida.',
            name: 'SaintApi.getInvoiceCount',
          );
          throw Exception('Sesion expirada.');
        }
        return null;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Exception during getInvoiceCount',
        name: 'SaintApi.getInvoiceCount',
        error: e,
        stackTrace: stackTrace,
      );
      if (e.toString().contains('Sesion expirada.')) {
        rethrow;
      }
      return null;
    }
  }
}

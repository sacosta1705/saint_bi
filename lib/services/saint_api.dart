import 'dart:convert';
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
          debugPrint(response.statusCode as String?);
          debugPrint(response.body);
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<int?> getInvoiceCount({
    required String baseUrl,
    required String authtoken,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/v1/adm/invoices');

    try {
      final response = await http.get(uri, headers: {'pragma': authtoken});

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.length;
      } else {
        if (response.statusCode == 403) {
          throw Exception('Sesion expirada.');
        }
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}

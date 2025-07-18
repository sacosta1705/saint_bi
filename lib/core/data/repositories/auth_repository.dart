import 'package:saint_bi/core/data/sources/remote/saint_api.dart';
import 'package:saint_bi/core/data/models/login_response.dart';

class AuthRepository {
  final SaintApi _saintApiClient;

  AuthRepository({required SaintApi saintApiClient})
    : _saintApiClient = saintApiClient;

  Future<LoginResponse?> login({
    required String baseUrl,
    required String username,
    required String password,
    required String terminal,
  }) {
    return _saintApiClient.login(
      baseurl: baseUrl,
      username: username,
      password: password,
      terminal: terminal,
    );
  }
}

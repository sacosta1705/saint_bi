// lib/models/login_response.dart
class LoginResponse {
  final String username; // API: "user"
  final String firstname; // API: "firstname"
  final String lastname; // API: "lastname"
  final String userrole; // API: "role"
  final String company; // API: "enterprise"
  final String? authToken; // NUEVO: Opcional para guardar el token Pragma

  LoginResponse({
    required this.username,
    required this.firstname,
    required this.lastname,
    required this.userrole,
    required this.company,
    this.authToken, // NUEVO
  });

  factory LoginResponse.fromJson(
    Map<String, dynamic> json, {
    String? pragmaToken,
  }) {
    return LoginResponse(
      username: json['user'] ?? '', // Ajustado a "user"
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      userrole: json['role'] ?? '', // Ajustado a "role"
      company: json['enterprise'] ?? '', // Ajustado a "enterprise"
      authToken: pragmaToken, // NUEVO: Asignar el token
    );
  }

  // Método para copiar con nuevas propiedades (útil)
  LoginResponse copyWith({
    String? username,
    String? firstname,
    String? lastname,
    String? userrole,
    String? company,
    String? authToken,
  }) {
    return LoginResponse(
      username: username ?? this.username,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      userrole: userrole ?? this.userrole,
      company: company ?? this.company,
      authToken: authToken ?? this.authToken,
    );
  }
}

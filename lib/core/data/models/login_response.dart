/// Representa la data devuelta en el cuerpo de la respuesta del servidor.
///
/// Ademas de poseer los datos de la base de datos a la cual se inicio sesion
/// tiene tambien el token Pragma para la autenticacion de proximas solicitudes.
///
class LoginResponse {
  /// Usuario de acceso a la cual se inicio sesion exitosamente
  final String username;

  /// Primer nombre del usuario que inicio sesion exitosamente
  final String firstname;

  /// Apellido del usuario que inicio sesion exitosamente
  final String lastname;

  /// Rol del usuario que inicio sesion exitosamente
  final String userrole;

  /// Razon social de la licencia que tiene activada la sucusal a la que se
  /// inicio sesion exitosamente.
  final String company;

  /// Token de autenticacion devuelto en la cabecera de la respuesta del servidor
  /// bajo el nombre `Pragma`.
  ///
  /// Este token debe ser enviado en la cabecera `pragma` al enviar la solicitud
  /// a cualquier otro servicio.
  final String? authToken;

  /// Constructor de la clase, crea una nueva instancia de [LoginResponse]
  LoginResponse({
    required this.username,
    required this.firstname,
    required this.lastname,
    required this.userrole,
    required this.company,
    this.authToken,
  });

  /// Crea una instancia de [LoginResponse] a partir de un JSON.
  ///
  /// Recibe los datos a convertir en formato Map y devuelve un JSON equivalente.
  factory LoginResponse.fromJson(
    Map<String, dynamic> json, {
    String? pragmaToken,
  }) {
    return LoginResponse(
      username: json['user']?.toString() ?? '', // Ajustado a "user"
      firstname: json['firstname']?.toString() ?? '',
      lastname: json['lastname']?.toString() ?? '',
      userrole: json['role']?.toString() ?? '', // Ajustado a "role"
      company: json['enterprise']?.toString() ?? '', // Ajustado a "enterprise"
      authToken: pragmaToken?.toString() ?? '', // NUEVO: Asignar el token
    );
  }

  /// Crea una nueva copia de [LoginResponse] con propiedades actualizadas.
  ///
  /// El metodo es util para crear nuevas instancias con valores modificados,
  /// lo cual es comun al momento de gestionar estados.
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

class LoginResponse {
  final String username; // Usuario que inicio sesion
  final String firstname; // Primer nombre del usuario que inicio sesion
  final String lastname; // Apellido del usuario que inicio sesion
  final String userrole; // Rol del usuario que inicio sesion
  final String company; // Nombre de la compañia a la que se inicio sesion

  LoginResponse({
    required this.username,
    required this.firstname,
    required this.lastname,
    required this.userrole,
    required this.company,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      username: json['username'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      userrole: json['userrole'],
      company: json['company'],
    );
  }
}

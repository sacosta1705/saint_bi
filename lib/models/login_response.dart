class LoginResponse {
  final String username;
  final String firstname;
  final String lastname;
  final String userrole;
  final String company;

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

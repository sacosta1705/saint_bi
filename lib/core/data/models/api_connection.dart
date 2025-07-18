import 'package:saint_bi/core/data/models/permissions.dart';

/// Representa la configuración completa para una conexión a la API. 🔌
///
/// Esta clase almacena todos los datos necesarios para establecer
/// y gestionar una conexión con un endpoint específico, incluyendo credenciales,
/// información de la empresa y ajustes de conexión como el intervalo de sondeo.
///
class ApiConnection {
  /// El identificador único de la conexión en la base de datos local.
  ///
  /// Puede ser nulo si la conexión aún no ha sido guardada.
  final int? id;

  /// La URL base del servidor de la API a la que se conectará.
  final String baseUrl;

  /// El nombre de usuario para la autenticación en la API.
  final String username;

  /// La contraseña para la autenticación en la API.
  final String password;

  /// El intervalo en segundos para realizar consultas periódicas a la API.
  final int pollingIntervalSeconds;

  /// El nombre completo de la empresa asociada a esta conexión.
  final String companyName;

  /// Un alias corto o identificador para la empresa.
  final String companyAlias;

  /// Un identificador para el terminal o cliente que realiza la conexión.
  ///
  /// Por defecto es `'saint_bi'`.
  final String terminal;

  /// Los permisos asociados al usuario de esta conexión.
  ///
  /// Define qué acciones puede realizar el usuario. Ver [Permissions].
  final Permissions permissions;

  /// El id de la configuracion a la que se conecta la instancia del servidor web
  /// configurado en la aplicacion
  final int configId;

  /// Crea una nueva instancia de configuración de conexión a la API.
  const ApiConnection({
    this.id,
    required this.companyAlias,
    required this.baseUrl,
    required this.username,
    required this.password,
    required this.pollingIntervalSeconds,
    required this.companyName,
    this.terminal = 'saint_bi',
    required this.permissions,
    required this.configId,
  });

  /// Convierte la instancia de [ApiConnection] a un mapa.
  ///
  /// Es útil para serializar el objeto, por ejemplo, para guardarlo en una
  /// base de datos local.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'baseUrl': baseUrl,
      'username': username,
      'password': password,
      'pollingIntervalSeconds': pollingIntervalSeconds,
      'companyName': companyName,
      'companyAlias': companyAlias,
      'terminal': terminal,
      'permissions': permissions.toJson(),
      'configId': configId,
    };
  }

  /// Crea una instancia de [ApiConnection] a partir de un mapa.
  ///
  /// Este constructor de fábrica es el inverso de [toMap] y se usa para
  /// deserializar un objeto desde una fuente como una base de datos.
  factory ApiConnection.fromMap(Map<String, dynamic> map) {
    return ApiConnection(
      id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
      baseUrl: map['baseUrl']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      pollingIntervalSeconds:
          int.tryParse(map['pollingIntervalSeconds']?.toString() ?? '') ?? 60,
      companyName: map['companyName']?.toString() ?? '',
      companyAlias: map['companyAlias']?.toString() ?? '',
      terminal: map['terminal']?.toString() ?? 'saint_bi',
      permissions: map['permissions'] != null
          ? Permissions.fromJson(map['permissions'])
          : Permissions(),
      configId: int.tryParse(map['configId']?.toString() ?? '1') ?? 1,
    );
  }

  /// Crea una copia de esta instancia de [ApiConnection] con algunas propiedades modificadas.
  ///
  /// Dado que [ApiConnection] es inmutable, este método es la forma
  /// recomendada de crear una versión actualizada del objeto.
  ApiConnection copyWith({
    int? id,
    String? baseUrl,
    String? username,
    String? password,
    int? pollingIntervalSeconds,
    String? companyName,
    String? companyAlias,
    String? terminal,
    Permissions? permissions,
    int? configId,
  }) {
    return ApiConnection(
      id: id ?? this.id,
      baseUrl: baseUrl ?? this.baseUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      pollingIntervalSeconds:
          pollingIntervalSeconds ?? this.pollingIntervalSeconds,
      companyName: companyName ?? this.companyName,
      companyAlias: companyAlias ?? this.companyAlias,
      terminal: terminal ?? this.terminal,
      permissions: permissions ?? this.permissions,
      configId: configId ?? this.configId,
    );
  }

  /// Devuelve una representación en `String` del objeto para depuración.
  @override
  String toString() {
    return '''ApiConnection(
              id: $id, 
              companyName: $companyName, 
              baseUrl: $baseUrl, 
              username: $username, 
              pollingInterval: $pollingIntervalSeconds, 
              terminal: $terminal
            )''';
  }

  /// Sobrescribe el operador de igualdad para comparar instancias por valor.
  ///
  /// Dos instancias de [ApiConnection] se consideran iguales si todas sus
  /// propiedades son idénticas.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiConnection &&
        other.id == id &&
        other.baseUrl == baseUrl &&
        other.username == username &&
        other.password == password &&
        other.pollingIntervalSeconds == pollingIntervalSeconds &&
        other.companyName == companyName &&
        other.companyAlias == companyAlias &&
        other.terminal == terminal &&
        other.configId == configId;
  }

  /// Sobrescribe el `hashCode` para mantener la consistencia con [operator ==].
  @override
  int get hashCode {
    return id.hashCode ^
        baseUrl.hashCode ^
        username.hashCode ^
        password.hashCode ^
        pollingIntervalSeconds.hashCode ^
        companyName.hashCode ^
        companyAlias.hashCode ^
        terminal.hashCode ^
        configId.hashCode;
  }
}

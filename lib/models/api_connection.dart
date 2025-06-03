import 'package:flutter/foundation.dart';

@immutable
class ApiConnection {
  final int? id;
  final String baseUrl;
  final String username;
  final String password;
  final int pollingIntervalSeconds;
  final String companyName;
  final String terminal;

  const ApiConnection({
    this.id,
    required this.baseUrl,
    required this.username,
    required this.password,
    required this.pollingIntervalSeconds,
    required this.companyName,
    this.terminal = 'saint_bi',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'baseUrl': baseUrl,
      'username': username,
      'password': password,
      'pollingIntervalSeconds': pollingIntervalSeconds,
      'companyName': companyName,
      'terminal': terminal,
    };
  }

  factory ApiConnection.fromMap(Map<String, dynamic> map) {
    return ApiConnection(
      id: map['id'] as int?,
      baseUrl: map['baseUrl'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
      pollingIntervalSeconds: map['pollingIntervalSeconds'] as int,
      companyName: map['companyName'] as String,
      terminal: map['terminal'] as String? ?? 'saint_bi',
    );
  }

  ApiConnection copyWith({
    int? id,
    String? baseUrl,
    String? username,
    String? password,
    int? pollingIntervalSeconds,
    String? companyName,
    String? terminal,
  }) {
    return ApiConnection(
      id: id ?? this.id,
      baseUrl: baseUrl ?? this.baseUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      pollingIntervalSeconds:
          pollingIntervalSeconds ?? this.pollingIntervalSeconds,
      companyName: companyName ?? this.companyName,
      terminal: terminal ?? this.terminal,
    );
  }

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
        other.terminal == terminal;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        baseUrl.hashCode ^
        username.hashCode ^
        password.hashCode ^
        pollingIntervalSeconds.hashCode ^
        companyName.hashCode ^
        terminal.hashCode;
  }
}

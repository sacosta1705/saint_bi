class SaintApiExceptions implements Exception {
  final String msg;
  SaintApiExceptions(this.msg);

  @override
  String toString() => msg;
}

class SessionExpiredException extends SaintApiExceptions {
  SessionExpiredException(super.msg);
}

class AuthenticationException extends SaintApiExceptions {
  AuthenticationException(super.msg);
}

class NetworkException extends SaintApiExceptions {
  NetworkException(super.msg);
}

class UnknownApiExpection extends SaintApiExceptions {
  UnknownApiExpection(super.msg);
}

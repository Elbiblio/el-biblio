class AppException implements Exception {
  AppException(this.message, this.code, [this.details]);

  final String message;
  final String code;
  final dynamic details;

  @override
  String toString() =>
      'AppException(code: $code, message: $message, details: $details)';
}

class NetworkException extends AppException {
  NetworkException(String message, [dynamic details])
    : super(message, 'network_error', details);
}

class ApiRequestException extends NetworkException {
  ApiRequestException({
    required this.statusCode,
    required String message,
    dynamic details,
  }) : super(message, details);

  final int statusCode;

  @override
  String toString() =>
      'ApiRequestException(statusCode: $statusCode, message: $message, details: $details)';
}

class StorageException extends AppException {
  StorageException(String message, [dynamic details])
    : super(message, 'storage_error', details);
}

class ValidationException extends AppException {
  ValidationException(String message, [dynamic details])
    : super(message, 'validation_error', details);
}

class GuestUserException extends AppException {
  GuestUserException(String message, [dynamic details])
    : super(message, 'guest_user_error', details);
}

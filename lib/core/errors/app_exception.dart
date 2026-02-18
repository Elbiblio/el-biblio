class AppException implements Exception {
  AppException(this.message, this.code, [this.details]);

  final String message;
  final String code;
  final dynamic details;

  @override
  String toString() => 'AppException(code: $code, message: $message, details: $details)';
}

class NetworkException extends AppException {
  NetworkException(String message, [dynamic details])
      : super(message, 'network_error', details);
}

class StorageException extends AppException {
  StorageException(String message, [dynamic details])
      : super(message, 'storage_error', details);
}

class ValidationException extends AppException {
  ValidationException(String message, [dynamic details])
      : super(message, 'validation_error', details);
}

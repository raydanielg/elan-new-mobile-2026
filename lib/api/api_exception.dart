class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final String? statusCode;
  final Object? details;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' ($statusCode)';
    return 'ApiException$code: $message';
  }
}

class TimeoutException implements Exception {
  TimeoutException(this.message);

  final String message;

  @override
  String toString() => 'TimeoutException: $message';
}

class ApiResult<T> {
  const ApiResult._({
    required this.ok,
    this.data,
    this.message,
    this.error,
  });

  final bool ok;
  final T? data;
  final String? message;
  final Object? error;

  factory ApiResult.success(T data, {String? message}) {
    return ApiResult._(ok: true, data: data, message: message);
  }

  factory ApiResult.failure({String? message, Object? error}) {
    return ApiResult._(ok: false, message: message, error: error);
  }
}

class ApiResponse<T> {
  const ApiResponse({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
    required this.raw,
  });

  final bool status;
  final String? statusCode;
  final String? message;
  final T? data;
  final Map<String, dynamic> raw;

  static ApiResponse<Map<String, dynamic>> fromJson(
    Map<String, dynamic> json,
  ) {
    final rawStatus = json['status'];
    final normalizedStatus = rawStatus is String
        ? rawStatus.trim().toLowerCase()
        : rawStatus;
    final isSuccess = normalizedStatus == true ||
        normalizedStatus == 'true' ||
        normalizedStatus == 'success' ||
        normalizedStatus == 'ok' ||
        normalizedStatus == '000';

    return ApiResponse<Map<String, dynamic>>(
      status: isSuccess,
      statusCode: json['statusCode']?.toString(),
      message: json['message']?.toString(),
      data: json,
      raw: json,
    );
  }
}

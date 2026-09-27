class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final String? requestId;

  ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.requestId,
  });

  factory ApiException.fromJson(int statusCode, Map<String, dynamic> json) {
    final error = json['error'] as Map<String, dynamic>?;
    if (error != null) {
      return ApiException(
        statusCode: statusCode,
        code: error['code'] as String? ?? 'UNKNOWN_ERROR',
        message: error['message'] as String? ?? 'An unknown error occurred.',
        requestId: error['request_id'] as String?,
      );
    }
    return ApiException(
      statusCode: statusCode,
      code: 'UNKNOWN_ERROR',
      message: 'An unknown error occurred.',
    );
  }

  @override
  String toString() {
    return 'ApiException(statusCode: $statusCode, code: $code, message: $message, requestId: $requestId)';
  }
}

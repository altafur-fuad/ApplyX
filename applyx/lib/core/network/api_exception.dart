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
    // 1. Existing custom error envelope
    final error = json['error'] as Map<String, dynamic>?;
    if (error != null) {
      return ApiException(
        statusCode: statusCode,
        code: error['code'] as String? ?? 'UNKNOWN_ERROR',
        message: error['message'] as String? ?? 'An unknown error occurred.',
        requestId: error['request_id'] as String?,
      );
    }

    // 2. FastAPI default detail format
    final detail = json['detail'];
    if (detail != null) {
      if (detail is String) {
        return ApiException(
          statusCode: statusCode,
          code: 'HTTP_ERROR',
          message: detail,
        );
      } else if (detail is List && detail.isNotEmpty) {
        try {
          final firstError = detail.first as Map<String, dynamic>;
          final msg = firstError['msg'] as String? ?? 'Validation error';
          final loc = (firstError['loc'] as List?)?.join('.') ?? '';
          return ApiException(
            statusCode: statusCode,
            code: 'VALIDATION_ERROR',
            message: loc.isNotEmpty ? '$msg at $loc' : msg,
          );
        } catch (_) {}
      }
    }

    // 3. Fallback
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

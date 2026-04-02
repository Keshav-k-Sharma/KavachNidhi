import 'dart:convert';

/// Parses JSON body shaped like FastAPI `{ success, data, error }`.
class ApiEnvelope<T> {
  const ApiEnvelope({
    required this.success,
    this.data,
    this.error,
  });

  final bool success;
  final T? data;
  final String? error;

  static ApiEnvelope<Map<String, dynamic>> fromJsonMap(String body) {
    final Object? decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return const ApiEnvelope<Map<String, dynamic>>(
        success: false,
        error: 'Invalid JSON response',
      );
    }
    final bool success = decoded['success'] as bool? ?? false;
    final Object? rawData = decoded['data'];
    final Map<String, dynamic>? data = rawData is Map<String, dynamic>
        ? rawData
        : null;
    final String? error = decoded['error'] as String?;
    return ApiEnvelope<Map<String, dynamic>>(
      success: success,
      data: data,
      error: error,
    );
  }
}

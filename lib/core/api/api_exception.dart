import 'package:dio/dio.dart';

/// A friendly, typed error surfaced to the UI.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;

  /// Map a DioException into a human-readable [ApiException].
  factory ApiException.fromDio(DioException e) {
    final code = e.response?.statusCode;

    // Backend returns {"detail": "..."} on errors.
    final data = e.response?.data;
    String? detail;
    if (data is Map && data['detail'] != null) {
      detail = data['detail'].toString();
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('The server took too long to respond.');
      case DioExceptionType.connectionError:
        return const ApiException(
          'Cannot reach the server. Check your connection.',
        );
      default:
        if (code == 401) {
          return ApiException(detail ?? 'Session expired. Please log in again.',
              statusCode: 401);
        }
        if (code == 404) {
          return ApiException(detail ?? 'Not found.', statusCode: 404);
        }
        return ApiException(
          detail ?? 'Something went wrong. Please try again.',
          statusCode: code,
        );
    }
  }
}

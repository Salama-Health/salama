import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Thin Dio wrapper: base URL, JWT auth header, and automatic token refresh.
class ApiClient {
  ApiClient({required TokenStorage storage, this.onAuthFailure})
      : _storage = storage {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(_authInterceptor());
  }

  late final Dio _dio;
  final TokenStorage _storage;

  /// Called when refresh fails and the user must re-authenticate.
  final Future<void> Function()? onAuthFailure;

  Dio get raw => _dio;

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.extra['skipAuth'] != true) {
          final token = await _storage.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        // Only login and refresh are non-refreshable. /auth/me must be
        // retried after a refresh, or an expired access token signs the
        // worker out at startup even though the refresh token is still good.
        final path = e.requestOptions.path;
        final isAuthCall =
            path.contains('/auth/login') || path.contains('/auth/refresh');
        if (e.response?.statusCode == 401 &&
            !isAuthCall &&
            e.requestOptions.extra['retried'] != true) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            try {
              final opts = e.requestOptions;
              opts.extra['retried'] = true;
              final token = await _storage.accessToken;
              opts.headers['Authorization'] = 'Bearer $token';
              final clone = await _dio.fetch(opts);
              return handler.resolve(clone);
            } catch (_) {
              // fall through to failure
            }
          }
          await onAuthFailure?.call();
        }
        handler.next(e);
      },
    );
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _storage.refreshToken;
    if (refresh == null) return false;
    try {
      final resp = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refresh},
        options: Options(extra: {'skipAuth': true}),
      );
      final newAccess = resp.data['accessToken'] as String?;
      if (newAccess == null) return false;
      await _storage.saveAccess(newAccess);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Verb helpers (throw ApiException) ──────────────────────────────────────
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _wrap(() => _dio.get<T>(path, queryParameters: query));

  Future<Response<T>> post<T>(String path,
          {Object? data, Map<String, dynamic>? query, Options? options}) =>
      _wrap(() => _dio.post<T>(path,
          data: data, queryParameters: query, options: options));

  Future<Response<T>> patch<T>(String path, {Object? data}) =>
      _wrap(() => _dio.patch<T>(path, data: data));

  Future<Response<T>> _wrap<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

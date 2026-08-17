import 'dart:async';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

/// Thin wrapper around a configured [Dio] instance.
///
/// Handles: bearer auth injection, transparent access-token refresh on
/// `401 TOKEN_EXPIRED` (single-flight so concurrent requests share one
/// refresh call), and translation of every failure into an [ApiException].
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiBaseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        contentType: 'application/json',
      ),
    );
    _dio.interceptors.add(_AuthInterceptor(this));
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;
  Dio get dio => _dio;

  /// Called by [AuthProvider] once a manual login/register succeeds so
  /// unauthenticated 401s (e.g. wrong password) never trigger a refresh loop.
  void Function()? onSessionExpired;

  Completer<bool>? _refreshCompleter;

  Future<bool> refreshSession() async {
    if (_refreshCompleter != null) return _refreshCompleter!.future;
    final completer = Completer<bool>();
    _refreshCompleter = completer;
    try {
      final refreshToken = await SecureStorageService.instance.refreshToken;
      if (refreshToken == null) {
        completer.complete(false);
        return false;
      }
      final response = await Dio(BaseOptions(baseUrl: ApiConfig.apiBaseUrl)).post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      await SecureStorageService.instance.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      completer.complete(true);
      return true;
    } catch (_) {
      await SecureStorageService.instance.clear();
      onSessionExpired?.call();
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _guard(() => _dio.get(path, queryParameters: query));

  Future<Response<dynamic>> post(String path, {dynamic data}) =>
      _guard(() => _dio.post(path, data: data));

  Future<Response<dynamic>> patch(String path, {dynamic data}) =>
      _guard(() => _dio.patch(path, data: data));

  Future<Response<dynamic>> delete(String path) => _guard(() => _dio.delete(path));

  Future<Response<dynamic>> postForm(String path, FormData formData) =>
      _guard(() => _dio.post(path, data: formData));

  Future<Response<dynamic>> _guard(Future<Response<dynamic>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw ApiException.network();
      }
      throw ApiException.fromResponse(e.response?.statusCode, e.response?.data);
    }
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._client);
  final ApiClient _client;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorageService.instance.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final isTokenExpired = response?.statusCode == 401 &&
        (response?.data is Map) &&
        ((response!.data as Map)['error']?['code'] == 'TOKEN_EXPIRED');

    if (isTokenExpired) {
      final refreshed = await _client.refreshSession();
      if (refreshed) {
        try {
          final retryResponse = await _client.dio.fetch(err.requestOptions);
          handler.resolve(retryResponse);
          return;
        } on DioException catch (retryError) {
          handler.next(retryError);
          return;
        }
      }
    }
    handler.next(err);
  }
}

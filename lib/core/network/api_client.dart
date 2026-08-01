import 'dart:async';

import 'package:dio/dio.dart';

import 'api_error_mapper.dart';
import 'api_logger.dart';
import 'exceptions.dart';
import 'internet_checker.dart';

/// A reusable HTTP client that wraps [Dio] with production-grade
/// cross-cutting concerns:
///
/// * **Timeouts** – sensible connect/receive defaults.
/// * **Retry** – transparent exponential-backoff retry on transient
///   failures (timeout, connection error, 5xx). Capped so we never
///   hang the UI.
/// * **Logging** – every request/response is logged through [ApiLogger].
/// * **Exception mapping** – [DioException]s are translated into our
///   own [NetworkException] hierarchy, so consumers never have to
///   import `package:dio`.
/// * **Internet checking** – every request pre-checks connectivity so
///   the user gets a fast "no internet" message instead of waiting for
///   a 30-second connect timeout.
///
/// Feature code should NEVER construct a [Dio] instance directly —
/// always depend on [ApiClient] (typically via a Riverpod provider).
class ApiClient {
  ApiClient({
    Dio? dio,
    ApiLogger? logger,
    InternetChecker? internetChecker,
    ApiErrorMapper? errorMapper,
    Duration connectTimeout = const Duration(seconds: 20),
    Duration receiveTimeout = const Duration(seconds: 20),
    int maxRetries = 2,
  })  : _dio = dio ?? Dio(),
        _logger = logger ?? ApiLogger(),
        _internetChecker = internetChecker ?? InternetChecker(),
        _errorMapper = errorMapper ?? const ApiErrorMapper(),
        _maxRetries = maxRetries {
    _dio.options
      ..connectTimeout = connectTimeout
      ..receiveTimeout = receiveTimeout
      ..sendTimeout = connectTimeout
      ..headers = {
        'Accept': 'application/json',
      };
    _dio.interceptors.add(_logger);
    // The BD Apps endpoints expect an
    // `application/x-www-form-urlencoded` body. The data layer
    // wraps payloads in `FormData.fromMap(...)` to trigger that
    // encoding — see `subscription_remote_datasource.dart`.
  }

  final Dio _dio;
  final ApiLogger _logger;
  final InternetChecker _internetChecker;
  final ApiErrorMapper _errorMapper;
  final int _maxRetries;

  /// Public read-only handle for tests that need to assert on the
  /// underlying [Dio] (e.g. adapter overrides).
  Dio get raw => _dio;

  // ─── Public HTTP verbs ──────────────────────────────────────────

  Future<Response<dynamic>> get(
    String url, {
    Map<String, String>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _send(() => _dio.get<dynamic>(
          url,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        ));
  }

  Future<Response<dynamic>> post(
    String url, {
    Object? data,
    Map<String, String>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _send(() => _dio.post<dynamic>(
          url,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        ));
  }

  Future<Response<dynamic>> put(
    String url, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _send(() => _dio.put<dynamic>(
          url,
          data: data,
          options: options,
          cancelToken: cancelToken,
        ));
  }

  Future<Response<dynamic>> delete(
    String url, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _send(() => _dio.delete<dynamic>(
          url,
          data: data,
          options: options,
          cancelToken: cancelToken,
        ));
  }

  // ─── Retry / connectivity plumbing ──────────────────────────────

  Future<Response<dynamic>> _send(
    Future<Response<dynamic>> Function() runner,
  ) async {
    if (!await _internetChecker.isOnline()) {
      throw const NoInternetException();
    }

    Object? lastError;
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        return await runner();
      } on DioException catch (e) {
        lastError = e;
        if (!_isRetryable(e) || attempt == _maxRetries) {
          throw _errorMapper.map(e);
        }
        // Exponential backoff: 400ms, 800ms, 1600ms…
        final delayMs = 400 * (1 << attempt);
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      }
    }
    // Unreachable, but keeps the analyzer happy.
    throw UnknownNetworkException(
      lastError?.toString() ?? 'Unknown network failure',
    );
  }

  /// Whether a particular [DioException] is worth retrying. We do NOT
  /// retry on 4xx (the server is telling us our request is wrong) or
  /// cancellation (the user wanted to stop).
  bool _isRetryable(DioException e) {
    if (e.type == DioExceptionType.cancel) return false;
    if (e.type == DioExceptionType.badResponse) {
      final code = e.response?.statusCode ?? 0;
      return code >= 500 && code < 600;
    }
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError;
  }
}

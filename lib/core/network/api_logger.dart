import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Logs every Dio request/response pair with a uniform shape so
/// debugging in the console (or via `flutter logs`) is predictable.
///
/// Logging is best-effort — it never throws out of an interceptor.
class ApiLogger extends Interceptor {
  ApiLogger({this.enabled = true});

  /// Toggle to silence logging in release builds.
  final bool enabled;

  static const _tag = 'Api';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!enabled) return handler.next(options);
    developer.log(
      '→ ${options.method} ${options.uri}',
      name: _tag,
    );
    if (options.data != null) {
      developer.log(
        '  body: ${_truncate(options.data.toString())}',
        name: _tag,
      );
    }
    // Surface the content-type so we can verify that the
    // urlencoded body is actually being sent over the wire.
    final ct = options.headers['Content-Type'] ?? options.contentType;
    if (ct != null) {
      developer.log('  content-type: $ct', name: _tag);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!enabled) return handler.next(response);
    developer.log(
      '← ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.uri}',
      name: _tag,
    );
    final body = response.data?.toString();
    if (body != null && body.isNotEmpty) {
      developer.log(
        '  body: ${_truncate(body)}',
        name: _tag,
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!enabled) return handler.next(err);
    developer.log(
      '✗ ${err.requestOptions.method} ${err.requestOptions.uri} '
      '[${err.type.name}] ${err.message ?? ''}',
      name: _tag,
      error: err,
    );
    handler.next(err);
  }

  /// Keeps the log lines readable — some endpoints return multi-KB
  /// payloads that drown out the signal.
  static String _truncate(String s, [int max = 800]) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}… (+${s.length - max} chars)';
  }
}

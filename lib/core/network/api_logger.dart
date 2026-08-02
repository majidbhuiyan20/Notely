import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs every Dio request/response pair with a uniform shape so
/// debugging in the console (or via `flutter logs`) is predictable.
///
/// Logging is best-effort — it never throws out of an interceptor.
///
/// ## Sensitive-data handling
/// The BDApps subscription endpoints accept `otp`, `referenceNo`,
/// and `subscriberId` fields. We **never** echo these back to logs
/// because the logs are visible in Crashlytics / console / logcat in
/// debug builds and would let anyone with read access replay a
/// verification or unsubscription. Sensitive keys are replaced with
/// `***` before the body is printed.
class ApiLogger extends Interceptor {
  ApiLogger({this.enabled = true});

  /// Toggle to silence logging in release builds.
  final bool enabled;

  static const _tag = 'Api';

  /// Field names whose values must be masked in any logged body.
  /// Matched case-insensitively, so `Otp` and `otp` both trigger.
  static const Set<String> sensitiveFields = {
    'otp',
    'referenceno',
    'subscriberid',
    'usermobile',
    'user_mobile',
  };

  /// Canonical (mixed-case) key names for the sensitive fields. We
  /// use these for the JSON form `"key":"value"` regex so the
  /// replacement preserves the original camelCase style. The
  /// URL-encoded form (`key=value`) is matched case-insensitively
  /// so both `otp` and `OTP` are caught regardless of caller style.
  static const Set<String> _sensitiveOriginalCase = {
    'Otp',
    'otp',
    'referenceNo',
    'subscriberId',
    'userMobile',
    'user_mobile',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!enabled) return handler.next(options);
    developer.log(
      '→ ${options.method} ${options.uri}',
      name: _tag,
    );
    if (options.data != null) {
      developer.log(
        '  body: ${_truncate(_scrub(options.data))}',
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
        '  body: ${_truncate(_scrub(body))}',
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

  /// Replaces sensitive keys with `***` in any logged payload.
  /// Handles both `Map<String, dynamic>` (form data) and raw String
  /// bodies (server text response).
  static String scrub(Object? data) => _scrub(data);

  static String _scrub(Object? data) {
    if (data is Map) {
      return _scrubMap(data);
    }
    if (data is String) {
      return _scrubString(data);
    }
    return data.toString();
  }

  @visibleForTesting
  static String scrubMap(Map<dynamic, dynamic> map) => _scrubMap(map);

  static String _scrubMap(Map<dynamic, dynamic> map) {
    final out = <String, Object?>{};
    map.forEach((k, v) {
      final key = k.toString();
      if (_isSensitive(key)) {
        out[key] = '***';
      } else if (v is Map) {
        out[key] = _scrubMap(v);
      } else {
        out[key] = v;
      }
    });
    return out.toString();
  }

  /// Cheap, regex-based scrub for string bodies (e.g. JSON we
  /// decoded via `toString`). Looks for `"key":"value"` and
  /// `key=value` patterns.
  @visibleForTesting
  static String scrubString(String body) => _scrubString(body);

  static String _scrubString(String body) {
    var scrubbed = body;
    for (final key in _sensitiveOriginalCase) {
      // JSON form: "key":"value" — preserve the original case in
      // the replacement so the rendered log still looks idiomatic.
      // Match case-insensitively so we still catch `otp` / `Otp` /
      // `OTP`, but echo back whatever case the body used.
      final jsonRegex = RegExp(
        '"($key)"\\s*:\\s*"([^"]*)"',
        caseSensitive: false,
      );
      scrubbed = scrubbed.replaceAllMapped(
        jsonRegex,
        (m) => '"${m.group(1)}":"***"',
      );
      // URL-encoded form: key=value (terminated by & or end of
      // string). Same case-preservation here.
      final formRegex = RegExp(
        '($key)=([^&]*)',
        caseSensitive: false,
      );
      scrubbed = scrubbed.replaceAllMapped(
        formRegex,
        (m) => '${m.group(1)}=***',
      );
    }
    return scrubbed;
  }

  static bool _isSensitive(String key) {
    return sensitiveFields.contains(key.toLowerCase());
  }

  /// Keeps the log lines readable — some endpoints return multi-KB
  /// payloads that drown out the signal.
  static String _truncate(String s, [int max = 800]) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}… (+${s.length - max} chars)';
  }
}
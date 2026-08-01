import '../../core/network/exceptions.dart';

/// Maps server status codes (from the subscription API) and our
/// [NetworkException] types to **user-friendly** strings.
///
/// Centralised so:
///   * the same `E1951` always renders the same way across screens,
///   * tests can pin a single source of truth for UI copy,
///   * adding a new code is a one-line change.
///
/// The strings here are intentionally short — they show up in
/// snackbars and dialogs.
class FriendlyErrorMapper {
  const FriendlyErrorMapper();

  String map(Object error) {
    if (error is NoInternetException) {
      return 'No internet. Please check your connection and try again.';
    }
    if (error is TimeoutException) {
      return 'The request took too long. Please try again.';
    }
    if (error is CancelledException) {
      return 'Request cancelled.';
    }
    if (error is FormatException) {
      return 'Unexpected response from the server. Please try again.';
    }
    if (error is ServerException) {
      return _mapServerError(error);
    }
    if (error is NetworkException) {
      return error.message;
    }
    return 'Something went wrong. Please try again in a moment.';
  }

  String _mapServerError(ServerException e) {
    // The body may be a Map (JSON) or a String. We handle both.
    final body = e.errorBody;
    if (body is Map) {
      final code = (body['statusCode'] ?? body['status_code'])?.toString();
      final detail = (body['statusDetail'] ?? body['message'])?.toString();
      if (code != null) {
        final friendly = _statusCodeToMessage(code, detail);
        if (friendly != null) return friendly;
      }
    }
    if (e.statusCode == 0) {
      return 'Cannot reach the server. Please try again.';
    }
    if (e.statusCode >= 500) {
      return 'Server is having trouble. Please try again later.';
    }
    return 'Request failed (${e.statusCode}). Please try again.';
  }

  /// Documented server-side codes → user-friendly text. Returns
  /// `null` for codes we don't recognise so the caller can fall back
  /// to a generic message.
  String? _statusCodeToMessage(String code, String? detail) {
    switch (code) {
      case 'S1000':
        return 'Success.';
      case 'E1351':
        // The user is already registered with the carrier. Treated as
        // a soft success at the controller layer; this message is only
        // surfaced if it ever bubbles up.
        return 'You\'re already subscribed. Welcome back!';
      case 'E1951':
        return detail != null && detail.isNotEmpty
            ? detail
            : 'This number is not registered. Please check and try again.';
      case 'E1907':
        return 'OTP expired. Please request a new code.';
      case 'E1908':
        return 'Invalid OTP. Please check the code and try again.';
      default:
        if (detail != null && detail.isNotEmpty) return detail;
        return null;
    }
  }
}

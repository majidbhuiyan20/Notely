/// Centralised exception types for the network layer. Every call site
/// in the data layer throws one of these — UI code catches them and
/// maps them to user-friendly messages.
///
/// All exceptions extend [NetworkException] so consumers can either
/// pattern-match on the precise subtype (recommended) or use the
/// generic catch-all when only a generic message is needed.
library;

/// Base class for all network/transport-layer errors.
sealed class NetworkException implements Exception {
  const NetworkException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Raised when the device has no connectivity (per `Connectivity`).
class NoInternetException extends NetworkException {
  const NoInternetException()
      : super('No internet connection. Please check your network.');
}

/// Raised when a request takes longer than the configured timeout.
class TimeoutException extends NetworkException {
  const TimeoutException()
      : super('Request timed out. Please try again.');
}

/// Maps to HTTP 4xx/5xx responses from the server.
class ServerException extends NetworkException {
  const ServerException({
    required this.statusCode,
    required this.errorBody,
  }) : super('Server error ($statusCode)');

  /// HTTP status code (or `0` when the request never reached the server).
  final int statusCode;

  /// The raw response body, if any. Useful for inspecting structured
  /// error payloads from the subscription API.
  final Object? errorBody;
}

/// Raised when a 200 OK is returned but the payload is malformed.
class FormatException extends NetworkException {
  const FormatException(super.message);
}

/// Raised when the user cancels an in-flight request (e.g. closing
/// the OTP screen before the verification request finishes).
class CancelledException extends NetworkException {
  const CancelledException() : super('Request cancelled.');
}

/// Catch-all for any other transport-level error.
class UnknownNetworkException extends NetworkException {
  const UnknownNetworkException(super.message);
}

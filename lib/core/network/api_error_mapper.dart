import 'package:dio/dio.dart';

import 'exceptions.dart';

/// Translates low-level [DioException]s into our [NetworkException]
/// hierarchy. The rest of the app never sees [DioException] directly.
///
/// Lives in the core layer because every data source needs it.
class ApiErrorMapper {
  const ApiErrorMapper();

  NetworkException map(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TimeoutException();
      case DioExceptionType.cancel:
        return const CancelledException();
      case DioExceptionType.connectionError:
        return const NoInternetException();
      case DioExceptionType.badCertificate:
        return const UnknownNetworkException(
          'Secure connection failed. Please try again.',
        );
      case DioExceptionType.badResponse:
        return ServerException(
          statusCode: error.response?.statusCode ?? 0,
          errorBody: error.response?.data,
        );
      case DioExceptionType.unknown:
        return UnknownNetworkException(
          error.message ?? 'An unexpected error occurred.',
        );
    }
  }
}

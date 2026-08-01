import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/exceptions.dart';
import '../../core/subscription_constants.dart';
import '../models/otp_request_model.dart';
import '../models/otp_verification_model.dart';
import '../models/subscription_status_model.dart';
import '../models/unsubscribe_result_model.dart';

/// Hits the four subscription endpoints over [ApiClient]. Returns
/// models (DTOs) — never raw `Map<String, dynamic>` — and converts
/// transport-level errors into our [NetworkException] hierarchy
/// (which the [ApiClient] already does for us).
///
/// The BD Apps endpoints expect a
/// `application/x-www-form-urlencoded` body. Dio's default
/// encoding for a raw `Map<String, dynamic>` is JSON, which the
/// server rejects with a generic 500. We therefore wrap every
/// payload in `FormData.fromMap(...)`, which forces the
/// urlencoded content-type and the correct wire format.
class SubscriptionRemoteDataSource {
  SubscriptionRemoteDataSource({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<SubscriptionStatusModel> checkSubscription(String mobileNumber) async {
    final response = await _client.post(
      SubscriptionConstants.checkSubscriptionUrl,
      data: FormData.fromMap({'user_mobile': mobileNumber}),
    );
    return _parse(response, SubscriptionStatusModel.fromJson);
  }

  Future<OtpRequestModel> sendOtp(String mobileNumber) async {
    final response = await _client.post(
      SubscriptionConstants.sendOtpUrl,
      data: FormData.fromMap({'user_mobile': mobileNumber}),
    );
    return _parse(response, OtpRequestModel.fromJson);
  }

  Future<OtpVerificationModel> verifyOtp({
    required String mobileNumber,
    required String otp,
    required String referenceNo,
  }) async {
    final response = await _client.post(
      SubscriptionConstants.verifyOtpUrl,
      data: FormData.fromMap({
        'user_mobile': mobileNumber,
        'otp': otp,
        'referenceNo': referenceNo,
      }),
    );
    return _parse(response, OtpVerificationModel.fromJson);
  }

  Future<UnsubscribeResultModel> unsubscribe(String mobileNumber) async {
    final response = await _client.post(
      SubscriptionConstants.unsubscribeUrl,
      data: FormData.fromMap({'user_mobile': mobileNumber}),
    );
    return _parse(response, UnsubscribeResultModel.fromJson);
  }

  /// Common JSON-parse-and-validate helper. Throws [FormatException]
  /// (from the network layer's hierarchy) when the response is
  /// missing a body or the body is not a JSON object.
  T _parse<T>(
    dynamic response,
    T Function(Map<String, dynamic> json) factory,
  ) {
    final body = response?.data;
    if (body == null) {
      throw const FormatException('Empty response body.');
    }
    if (body is Map<String, dynamic>) {
      return factory(body);
    }
    if (body is String) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) return factory(decoded);
      } catch (_) {
        // fall through to FormatException
      }
    }
    throw const FormatException('Unexpected response shape.');
  }
}

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
/// The BD Apps endpoints expect an
/// `application/x-www-form-urlencoded` body. Dio encodes a plain
/// `Map<String, dynamic>` as form data only when the request's
/// content type is explicitly set to
/// `Headers.formUrlEncodedContentType`; `FormData.fromMap(...)` would
/// instead produce `multipart/form-data`, which is a different wire
/// format and is not guaranteed to be accepted by the PHP endpoints.
/// Every call below therefore sends a plain map together with explicit
/// URL-encoded [Options].
class SubscriptionRemoteDataSource {
  SubscriptionRemoteDataSource({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// Shared options for all four endpoints: URL-encoded form body
  /// with an explicit JSON Accept so the server can choose to reply
  /// with JSON.
  static final Options _formOptions = Options(
    contentType: Headers.formUrlEncodedContentType,
    headers: {
      'Accept': 'application/json',
    },
  );

  Future<SubscriptionStatusModel> checkSubscription(String mobileNumber) async {
    final response = await _client.post(
      SubscriptionConstants.checkSubscriptionUrl,
      data: {'user_mobile': mobileNumber},
      options: _formOptions,
    );
    return _parse(response, SubscriptionStatusModel.fromJson);
  }

  Future<OtpRequestModel> sendOtp(String mobileNumber) async {
    final response = await _client.post(
      SubscriptionConstants.sendOtpUrl,
      data: {'user_mobile': mobileNumber},
      options: _formOptions,
    );
    return _parse(response, OtpRequestModel.fromJson);
  }

  Future<OtpVerificationModel> verifyOtp({
    required String mobileNumber,
    required String otp,
    required String referenceNo,
  }) async {
    // BDApps PHP endpoint reads `$_POST['Otp']` and
    // `$_POST['referenceNo']` — the keys are CASE-SENSITIVE. PHP
    // does NOT normalise form keys, so sending `otp` (lowercase)
    // produces the user-visible error "OTP and referenceNo required".
    // We also include `user_mobile` for forward compatibility — the
    // server ignores unknown fields, and including the mobile lets
    // operators audit or debug the call.
    final response = await _client.post(
      SubscriptionConstants.verifyOtpUrl,
      data: {
        'user_mobile': mobileNumber,
        'Otp': otp,
        'referenceNo': referenceNo,
      },
      options: _formOptions,
    );
    return _parse(response, OtpVerificationModel.fromJson);
  }

  Future<UnsubscribeResultModel> unsubscribe(String mobileNumber) async {
    final response = await _client.post(
      SubscriptionConstants.unsubscribeUrl,
      data: {'user_mobile': mobileNumber},
      options: _formOptions,
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
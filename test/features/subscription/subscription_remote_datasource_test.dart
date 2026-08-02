// Tests for the SubscriptionRemoteDataSource — specifically the
// request body field names that the BDApps PHP endpoints expect.
//
// The PHP endpoints read `$_POST['key']` which is CASE-SENSITIVE.
// Sending `otp` (lowercase) makes the server respond with
// "OTP and referenceNo required". This test locks the wire format
// so a future refactor can't regress it.
//
// We use Dio's `HttpClientAdapter` mock to intercept the request
// body before it goes on the wire.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notely/core/network/api_client.dart';
import 'package:notely/core/network/internet_checker.dart';
import 'package:notely/features/subscription/core/subscription_constants.dart';
import 'package:notely/features/subscription/data/datasources/subscription_remote_datasource.dart';

/// Minimal Dio adapter that captures the request body and returns
/// a canned `S1000` response so the datasource can deserialize it.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({required this.responseBody});

  final String responseBody;
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    final bytes = utf8.encode(responseBody);
    return ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

void main() {
  late _CapturingAdapter adapter;
  late ApiClient apiClient;
  late SubscriptionRemoteDataSource source;

  setUp(() {
    adapter = _CapturingAdapter(
      responseBody: jsonEncode({
        'statusCode': 'S1000',
        'statusDetail': 'Request was successfully processed.',
        'subscriptionStatus': 'REGISTERED',
        'subscriberId': 'tel:8801712345678',
        'version': '1.0',
        'referenceNo': 'RE-SAMP-LE00',
      }),
    );
    final dio = Dio();
    dio.httpClientAdapter = adapter;
    apiClient = ApiClient(
      dio: dio,
      internetChecker: InternetChecker(override: () async => true),
    );
    source = SubscriptionRemoteDataSource(client: apiClient);
  });

  group('Request body field names (BDApps wire format)', () {
    test('verify_otp uses BDApps-canonical `Otp` (capital O)', () async {
      await source.verifyOtp(
        mobileNumber: '8801712345678',
        otp: '123456',
        referenceNo: 'REF-SECRET',
      );

      final body = adapter.lastRequest!.data;
      expect(body, isA<Map<String, dynamic>>());
      final map = body as Map<String, dynamic>;
      // The PHP endpoint reads `$_POST['Otp']` exactly.
      expect(map.containsKey('Otp'), isTrue);
      expect(map['Otp'], '123456');
      expect(map['referenceNo'], 'REF-SECRET');
      // We must NOT send a lowercase `otp` — PHP would ignore it.
      expect(map.containsKey('otp'), isFalse);
    });

    test('verify_otp sends urlencoded content type', () async {
      await source.verifyOtp(
        mobileNumber: '8801712345678',
        otp: '123456',
        referenceNo: 'REF',
      );
      final ct = adapter.lastRequest!.headers['Content-Type'] ??
          adapter.lastRequest!.contentType;
      expect(ct, contains('application/x-www-form-urlencoded'));
    });

    test('check_subscription sends `user_mobile`', () async {
      await source.checkSubscription('8801712345678');
      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['user_mobile'], '8801712345678');
      final ct = adapter.lastRequest!.headers['Content-Type'] ??
          adapter.lastRequest!.contentType;
      expect(ct, contains('application/x-www-form-urlencoded'));
    });

    test('send_otp sends `user_mobile`', () async {
      // Replace the expected response for sendOtp.
      adapter = _CapturingAdapter(
        responseBody: jsonEncode({
          'success': true,
          'message': 'OTP sent',
          'referenceNo': 'RE-SECRET',
          'statusCode': 'S1000',
          'statusDetail': 'OK',
          'version': '1.0',
          'subscriberId': 'tel:8801712345678',
        }),
      );
      final dio = Dio();
      dio.httpClientAdapter = adapter;
      apiClient = ApiClient(
        dio: dio,
        internetChecker: InternetChecker(override: () async => true),
      );
      source = SubscriptionRemoteDataSource(client: apiClient);

      await source.sendOtp('8801712345678');
      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['user_mobile'], '8801712345678');
    });

    test('unsubscribe sends `user_mobile`', () async {
      adapter = _CapturingAdapter(
        responseBody: jsonEncode({
          'success': true,
          'statusCode': 'S1000',
          'statusDetail': 'OK',
          'subscriptionStatus': 'UNREGISTERED',
          'subscriberId': 'tel:8801712345678',
          'action': 'UNSUBSCRIBE',
          'version': '1.0',
        }),
      );
      final dio = Dio();
      dio.httpClientAdapter = adapter;
      apiClient = ApiClient(
        dio: dio,
        internetChecker: InternetChecker(override: () async => true),
      );
      source = SubscriptionRemoteDataSource(client: apiClient);

      await source.unsubscribe('8801712345678');
      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['user_mobile'], '8801712345678');
    });

    test('verify_otp URL is the BDApps canonical one', () {
      // Documentation lock — verifies the URL pattern didn't drift.
      expect(
        SubscriptionConstants.verifyOtpUrl,
        'https://www.bdappsdigitalapps.com/NADB26112/verify_otp.php',
      );
      expect(
        SubscriptionConstants.sendOtpUrl,
        'https://www.bdappsdigitalapps.com/NADB26112/send_otp.php',
      );
      expect(
        SubscriptionConstants.checkSubscriptionUrl,
        'https://www.bdappsdigitalapps.com/NADB26112/check_subscription.php',
      );
      expect(
        SubscriptionConstants.unsubscribeUrl,
        'https://www.bdappsdigitalapps.com/NADB26112/unsubscribe.php',
      );
    });
  });
}
/// Constants for the subscription (mobile) authentication feature.
///
/// Keeping the API base URL in one place makes it easy to switch
/// environments (staging, prod, etc.) without touching feature code.
class SubscriptionConstants {
  SubscriptionConstants._();

  /// Shared base for all 4 BD Apps endpoints.
  static const String baseUrl = 'https://www.bdappsdigitalapps.com';
  static const String appId = 'NADB26112';

  static const String checkSubscriptionPath =
      '/$appId/check_subscription.php';
  static const String sendOtpPath = '/$appId/send_otp.php';
  static const String verifyOtpPath = '/$appId/verify_otp.php';
  static const String unsubscribePath = '/$appId/unsubscribe.php';

  /// Full URLs — convenient for direct calls in tests.
  static String get checkSubscriptionUrl => '$baseUrl$checkSubscriptionPath';
  static String get sendOtpUrl => '$baseUrl$sendOtpPath';
  static String get verifyOtpUrl => '$baseUrl$verifyOtpPath';
  static String get unsubscribeUrl => '$baseUrl$unsubscribePath';

  /// Bangladeshi country code.
  static const String countryCode = '+880';

  /// Allowed mobile prefixes (operator-agnostic).
  static const List<String> allowedPrefixes = [
    '013', '014', '015', '016', '017', '018', '019',
  ];

  /// Total digit count for a Bangladeshi mobile number (without code).
  static const int mobileLength = 11;

  /// OTP length.
  static const int otpLength = 6;

  /// Resend OTP cooldown.
  static const Duration otpResendCooldown = Duration(seconds: 60);

  /// The local-prefs key namespace for this feature.
  static const String prefsKey = 'notely.subscription.v1';
}

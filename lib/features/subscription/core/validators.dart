import 'subscription_constants.dart';

/// Stateless validators for the mobile + OTP fields. Each validator
/// returns `null` on success or a user-friendly error string on
/// failure — perfect for feeding straight into a `TextField`'s
/// `errorText`.
class Validators {
  Validators._();

  /// Validates a Bangladeshi mobile number entered as **local digits
  /// only** (e.g. `01712345678`). The `+880` country code is shown
  /// separately in the UI and is not part of the field value.
  static String? mobileNumber(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'Please enter your mobile number.';
    if (value.length != SubscriptionConstants.mobileLength) {
      return 'Mobile number must be ${SubscriptionConstants.mobileLength} digits.';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Mobile number can only contain digits.';
    }
    final prefix = value.substring(0, 3);
    if (!SubscriptionConstants.allowedPrefixes.contains(prefix)) {
      return 'Number must start with 013/014/015/016/017/018/019.';
    }
    return null;
  }

  /// Validates a 6-digit OTP. Empty input is allowed (UI will hide
  /// the error until the user has typed something).
  static String? otp(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'Please enter the verification code.';
    if (value.length != SubscriptionConstants.otpLength) {
      return 'Code must be ${SubscriptionConstants.otpLength} digits.';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Code can only contain digits.';
    }
    return null;
  }

  /// Returns the full E.164-ish number that the API expects
  /// (`8801XXXXXXXXX`). Used by every remote call so we keep the
  /// wire-format in one place.
  static String toApiMobile(String localNumber) {
    var digits = localNumber.replaceAll(RegExp(r'\D'), '');
    // Strip the leading 0 (if any) so `01712345678` becomes
    // `1712345678` before we prepend the country code.
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return '880$digits';
  }
}

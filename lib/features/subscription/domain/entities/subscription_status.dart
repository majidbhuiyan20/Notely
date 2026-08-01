/// Result of hitting `check_subscription.php`.
///
/// `isSubscribed` is the field that matters for routing: when `true`
/// we can skip OTP and go straight to Google Sign-In.
class SubscriptionStatus {
  const SubscriptionStatus({
    required this.isSubscribed,
    required this.subscriptionStatus,
    required this.subscriberId,
    required this.statusCode,
    required this.statusDetail,
    this.referenceNo,
  });

  /// `true` when the user already has an active subscription.
  final bool isSubscribed;

  /// Free-form description from the carrier (e.g. "ACTIVE",
  /// "INITIAL CHARGING PENDING", …).
  final String subscriptionStatus;

  /// E.164 number (e.g. `tel:8801828931039`). May be empty for some
  /// error responses.
  final String subscriberId;

  /// Documented status code — `S1000` for success.
  final String statusCode;

  /// Human-readable status detail. Surfaced in the UI only when the
  /// code is non-success.
  final String statusDetail;

  /// Populated when the subscription check requested an OTP flow.
  final String? referenceNo;

  /// True when the API considers the request to have succeeded
  /// (statusCode == "S1000").
  bool get isOk => statusCode == 'S1000';
}

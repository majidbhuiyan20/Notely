/// Result of `unsubscribe.php`. We always clear the local session
/// regardless of the outcome, so the precise values here matter only
/// for the snackbar / confirmation message.
class UnsubscribeResult {
  const UnsubscribeResult({
    required this.success,
    required this.statusCode,
    required this.statusDetail,
    required this.subscriptionStatus,
    required this.subscriberId,
  });

  final bool success;
  final String statusCode;
  final String statusDetail;
  final String subscriptionStatus;
  final String subscriberId;

  /// `true` when the carrier says the user is already unsubscribed
  /// (idempotent endpoint).
  bool get isAlreadyUnsubscribed => statusCode == 'E1951';
}

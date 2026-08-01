import '../../domain/entities/subscription_status.dart';

/// Wire model for the `check_subscription.php` response. Tolerates
/// missing fields (the carrier sometimes omits them on error
/// responses) by defaulting to safe empty values.
class SubscriptionStatusModel {
  const SubscriptionStatusModel({
    required this.subscriptionStatus,
    required this.isSubscribed,
    required this.statusCode,
    required this.statusDetail,
    required this.version,
    required this.subscriberId,
    this.referenceNo,
  });

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusModel(
      subscriptionStatus:
          (json['subscriptionStatus'] as String?) ?? '',
      // The API returns "true" / "false" as strings; some versions
      // also return a real bool. Handle both.
      isSubscribed: _parseBool(json['isSubscribed']),
      statusCode: (json['statusCode'] as String?) ?? '',
      statusDetail: (json['statusDetail'] as String?) ?? '',
      version: (json['version'] as String?) ?? '',
      subscriberId: (json['subscriberId'] as String?) ?? '',
      referenceNo: json['referenceNo'] as String?,
    );
  }

  static bool _parseBool(Object? raw) {
    if (raw is bool) return raw;
    if (raw is String) {
      return raw.toLowerCase() == 'true';
    }
    return false;
  }

  final String subscriptionStatus;
  final bool isSubscribed;
  final String statusCode;
  final String statusDetail;
  final String version;
  final String subscriberId;
  final String? referenceNo;

  SubscriptionStatus toEntity() => SubscriptionStatus(
        isSubscribed: isSubscribed,
        subscriptionStatus: subscriptionStatus,
        subscriberId: subscriberId,
        statusCode: statusCode,
        statusDetail: statusDetail,
        referenceNo: referenceNo,
      );
}

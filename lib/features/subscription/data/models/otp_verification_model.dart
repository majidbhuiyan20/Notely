import '../../domain/entities/otp_verification.dart';

class OtpVerificationModel {
  const OtpVerificationModel({
    required this.statusCode,
    required this.statusDetail,
    required this.subscriptionStatus,
    required this.subscriberId,
    required this.version,
    this.isSubscribed = false,
  });

  factory OtpVerificationModel.fromJson(Map<String, dynamic> json) {
    return OtpVerificationModel(
      statusCode: (json['statusCode'] as String?) ?? '',
      statusDetail: (json['statusDetail'] as String?) ?? '',
      subscriptionStatus:
          (json['subscriptionStatus'] as String?) ?? '',
      subscriberId: (json['subscriberId'] as String?) ?? '',
      version: (json['version'] as String?) ?? '',
      isSubscribed: _parseBool(json['isSubscribed']),
    );
  }

  static bool _parseBool(Object? raw) {
    if (raw is bool) return raw;
    if (raw is String) {
      return raw.toLowerCase() == 'true';
    }
    return false;
  }

  final String statusCode;
  final String statusDetail;
  final String subscriptionStatus;
  final String subscriberId;
  final String version;
  final bool isSubscribed;

  OtpVerification toEntity() => OtpVerification(
        statusCode: statusCode,
        statusDetail: statusDetail,
        subscriptionStatus: subscriptionStatus,
        subscriberId: subscriberId,
        isSubscribed: isSubscribed,
      );
}
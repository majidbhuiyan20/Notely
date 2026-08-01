import '../../domain/entities/otp_verification.dart';

class OtpVerificationModel {
  const OtpVerificationModel({
    required this.statusCode,
    required this.statusDetail,
    required this.subscriptionStatus,
    required this.subscriberId,
    required this.version,
  });

  factory OtpVerificationModel.fromJson(Map<String, dynamic> json) {
    return OtpVerificationModel(
      statusCode: (json['statusCode'] as String?) ?? '',
      statusDetail: (json['statusDetail'] as String?) ?? '',
      subscriptionStatus:
          (json['subscriptionStatus'] as String?) ?? '',
      subscriberId: (json['subscriberId'] as String?) ?? '',
      version: (json['version'] as String?) ?? '',
    );
  }

  final String statusCode;
  final String statusDetail;
  final String subscriptionStatus;
  final String subscriberId;
  final String version;

  OtpVerification toEntity() => OtpVerification(
        statusCode: statusCode,
        statusDetail: statusDetail,
        subscriptionStatus: subscriptionStatus,
        subscriberId: subscriberId,
      );
}

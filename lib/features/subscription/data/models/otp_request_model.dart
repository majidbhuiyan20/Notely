import '../../domain/entities/otp_request.dart';

class OtpRequestModel {
  const OtpRequestModel({
    required this.success,
    required this.message,
    required this.referenceNo,
    required this.statusCode,
    required this.statusDetail,
    required this.version,
    required this.subscriberId,
  });

  factory OtpRequestModel.fromJson(Map<String, dynamic> json) {
    return OtpRequestModel(
      success: _parseBool(json['success']),
      message: (json['message'] as String?) ?? '',
      referenceNo: json['referenceNo'] as String?,
      statusCode: (json['statusCode'] as String?) ?? '',
      statusDetail: (json['statusDetail'] as String?) ?? '',
      version: (json['version'] as String?) ?? '',
      subscriberId: (json['subscriberId'] as String?) ?? '',
    );
  }

  static bool _parseBool(Object? raw) {
    if (raw is bool) return raw;
    if (raw is String) return raw.toLowerCase() == 'true';
    return false;
  }

  final bool success;
  final String message;
  final String? referenceNo;
  final String statusCode;
  final String statusDetail;
  final String version;
  final String subscriberId;

  OtpRequest toEntity() => OtpRequest(
        success: success,
        message: message,
        referenceNo: referenceNo,
        statusCode: statusCode,
        statusDetail: statusDetail,
        subscriberId: subscriberId,
      );
}

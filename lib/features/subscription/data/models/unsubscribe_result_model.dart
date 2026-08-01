import '../../domain/entities/unsubscribe_result.dart';

class UnsubscribeResultModel {
  const UnsubscribeResultModel({
    required this.success,
    required this.statusCode,
    required this.statusDetail,
    required this.subscriptionStatus,
    required this.subscriberId,
    required this.action,
    required this.version,
  });

  factory UnsubscribeResultModel.fromJson(Map<String, dynamic> json) {
    return UnsubscribeResultModel(
      success: _parseBool(json['success']),
      statusCode: (json['statusCode'] as String?) ?? '',
      statusDetail: (json['statusDetail'] as String?) ?? '',
      subscriptionStatus:
          (json['subscriptionStatus'] as String?) ?? 'UNKNOWN',
      subscriberId: (json['subscriberId'] as String?) ?? '',
      action: (json['action'] as String?) ?? '',
      version: (json['version'] as String?) ?? '',
    );
  }

  static bool _parseBool(Object? raw) {
    if (raw is bool) return raw;
    if (raw is String) return raw.toLowerCase() == 'true';
    return false;
  }

  final bool success;
  final String statusCode;
  final String statusDetail;
  final String subscriptionStatus;
  final String subscriberId;
  final String action;
  final String version;

  UnsubscribeResult toEntity() => UnsubscribeResult(
        success: success,
        statusCode: statusCode,
        statusDetail: statusDetail,
        subscriptionStatus: subscriptionStatus,
        subscriberId: subscriberId,
      );
}

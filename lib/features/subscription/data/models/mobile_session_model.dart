import '../../domain/entities/mobile_session.dart';

/// Data-layer DTO for [MobileSession] — adds JSON serialization
/// so we can persist the entire session as a single blob.
class MobileSessionModel extends MobileSession {
  const MobileSessionModel({
    required super.isMobileLoggedIn,
    required super.isGoogleLoggedIn,
    required super.isOnboardingCompleted,
    super.isSubscribed,
    super.mobileNumber,
    super.subscriberId,
    super.subscriptionStatus,
    super.firebaseUid,
    super.email,
    super.displayName,
    super.photoUrl,
    super.loginDate,
    super.referenceNo,
  });

  factory MobileSessionModel.fromEntity(MobileSession session) {
    return MobileSessionModel(
      isMobileLoggedIn: session.isMobileLoggedIn,
      isGoogleLoggedIn: session.isGoogleLoggedIn,
      isOnboardingCompleted: session.isOnboardingCompleted,
      isSubscribed: session.isSubscribed,
      mobileNumber: session.mobileNumber,
      subscriberId: session.subscriberId,
      subscriptionStatus: session.subscriptionStatus,
      firebaseUid: session.firebaseUid,
      email: session.email,
      displayName: session.displayName,
      photoUrl: session.photoUrl,
      loginDate: session.loginDate,
      referenceNo: session.referenceNo,
    );
  }

  factory MobileSessionModel.fromJson(Map<String, dynamic> json) {
    return MobileSessionModel(
      isMobileLoggedIn: (json['isMobileLoggedIn'] as bool?) ?? false,
      isGoogleLoggedIn: (json['isGoogleLoggedIn'] as bool?) ?? false,
      isOnboardingCompleted:
          (json['isOnboardingCompleted'] as bool?) ?? false,
      isSubscribed: (json['isSubscribed'] as bool?) ?? false,
      mobileNumber: json['mobileNumber'] as String?,
      subscriberId: json['subscriberId'] as String?,
      subscriptionStatus: json['subscriptionStatus'] as String?,
      firebaseUid: json['firebaseUid'] as String?,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      loginDate: json['loginDate'] == null
          ? null
          : DateTime.tryParse(json['loginDate'] as String),
      referenceNo: json['referenceNo'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'isMobileLoggedIn': isMobileLoggedIn,
        'isGoogleLoggedIn': isGoogleLoggedIn,
        'isOnboardingCompleted': isOnboardingCompleted,
        'isSubscribed': isSubscribed,
        if (mobileNumber != null) 'mobileNumber': mobileNumber,
        if (subscriberId != null) 'subscriberId': subscriberId,
        if (subscriptionStatus != null)
          'subscriptionStatus': subscriptionStatus,
        if (firebaseUid != null) 'firebaseUid': firebaseUid,
        if (email != null) 'email': email,
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (loginDate != null) 'loginDate': loginDate!.toIso8601String(),
        if (referenceNo != null) 'referenceNo': referenceNo,
      };

  MobileSession toEntity() => MobileSession(
        isMobileLoggedIn: isMobileLoggedIn,
        isGoogleLoggedIn: isGoogleLoggedIn,
        isOnboardingCompleted: isOnboardingCompleted,
        isSubscribed: isSubscribed,
        mobileNumber: mobileNumber,
        subscriberId: subscriberId,
        subscriptionStatus: subscriptionStatus,
        firebaseUid: firebaseUid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        loginDate: loginDate,
        referenceNo: referenceNo,
      );
}
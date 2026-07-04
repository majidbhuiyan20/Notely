import '../../domain/entities/auth_user.dart';

/// DTO used by the data layer. Adds JSON serialization for local
/// persistence and a factory for converting from external user records
/// (Firebase User, GoogleSignInAccount, etc.).
class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.uid,
    required super.displayName,
    required super.email,
    required super.photoUrl,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      uid: (json['uid'] as String?) ?? '',
      displayName: (json['displayName'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
      };

  factory AuthUserModel.fromFirebase({
    required String uid,
    required String? displayName,
    required String? email,
    required String? photoUrl,
  }) {
    return AuthUserModel(
      uid: uid,
      displayName: displayName ?? '',
      email: email ?? '',
      photoUrl: photoUrl,
    );
  }

  factory AuthUserModel.fromEntity(AuthUser user) {
    return AuthUserModel(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoUrl,
    );
  }
}
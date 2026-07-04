/// Immutable representation of the authenticated user. Used across the
/// presentation layer so screens can render greetings, avatars, etc.
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
  });

  /// Stable unique identifier (Firebase UID, etc.).
  final String uid;

  /// Human-friendly name shown in the UI.
  final String displayName;

  /// Account email address (may be empty if not granted by the provider).
  final String email;

  /// Absolute URL to a profile photo, or `null` when none is available.
  final String? photoUrl;

  /// First name only (handy for greetings like "Hi, Majid").
  String get firstName {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'there';
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.first;
  }

  AuthUser copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          other.uid == uid &&
          other.displayName == displayName &&
          other.email == email &&
          other.photoUrl == photoUrl;

  @override
  int get hashCode =>
      Object.hash(uid, displayName, email, photoUrl);
}

/// Thrown when authentication fails for any reason (cancellation, network,
/// missing Firebase user, etc.).
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => 'AuthFailure: $message';
}
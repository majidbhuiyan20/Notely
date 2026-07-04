import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user_model.dart';

/// Reads and writes the cached [AuthUserModel] and onboarding flag in
/// [SharedPreferences]. The user is stored as a single JSON blob under
/// [_userKey] so migrations are simple.
class AuthLocalDataSource {
  AuthLocalDataSource({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const String _userKey = 'notely.auth.user.v1';
  static const String _onboardingKey = 'notely.onboarding.completed.v1';

  final SharedPreferences? _prefsOverride;

  Future<SharedPreferences> _prefs() async =>
      _prefsOverride ?? await SharedPreferences.getInstance();

  // --- User ---

  Future<AuthUserModel?> readUser() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthUserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupted cache – wipe and treat as signed out.
      await prefs.remove(_userKey);
      return null;
    }
  }

  Future<void> writeUser(AuthUserModel user) async {
    final prefs = await _prefs();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> clearUser() async {
    final prefs = await _prefs();
    await prefs.remove(_userKey);
  }

  // --- Onboarding ---

  /// Whether the user has finished the onboarding carousel at least once.
  /// Used at app startup to decide between Splash → Onboarding → Login
  /// and Splash → Login.
  Future<bool> isOnboardingComplete() async {
    final prefs = await _prefs();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> markOnboardingComplete() async {
    final prefs = await _prefs();
    await prefs.setBool(_onboardingKey, true);
  }
}

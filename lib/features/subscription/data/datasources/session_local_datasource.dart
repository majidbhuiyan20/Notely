import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/mobile_session.dart';
import '../models/mobile_session_model.dart';

/// SharedPreferences wrapper for the mobile-subscription session.
///
/// All keys live under a single root so we can wipe the entire
/// feature in one `prefs.remove(...)` call during unsubscribe /
/// logout.
class SessionLocalDataSource {
  SessionLocalDataSource({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const String _rootKey = 'notely.subscription.v1.session';
  static const String _mobileKey = '$_rootKey.mobile';
  static const String _googleKey = '$_rootKey.google';
  static const String _onboardingKey = '$_rootKey.onboarding';

  // Detail keys (so we can update individual fields without rewriting
  // the entire blob — handy when only one field changes).
  static const String _mobileNumberKey = 'notely.subscription.v1.mobileNumber';
  static const String _subscriberIdKey = 'notely.subscription.v1.subscriberId';
  static const String _subscriptionStatusKey =
      'notely.subscription.v1.subscriptionStatus';
  static const String _firebaseUidKey = 'notely.subscription.v1.firebaseUid';
  static const String _emailKey = 'notely.subscription.v1.email';
  static const String _displayNameKey = 'notely.subscription.v1.displayName';
  static const String _photoUrlKey = 'notely.subscription.v1.photoUrl';
  static const String _loginDateKey = 'notely.subscription.v1.loginDate';
  static const String _referenceNoKey = 'notely.subscription.v1.referenceNo';

  final SharedPreferences? _prefsOverride;

  Future<SharedPreferences> _prefs() async =>
      _prefsOverride ?? await SharedPreferences.getInstance();

  // --- Read ---

  Future<MobileSession> read() async {
    final prefs = await _prefs();
    try {
      final raw = prefs.getString(_rootKey);
      if (raw == null || raw.isEmpty) {
        return _compose(prefs);
      }
      return MobileSessionModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      ).toEntity();
    } catch (_) {
      // Corrupt cache — wipe and start over.
      await prefs.remove(_rootKey);
      return MobileSession.empty;
    }
  }

  /// Reconstructs a [MobileSession] from individual prefs (fallback when
  /// the blob is missing but some legacy keys exist).
  MobileSession _compose(SharedPreferences prefs) {
    return MobileSession(
      isMobileLoggedIn: prefs.getBool(_mobileKey) ?? false,
      isGoogleLoggedIn: prefs.getBool(_googleKey) ?? false,
      isOnboardingCompleted: prefs.getBool(_onboardingKey) ?? false,
      mobileNumber: prefs.getString(_mobileNumberKey),
      subscriberId: prefs.getString(_subscriberIdKey),
      subscriptionStatus: prefs.getString(_subscriptionStatusKey),
      firebaseUid: prefs.getString(_firebaseUidKey),
      email: prefs.getString(_emailKey),
      displayName: prefs.getString(_displayNameKey),
      photoUrl: prefs.getString(_photoUrlKey),
      loginDate: _parseDate(prefs.getString(_loginDateKey)),
      referenceNo: prefs.getString(_referenceNoKey),
    );
  }

  // --- Write ---

  Future<void> write(MobileSession session) async {
    final prefs = await _prefs();
    final model = MobileSessionModel.fromEntity(session);
    await prefs.setString(_rootKey, jsonEncode(model.toJson()));
    // Also write the individual fields for cheap read paths.
    await prefs.setBool(_mobileKey, session.isMobileLoggedIn);
    await prefs.setBool(_googleKey, session.isGoogleLoggedIn);
    await prefs.setBool(_onboardingKey, session.isOnboardingCompleted);
    if (session.mobileNumber != null) {
      await prefs.setString(_mobileNumberKey, session.mobileNumber!);
    }
    if (session.subscriberId != null) {
      await prefs.setString(_subscriberIdKey, session.subscriberId!);
    }
    if (session.subscriptionStatus != null) {
      await prefs.setString(
        _subscriptionStatusKey,
        session.subscriptionStatus!,
      );
    }
    if (session.firebaseUid != null) {
      await prefs.setString(_firebaseUidKey, session.firebaseUid!);
    }
    if (session.email != null) {
      await prefs.setString(_emailKey, session.email!);
    }
    if (session.displayName != null) {
      await prefs.setString(_displayNameKey, session.displayName!);
    }
    if (session.photoUrl != null) {
      await prefs.setString(_photoUrlKey, session.photoUrl!);
    }
    if (session.loginDate != null) {
      await prefs.setString(
        _loginDateKey,
        session.loginDate!.toIso8601String(),
      );
    }
    if (session.referenceNo != null) {
      await prefs.setString(_referenceNoKey, session.referenceNo!);
    }
  }

  /// Wipes EVERY key owned by this feature. Called by `clearSession()`
  /// and during Unsubscribe & Logout.
  Future<void> wipe() async {
    final prefs = await _prefs();
    final keys = <String>{
      _rootKey,
      _mobileKey,
      _googleKey,
      _onboardingKey,
      _mobileNumberKey,
      _subscriberIdKey,
      _subscriptionStatusKey,
      _firebaseUidKey,
      _emailKey,
      _displayNameKey,
      _photoUrlKey,
      _loginDateKey,
      _referenceNoKey,
    };
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  // --- Helpers ---

  DateTime? _parseDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }
}

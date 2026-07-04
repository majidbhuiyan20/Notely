import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/auth_user.dart';
import '../models/auth_user_model.dart';

/// Talks to Firebase Auth + Google Sign-In to perform the actual login.
/// Exposed through [AuthRepository] so the rest of the app never imports
/// the Firebase/Google packages directly.
class AuthRemoteDataSource {
  AuthRemoteDataSource({
    fb.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _google = googleSignIn ?? GoogleSignIn();

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _google;

  /// Returns the currently signed-in Firebase user, or `null` when no
  /// session is active. This is what we use at app startup as a fallback
  /// when the local cache is empty.
  AuthUser? currentUser() {
    final user = _auth.currentUser;
    return user == null ? null : _toModel(user);
  }

  /// Runs the Google Sign-In + Firebase credential exchange flow. Throws
  /// an [AuthFailure] for any failure (cancellation, network, missing
  /// Firebase user, etc.).
  Future<AuthUser> signInWithGoogle() async {
    try {
      developer.log('Attempting Google Sign-In', name: 'Auth');

      // Trigger the native Google Sign-In UI on iOS/Android.
      final account = await _google.signIn();
      if (account == null) {
        developer.log('User cancelled Google Sign-In', name: 'Auth');
        throw const AuthFailure('Sign-in cancelled.');
      }

      developer.log(
        'Google account obtained: ${account.email}',
        name: 'Auth',
      );

      final googleAuth = await account.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw const AuthFailure('Firebase returned no user.');
      }

      developer.log('Signed in to Firebase as ${user.uid}', name: 'Auth');
      return _toModel(user);
    } on fb.FirebaseAuthException catch (e) {
      developer.log(
        'FirebaseAuthException [${e.code}] ${e.message}',
        name: 'Auth',
        error: e,
      );
      throw AuthFailure(e.message ?? 'Authentication failed.');
    } on AuthFailure {
      rethrow;
    } catch (e, stack) {
      developer.log(
        'Unexpected sign-in error',
        name: 'Auth',
        error: e,
        stackTrace: stack,
      );
      throw const AuthFailure(
        'An unexpected error occurred. Please check your connection and try again.',
      );
    }
  }

  /// Signs out from both Google and Firebase. Errors are swallowed because
  /// sign-out is best-effort; we'll still clear the local cache.
  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (e) {
      developer.log('Google sign-out error', name: 'Auth', error: e);
    }
    try {
      await _auth.signOut();
    } catch (e) {
      developer.log('Firebase sign-out error', name: 'Auth', error: e);
    }
  }

  AuthUserModel _toModel(fb.User user) {
    return AuthUserModel.fromFirebase(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Small, opinionated wrapper around [SnackBar] so feature code never has
/// to know about colors, padding, or Material 3 behavior. Use the static
/// helpers (`AppSnackbar.success`, `AppSnackbar.error`, `AppSnackbar.info`)
/// for the common cases and drop a fully-custom [SnackBar] through
/// [AppSnackbar.show] when you need more control.
///
/// All messages are floating, queued (one at a time), and dismissed by
/// the user tapping them or by the 3s default timeout.
class AppSnackbar {
  AppSnackbar._();

  /// Show a green "success" message. Use after a successful sign-in,
  /// save, delete, etc.
  static void success(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_rounded,
    );
  }

  /// Show a red "error" message. Use for failure cases.
  static void error(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.error,
      icon: Icons.error_rounded,
    );
  }

  /// Show a neutral "info" message. Use when something noteworthy happens
  /// but it isn't strictly an error or success.
  static void info(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.royalBlue,
      icon: Icons.info_rounded,
    );
  }

  /// Show a fully custom [SnackBar]. Useful when the simple helpers don't
  /// cover the use case.
  static void show(BuildContext context, SnackBar snackBar) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Async-safe variant of [info]. Use when you've already crossed an
  /// `await` and no longer trust the [BuildContext] to still be mounted.
  static void showInfo(ScaffoldMessengerState messenger, String message) {
    _showOn(messenger, message, AppColors.royalBlue, Icons.info_rounded);
  }

  /// Async-safe variant of [success].
  static void showSuccess(ScaffoldMessengerState messenger, String message) {
    _showOn(messenger, message, AppColors.success, Icons.check_circle_rounded);
  }

  /// Async-safe variant of [error].
  static void showError(ScaffoldMessengerState messenger, String message) {
    _showOn(messenger, message, AppColors.error, Icons.error_rounded);
  }

  static void _showOn(
    ScaffoldMessengerState messenger,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
          elevation: 6,
        ),
      );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    show(
      context,
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }
}

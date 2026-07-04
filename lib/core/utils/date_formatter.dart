import 'package:flutter/material.dart';

/// Tiny pure helpers for the calendar's time-of-day field. We deliberately
/// don't pull in `intl` — the project hand-rolls all date formatting and
/// the only formatting we need is 12-hour `h:mm a` and 24-hour `HH:mm`.
class DateFormatter {
  DateFormatter._();

  /// Converts a 24-hour `'HH:mm'` string (e.g. `'14:30'`, `'09:05'`) to
  /// a 12-hour display string (e.g. `'2:30 PM'`, `'9:05 AM'`).
  /// Returns the input unchanged when it isn't a well-formed `HH:mm`.
  static String formatTime12h(String hhmm) {
    final parsed = parseTime24h(hhmm);
    if (parsed == null) return hhmm;
    final h = parsed.hour;
    final m = parsed.minute.toString().padLeft(2, '0');
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $period';
  }

  /// Converts a [TimeOfDay] to the 24-hour `'HH:mm'` form we persist.
  static String formatTime24h(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  /// Parses a 24-hour `'HH:mm'` string into a [TimeOfDay]. Returns
  /// `null` for blank input or any malformed value.
  static TimeOfDay? parseTime24h(String s) {
    if (s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }
}
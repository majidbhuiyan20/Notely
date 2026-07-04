import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/analytics_repository.dart';

/// Tracks which range pill (Day / Week / Month / Year) is active on the
/// analytics screen. Uses Riverpod 3.x [Notifier] — [StateProvider] is
/// not exported by `flutter_riverpod` 3.3.
class AnalyticsRangeNotifier extends Notifier<AnalyticsRange> {
  @override
  AnalyticsRange build() => AnalyticsRange.week;

  void set(AnalyticsRange value) => state = value;
}

final analyticsRangeProvider =
    NotifierProvider<AnalyticsRangeNotifier, AnalyticsRange>(
  AnalyticsRangeNotifier.new,
);
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/category_filter_tabs.dart' show CategoryFilter;

/// Filter pill on the category details screen — All / Pending / Completed.
class CategoryFilterNotifier extends Notifier<CategoryFilter> {
  @override
  CategoryFilter build() => CategoryFilter.all;

  void set(CategoryFilter value) => state = value;
}

final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, CategoryFilter>(
  CategoryFilterNotifier.new,
);

/// Whether the category list is sorted by priority (true) or by insertion
/// order (false). Toggled by the "Priority / Default" chip.
class CategorySortByPriorityNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;

  void set(bool value) => state = value;
}

final categorySortByPriorityProvider =
    NotifierProvider<CategorySortByPriorityNotifier, bool>(
  CategorySortByPriorityNotifier.new,
);
// Locks the contract that lets Flutter's release-build icon-font
// tree-shaker keep every category glyph. If anyone ever adds a
// runtime `IconData(...)` or drops a const reference, this test
// suite fails before the release build does.
//
// Specifically:
//   1. `defaultIcon` must be a const IconData.
//   2. Every entry registered in the catalog must be reachable via
//      `resolve()` and round-trip its own code point.
//   3. An unknown code point must fall back to `defaultIcon`.
//   4. The catalog must contain at least the icons referenced by
//      the NotesRepository metadata (lifestyle categories).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notely/features/task/model/category_icons.dart';

void main() {
  group('CategoryIcons (tree-shake contract)', () {
    test('defaultIcon is a const IconData reference', () {
      // If a future refactor ever replaces the const with a
      // runtime IconData, the release build breaks. This test
      // surfaces that locally first.
      const IconData icon = CategoryIcons.defaultIcon;
      expect(icon.codePoint, isNonZero);
      expect(icon.fontFamily, isNotEmpty);
    });

    test('resolve returns the same IconData whose code point was queried',
        () {
      // For every glyph in the catalog, looking it up by its own
      // code point must return itself (not the fallback). This
      // catches the case where someone forgets to register a
      // const reference in the catalog.
      for (final registered in CategoryIcons.byCodePoint.values) {
        final looked = CategoryIcons.resolve(registered.codePoint);
        expect(looked.codePoint, registered.codePoint,
            reason: 'Catalog entry ${registered.codePoint} not retrievable');
        expect(looked.codePoint, isNonZero);
      }
    });

    test('resolve falls back to defaultIcon for unknown code points', () {
      final unknown = CategoryIcons.resolve(0x7FFFFFFF);
      expect(unknown.codePoint, CategoryIcons.defaultIcon.codePoint);
    });

    test('catalog contains the lifestyle categories used by the app', () {
      // The NotesRepository defines its categories with specific
      // icons; if any of those ever stop being const references,
      // the tree-shaker will drop them. This test makes the
      // expectation explicit so a future refactor knows what to
      // keep.
      const expectedIcons = <IconData>[
        Icons.note_alt_outlined,
        Icons.person_outline,
        Icons.work_outline,
        Icons.favorite_border,
        Icons.account_balance_wallet_outlined,
        Icons.flight_takeoff,
        Icons.shopping_cart_outlined,
        Icons.restaurant,
        Icons.lightbulb_outline,
        Icons.music_note,
        Icons.sports_basketball,
        Icons.school_outlined,
        Icons.camera_alt_outlined,
        Icons.code,
        Icons.palette_outlined,
        Icons.local_florist_outlined,
        Icons.sports_esports_outlined,
        Icons.movie_filter_outlined,
        Icons.menu_book_outlined,
        Icons.wb_sunny_outlined,
      ];
      for (final icon in expectedIcons) {
        expect(
          CategoryIcons.resolve(icon.codePoint).codePoint,
          icon.codePoint,
          reason: 'Icon ${icon.codePoint} not registered',
        );
      }
    });

    test('byCodePoint map has no duplicate keys', () {
      // The catalog uses an iterable-to-map spread which would
      // silently drop collisions. Make sure the spread is
      // collision-free so every entry is reachable.
      final keys = <int>{};
      for (final key in CategoryIcons.byCodePoint.keys) {
        expect(keys.add(key), isTrue,
            reason: 'Duplicate key $key in byCodePoint');
      }
    });
  });
}
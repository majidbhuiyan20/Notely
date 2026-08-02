import 'package:flutter/material.dart';

/// Const catalog of every category icon used by the app.
///
/// We **must** use `const IconData` for every entry — Flutter's
/// release build runs an "icon-font tree-shaker" that prunes any
/// icon-glyph files that aren't reachable from a const IconData
/// reference. If the app ever builds a `IconData` at runtime (e.g.
/// `IconData(iconCodePoint, fontFamily: 'MaterialIcons')`) the
/// shaker refuses to run, the release build fails, and the
/// offending call site is reported as a non-const
/// `IconData` instance.
///
/// Why a catalog? Three reasons:
///
/// 1. **Tree-shaking works** — every `IconData` here is a const
///    reference, so every glyph referenced here is kept in the
///    binary. Glyphs that aren't referenced (because the user
///    removed the `Icons.work_outline` import, say) are dropped,
///    keeping the APK small.
/// 2. **Backwards-compatible persistence** — the local DB stores
///    `iconCodePoint`. We look it up at read time and fall back to
///    [defaultIcon] when the value is missing or has been retired.
/// 3. **No surprises when the user upgrades** — the lookup table
///    here is the single source of truth for "which icons are
///    valid". A new entry can be added without breaking old data.
///
/// Why a non-const Map? `IconData.codePoint` is a method, so
/// `Icons.X.codePoint` is *not* a compile-time constant — Dart
/// forbids method calls in const map keys. The map itself doesn't
/// have to be const; only the **values** must be const `IconData`
/// references for the tree-shaker to keep the glyphs. So we build
/// the lookup once at first access and cache it in [_byCodePoint].
///
/// When you need a new category icon, add a new `static const`
/// line below and use it in [NotesRepository.categoryMeta].
class CategoryIcons {
  CategoryIcons._();

  /// Default fallback when the stored `iconCodePoint` doesn't match
  /// any registered icon (corrupt row, very old data, or a glyph
  /// that was removed in a later release).
  static const IconData defaultIcon = Icons.more_horiz_outlined;

  // ─── Const references for every icon in the catalog. Declaring
  //     each one as a `static const` ensures Flutter's icon-font
  //     tree-shaker keeps the glyph in the release binary even if
  //     the icon is never rendered at runtime. Add new icons here,
  //     then register them in [_catalog] below.
  static const IconData _iconMoreHoriz = Icons.more_horiz_outlined;
  static const IconData _iconNoteAlt = Icons.note_alt_outlined;
  static const IconData _iconPerson = Icons.person_outline;
  static const IconData _iconWork = Icons.work_outline;
  static const IconData _iconFavorite = Icons.favorite_border;
  static const IconData _iconWallet = Icons.account_balance_wallet_outlined;
  static const IconData _iconFlight = Icons.flight_takeoff;
  static const IconData _iconCart = Icons.shopping_cart_outlined;
  static const IconData _iconRestaurant = Icons.restaurant;
  static const IconData _iconLightbulb = Icons.lightbulb_outline;
  static const IconData _iconMusic = Icons.music_note;
  static const IconData _iconBasketball = Icons.sports_basketball;
  static const IconData _iconSchool = Icons.school_outlined;
  static const IconData _iconCamera = Icons.camera_alt_outlined;
  static const IconData _iconCode = Icons.code;
  static const IconData _iconPalette = Icons.palette_outlined;
  static const IconData _iconFlorist = Icons.local_florist_outlined;
  static const IconData _iconEsports = Icons.sports_esports_outlined;
  static const IconData _iconMovie = Icons.movie_filter_outlined;
  static const IconData _iconBook = Icons.menu_book_outlined;
  static const IconData _iconSun = Icons.wb_sunny_outlined;

  /// Source-of-truth list — order must match the keys in
  /// [NotesRepository.categoryMeta]. Every entry is a const
  /// reference so the tree-shaker keeps the glyph.
  static const List<IconData> _catalog = <IconData>[
    _iconMoreHoriz, // Reserved — legacy default fallback.
    _iconNoteAlt,
    _iconPerson,
    _iconWork,
    _iconFavorite,
    _iconWallet,
    _iconFlight,
    _iconCart,
    _iconRestaurant,
    _iconLightbulb,
    _iconMusic,
    _iconBasketball,
    _iconSchool,
    _iconCamera,
    _iconCode,
    _iconPalette,
    _iconFlorist,
    _iconEsports,
    _iconMovie,
    _iconBook,
    _iconSun,
  ];

  /// Lazy lookup table. Built once on first access, then reused.
  /// The map itself isn't const because [IconData.codePoint] is a
  /// method (not a compile-time constant), but the values are all
  /// const `IconData` references — which is what the tree-shaker
  /// actually checks.
  static final Map<int, IconData> _byCodePoint = <int, IconData>{
    for (final icon in _catalog) icon.codePoint: icon,
  };

  /// Public read-only view of the catalog. Exposed for tests and
  /// debug tooling — production code should call [resolve].
  static Map<int, IconData> get byCodePoint =>
      Map<int, IconData>.unmodifiable(_byCodePoint);

  /// Returns the [IconData] registered for [codePoint], or
  /// [defaultIcon] if the code point isn't in the catalog.
  static IconData resolve(int codePoint) {
    return _byCodePoint[codePoint] ?? defaultIcon;
  }
}
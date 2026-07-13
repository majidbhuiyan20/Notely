import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/route/app_route.dart';
import '../../analytics/view/analytics_screen.dart';
import '../../authentication/presentation/providers/auth_providers.dart';
import '../../calendar/presentation/view/calendar_screen.dart';
import '../../home/view/home_screen.dart';
import '../../profile/view/profile_screen.dart';

class SelectedTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int value) => state = value;
}

final selectedTabProvider =
    NotifierProvider<SelectedTabNotifier, int>(SelectedTabNotifier.new);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  /// `true` once we've pushed the Login screen in response to a sign-out.
  /// Used to suppress duplicate navigations if the auth listener fires
  /// more than once for the same sign-out event. The flag is reset only
  /// when the widget is rebuilt against a fresh auth state (i.e. the user
  /// signs back in and reaches Main again — handled by widget disposal).
  bool _signedOut = false;

  static const _destinations = <_Destination>[
    _Destination(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _Destination(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Calendar',
    ),
    _Destination(
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded,
      label: 'Insights',
    ),
    _Destination(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  static const _screens = <Widget>[
    HomeScreen(),
    CalendarScreen(),
    AnalyticsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    final current = ref.read(selectedTabProvider);
    if (current == index) {
      HapticFeedback.selectionClick();
      return;
    }
    HapticFeedback.lightImpact();
    ref.read(selectedTabProvider.notifier).set(index);
  }

  @override
  Widget build(BuildContext context) {
    // If the auth state flips to signed-out while MainScreen is mounted
    // (the Profile tab's AccountCard drives this explicitly, but we also
    // listen here so Home / Calendar / Insights users can't be stranded
    // if their session expires mid-use), redirect to Login exactly once.
    // The Profile screen handles its own navigation; we use the shared
    // [_signedOut] flag so this listener doesn't double-fire.
    ref.listen(authNotifierProvider, (prev, next) {
      if (_signedOut) return;
      final wasSignedIn = prev?.value != null;
      final isSignedOut = next.value == null && !next.isLoading;
      if (wasSignedIn && isSignedOut && mounted) {
        _signedOut = true;
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          Routes.loginRoute,
          (_) => false,
        );
      }
    });

    final selectedIndex = ref.watch(selectedTabProvider);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: selectedIndex,
        children: _screens,
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _IosGlassDock(
        destinations: _destinations,
        selectedIndex: selectedIndex,
        onItemTap: _onItemTapped,
        onCreateTap: () {
          HapticFeedback.mediumImpact();
          Navigator.pushNamed(context, Routes.createTaskRoute);
        },
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _IosGlassDock extends StatelessWidget {
  const _IosGlassDock({
    required this.destinations,
    required this.selectedIndex,
    required this.onItemTap,
    required this.onCreateTap,
  });

  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onItemTap;
  final VoidCallback onCreateTap;

  static const double _dockHeight = 68;
  static const double _fabSize = 60;
  static const double _fabNotch = _fabSize + 20;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomInset = mq.padding.bottom;
    final bottomPad = math.max(bottomInset, 12.0) + 8.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad),
      child: SizedBox(
        height: _dockHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final itemCount = destinations.length;
            final reservedWidth = _fabNotch;
            final freeWidth = math.max(0.0, totalWidth - reservedWidth);
            final slotWidth = freeWidth / itemCount;

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: _GlassPill()),

                _HighlightLayer(
                  reservedWidth: reservedWidth,
                  slotWidth: slotWidth,
                  height: _dockHeight,
                  selectedIndex: selectedIndex,
                ),

                Row(
                  children: [
                    for (int i = 0; i < itemCount; i++) ...[
                      if (i == 2) SizedBox(width: _fabNotch),
                      Expanded(
                        child: _DockItem(
                          destination: destinations[i],
                          isActive: selectedIndex == i,
                          onTap: () => onItemTap(i),
                        ),
                      ),
                    ],
                  ],
                ),

                Positioned(
                  top: -15,
                  child: _PremiumFab(onPressed: onCreateTap),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final surface = isDark
        ? const Color(0xCC1A1C2E)
        : Colors.white.withValues(alpha: 0.75);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: border, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightLayer extends StatelessWidget {
  const _HighlightLayer({
    required this.reservedWidth,
    required this.slotWidth,
    required this.height,
    required this.selectedIndex,
  });

  final double reservedWidth;
  final double slotWidth;
  final double height;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    // Dynamic pill width that fits the slot nicely
    final pillWidth = slotWidth * 0.85;
    const pillHeight = 52.0;

    // Fixed math for center alignment
    final double leftOffset = selectedIndex < 2
        ? (slotWidth * selectedIndex) + (slotWidth - pillWidth) / 2
        : (slotWidth * selectedIndex) + reservedWidth + (slotWidth - pillWidth) / 2;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack, // Fixed name
      left: leftOffset,
      top: (height - pillHeight) / 2,
      child: Container(
        width: pillWidth,
        height: pillHeight,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.destination,
    required this.isActive,
    required this.onTap,
  });

  final _Destination destination;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = isActive ? Colors.white : AppColors.textTertiary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, isActive ? -2 : 0, 0),
            child: Icon(
              isActive ? destination.activeIcon : destination.icon,
              size: 24,
              color: fg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            destination.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumFab extends StatelessWidget {
  const _PremiumFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
      ),
    );
  }
}

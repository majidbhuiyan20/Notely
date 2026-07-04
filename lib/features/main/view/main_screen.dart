import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/route/app_route.dart';
import '../../calendar/presentation/view/calendar_screen.dart';
import '../../home/view/home_screen.dart';
import '../../profile/view/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    CalendarScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      HapticFeedback.lightImpact();
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.1).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.royalBlue.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 5,
              )
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pushNamed(context, Routes.createTaskRoute);
            },
            backgroundColor: AppColors.royalBlue,
            elevation: 8,
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 36),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        color: Colors.white,
        elevation: 15,
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_rounded, Icons.home_outlined, 0),
            _buildNavItem(
              Icons.calendar_month_rounded,
              Icons.calendar_month_outlined,
              1,
            ),
            const SizedBox(width: 50), // Gap for FAB
            // Right side of the FAB: only one slot remains for Profile,
            // but with 3 items + 1 spacer we use spaceAround to keep things
            // symmetric, so we add an empty leader here.
            const SizedBox(width: 36),
            _buildNavItem(Icons.person_rounded, Icons.person_outline_rounded, 2),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData selectedIcon, IconData unselectedIcon, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 400),
              scale: isSelected ? 1.25 : 1.0,
              curve: Curves.elasticOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                transform: Matrix4.translationValues(0, isSelected ? -8 : 0, 0),
                child: Icon(
                  isSelected ? selectedIcon : unselectedIcon,
                  color: isSelected ? AppColors.royalBlue : Colors.grey.shade400,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSelected ? 6 : 0,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.royalBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppColors.royalBlue.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 2,
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

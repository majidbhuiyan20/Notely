import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../widgets/back_button.dart';
import '../providers/calendar_providers.dart';
import '../widgets/day_task_list.dart';
import '../widgets/month_grid.dart';

const List<String> _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(visibleMonthProvider);
    final selected = ref.watch(selectedDateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const NotelyAppBar(title: 'Calendar'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _MonthHeader(
            month: visible,
            selected: selected,
            onPrev: () {
              ref.read(visibleMonthProvider.notifier).setMonth(
                  visible.year, visible.month - 1);
            },
            onNext: () {
              ref.read(visibleMonthProvider.notifier).setMonth(
                  visible.year, visible.month + 1);
            },
            onToday: () {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              ref.read(selectedDateProvider.notifier).select(today);
              ref.read(visibleMonthProvider.notifier).setMonth(
                  today.year, today.month);
            },
          ),
          const SizedBox(height: 12),
          const MonthGrid(),
          const SizedBox(height: 16),
          const DayTaskList(),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.selected,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  final DateTime month;
  final DateTime selected;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_monthNames[month.month - 1]} ${month.year}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1E1E),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Selected: ${_selectedLabel(selected)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _CircleNav(icon: Icons.chevron_left_rounded, onTap: onPrev),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onToday,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.royalBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _CircleNav(icon: Icons.chevron_right_rounded, onTap: onNext),
        ],
      ),
    );
  }

  String _selectedLabel(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _CircleNav extends StatelessWidget {
  const _CircleNav({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: const Color(0xFF1E1E1E)),
        ),
      ),
    );
  }
}
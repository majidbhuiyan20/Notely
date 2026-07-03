import 'package:flutter/material.dart';

/// Thin progress bar with a count badge used below the header.
class CategoryProgressBar extends StatelessWidget {
  const CategoryProgressBar({
    super.key,
    required this.progress,
    required this.color,
    required this.completed,
    required this.total,
  });

  final double progress;
  final Color color;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Progress',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1E1E1E),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$completed / $total tasks',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  color: const Color(0xFFE5E5EA),
                ),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 700),
                  widthFactor: progress.clamp(0.0, 1.0),
                  heightFactor: 1,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 0),
                      child: Text(
                        '$percent%',
                        style: TextStyle(
                          fontSize: 9,
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
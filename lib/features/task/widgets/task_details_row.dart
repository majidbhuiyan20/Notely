import 'package:flutter/material.dart';
class TaskDetailRow extends StatelessWidget {
  const TaskDetailRow({
    super.key, required this.title, required this.icon, required this.value,
  });
  final String title;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;
    switch (value) {
      case "High":
        indicatorColor = Colors.red;
        break;
      case "Medium":
        indicatorColor = Colors.orange;
        break;
      case "Low":
        indicatorColor = Colors.green;
        break;
      case "Completed":
        indicatorColor = Colors.green;
        break;
      default:
        indicatorColor = Colors.transparent;
    }

    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade500, size: 20),
        SizedBox(width: 6,),
        Text(title, style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w600), ),
        Spacer(),
        Row(
          children: [
            if (indicatorColor != Colors.transparent)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
            Text(value, style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w600), ),
          ],
        )
      ],
    );
  }
}
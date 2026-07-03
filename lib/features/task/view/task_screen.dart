import 'package:flutter/material.dart';
import '../widgets/check_list_item.dart';
import '../widgets/task_details_row.dart';
class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 16),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        actions: [
          Icon(Icons.edit),
          SizedBox(width: 12),
          Icon(Icons.more_vert_outlined),
          SizedBox(width: 16,),
        ],
      ),
      body: Column(
        spacing: 12,
        children: [
          SizedBox(height: 12,),
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Icon(Icons.person_outline, color: Colors.orange, size: 48),
            ),
          ),
          Text("Product RoadMap", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 6,),
                    Text("Personal", style: TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.w500), ),
                  ],
                ),
              ),
              SizedBox(width: 12,),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 10,
                      width: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6,),
                    Text("High", style: TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.w500), ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(12)),
                border: Border.all(color: Colors.black.withOpacity(0.1), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],

              ),
              child: Column(
                children: [
                  TaskDetailRow(title: 'Due Date', icon: Icons.calendar_month, value: 'Today, 10:00 AM',),
                  SizedBox(height: 12),
                  TaskDetailRow(title: 'Created', icon: Icons.timer, value: 'May 22, 2025 - 9.20 AM',),
                  SizedBox(height: 12),
                  TaskDetailRow(title: 'Priority', icon: Icons.priority_high, value: 'High',),
                  SizedBox(height: 12),
                  TaskDetailRow(title: 'Status', icon: Icons.check_circle_outline, value: 'Completed',),
                  SizedBox(height: 12),
                  TaskDetailRow(title: 'Assignee', icon: Icons.person_outline, value: 'John Doe',),
                  SizedBox(height: 12),
                  TaskDetailRow(title: 'Reminder', icon: Icons.notifications_active, value: "10 Min Before",),

                  SizedBox(height: 12),
                  Row(
                    children: [
                      Text("Checklist", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),),
                      Spacer(),
                      Text("2", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1B5E20)),),
                      Text("/4", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),)
                    ],
                  ),
                  SizedBox(height: 12),
                  ChecklistItem(title: "Define product vision", isChecked: true),
                  ChecklistItem(title: "Competitor analysis", isChecked: true),
                  ChecklistItem(title: "Feature prioritization", isChecked: false),
                  ChecklistItem(title: "Release schedule", isChecked: false),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}


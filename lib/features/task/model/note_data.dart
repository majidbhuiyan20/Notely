import 'package:flutter/material.dart';

enum NoteStatus { pending, completed }

enum NotePriority { high, medium, low }

class ChecklistItemModel {
  String id;
  String title;
  bool isChecked;

  ChecklistItemModel({
    required this.id,
    required this.title,
    this.isChecked = false,
  });
}

class NoteData {
  final String id;
  String title;
  String description;
  String category;
  Color categoryColor;
  IconData categoryIcon;
  NoteStatus status;
  NotePriority priority;
  String dueDate;
  String assignee;
  String reminder;
  final List<ChecklistItemModel> checklist;

  NoteData({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.categoryColor,
    required this.categoryIcon,
    this.status = NoteStatus.pending,
    this.priority = NotePriority.medium,
    this.dueDate = '',
    this.assignee = '',
    this.reminder = '',
    List<ChecklistItemModel>? checklist,
  }) : checklist = checklist ?? [];

  int get completedChecklist =>
      checklist.where((c) => c.isChecked).length;
  int get totalChecklist => checklist.length;
  double get checklistProgress =>
      totalChecklist == 0 ? 0 : completedChecklist / totalChecklist;

  NoteData copy() => NoteData(
        id: id,
        title: title,
        description: description,
        category: category,
        categoryColor: categoryColor,
        categoryIcon: categoryIcon,
        status: status,
        priority: priority,
        dueDate: dueDate,
        assignee: assignee,
        reminder: reminder,
        checklist: checklist
            .map((c) => ChecklistItemModel(
                id: c.id, title: c.title, isChecked: c.isChecked))
            .toList(),
      );
}
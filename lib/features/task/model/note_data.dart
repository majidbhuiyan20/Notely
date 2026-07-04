import 'package:flutter/material.dart';

enum NoteStatus { pending, completed }

enum NotePriority { high, medium, low }

class ChecklistItemModel {
  ChecklistItemModel({
    required this.id,
    required this.title,
    this.isChecked = false,
  });

  final String id;
  String title;
  bool isChecked;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isChecked': isChecked,
      };

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return ChecklistItemModel(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      isChecked: (json['isChecked'] as bool?) ?? false,
    );
  }

  ChecklistItemModel copy() => ChecklistItemModel(
        id: id,
        title: title,
        isChecked: isChecked,
      );
}

class NoteData {
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
    this.dueDateIso,
    List<ChecklistItemModel>? checklist,
  }) : checklist = checklist ?? [];

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

  /// ISO-8601 date (yyyy-MM-dd) used by the calendar feature to key notes
  /// by the day they're due. `null` when no due date is set; the existing
  /// free-form [dueDate] string is preserved for display.
  String? dueDateIso;

  final List<ChecklistItemModel> checklist;

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
        dueDateIso: dueDateIso,
        checklist:
            checklist.map((c) => c.copy()).toList(growable: false),
      );
}

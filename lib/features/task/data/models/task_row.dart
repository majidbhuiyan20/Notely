import 'dart:convert';

import 'package:flutter/material.dart';

import '../../model/note_data.dart';
import '../../../../core/constants/app_colors.dart';

/// Converts a [NoteData] into the flat `Map<String, Object?>` form used by
/// sqflite and Firestore. Color + Icon are stored as ints (Material code
/// points) so the row is portable to non-Flutter contexts.
class TaskRow {
  const TaskRow({
    required this.id,
    required this.uid,
    required this.title,
    required this.description,
    required this.category,
    required this.colorValue,
    required this.iconCodePoint,
    required this.statusIndex,
    required this.priorityIndex,
    required this.dueDate,
    required this.dueDateIso,
    required this.dueTime,
    required this.assignee,
    required this.reminder,
    required this.checklistJson,
    required this.isPinned,
    required this.isDirty,
    required this.updatedAt,
  });

  final String id;
  final String uid;
  final String title;
  final String description;
  final String category;
  final int colorValue;
  final int iconCodePoint;
  final int statusIndex;
  final int priorityIndex;
  final String dueDate;
  final String? dueDateIso;
  final String dueTime;
  final String assignee;
  final String reminder;
  final String checklistJson;
  final bool isPinned;

  /// `true` when this row has a local change that hasn't been pushed to
  /// Firestore yet. The sync manager drains dirty rows on reconnect.
  final bool isDirty;
  final int updatedAt;

  Map<String, Object?> toDb() => {
        'id': id,
        'uid': uid,
        'title': title,
        'description': description,
        'category': category,
        'color_value': colorValue,
        'icon_code_point': iconCodePoint,
        'status_index': statusIndex,
        'priority_index': priorityIndex,
        'due_date': dueDate,
        'due_date_iso': dueDateIso,
        'due_time': dueTime,
        'assignee': assignee,
        'reminder': reminder,
        'checklist_json': checklistJson,
        'is_pinned': isPinned ? 1 : 0,
        'is_dirty': isDirty ? 1 : 0,
        'updated_at': updatedAt,
      };

  factory TaskRow.fromDb(Map<String, Object?> row) {
    return TaskRow(
      id: row['id'] as String,
      uid: (row['uid'] as String?) ?? '',
      title: (row['title'] as String?) ?? '',
      description: (row['description'] as String?) ?? '',
      category: (row['category'] as String?) ?? '',
      colorValue: (row['color_value'] as int?) ?? AppColors.royalBlue.toARGB32(),
      iconCodePoint: (row['icon_code_point'] as int?) ??
          Icons.note_alt_outlined.codePoint,
      statusIndex: (row['status_index'] as int?) ?? 0,
      priorityIndex: (row['priority_index'] as int?) ?? 1,
      dueDate: (row['due_date'] as String?) ?? '',
      dueDateIso: row['due_date_iso'] as String?,
      dueTime: (row['due_time'] as String?) ?? '',
      assignee: (row['assignee'] as String?) ?? '',
      reminder: (row['reminder'] as String?) ?? '',
      checklistJson: (row['checklist_json'] as String?) ?? '[]',
      isPinned: ((row['is_pinned'] as int?) ?? 0) != 0,
      isDirty: ((row['is_dirty'] as int?) ?? 0) != 0,
      updatedAt: (row['updated_at'] as int?) ?? 0,
    );
  }

  NoteData toNote() {
    return NoteData(
      id: id,
      title: title,
      description: description,
      category: category,
      categoryColor: Color(colorValue),
      categoryIcon: IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
      status: NoteStatus.values[
          statusIndex.clamp(0, NoteStatus.values.length - 1)],
      priority: NotePriority.values[
          priorityIndex.clamp(0, NotePriority.values.length - 1)],
      dueDate: dueDate,
      dueDateIso: dueDateIso,
      dueTime: dueTime,
      assignee: assignee,
      reminder: reminder,
      isPinned: isPinned,
      checklist: _decodeChecklist(checklistJson),
    );
  }

  factory TaskRow.fromNote({
    required String uid,
    required NoteData note,
    int? updatedAt,
    bool isDirty = false,
  }) {
    return TaskRow(
      id: note.id,
      uid: uid,
      title: note.title,
      description: note.description,
      category: note.category,
      colorValue: note.categoryColor.toARGB32(),
      iconCodePoint: note.categoryIcon.codePoint,
      statusIndex: note.status.index,
      priorityIndex: note.priority.index,
      dueDate: note.dueDate,
      dueDateIso: note.dueDateIso,
      dueTime: note.dueTime,
      assignee: note.assignee,
      reminder: note.reminder,
      checklistJson: jsonEncode(
        note.checklist.map((c) => c.toJson()).toList(),
      ),
      isPinned: note.isPinned,
      isDirty: isDirty,
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  static List<ChecklistItemModel> _decodeChecklist(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(ChecklistItemModel.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

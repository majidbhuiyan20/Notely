import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/note_data.dart';
import '../models/task_row.dart';

/// Mirrors local task writes to Firestore under `users/{uid}/tasks/{id}`.
///
/// Every method is best-effort: network errors are logged and swallowed so
/// the local sqflite copy remains the source of truth even when offline.
class TaskRemoteDataSource {
  TaskRemoteDataSource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _tasks(String uid) =>
      _db.collection('users').doc(uid).collection('tasks');

  /// Pulls every task for [uid] from Firestore. Returns an empty list if
  /// the network is down or the user has no remote data yet.
  Future<List<TaskRow>> fetchAllForUser(String uid) async {
    try {
      final snap = await _tasks(uid).get();
      return snap.docs
          .map((d) => _rowFromDoc(d.id, d.data(), uid))
          .toList();
    } catch (e, st) {
      developer.log(
        'firestore fetch failed',
        name: 'Task',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  Future<void> upsert(String uid, NoteData note) async {
    try {
      await _tasks(uid).doc(note.id).set(_toDoc(note));
    } catch (e, st) {
      developer.log(
        'firestore upsert failed',
        name: 'Task',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> delete(String uid, String id) async {
    try {
      await _tasks(uid).doc(id).delete();
    } catch (e, st) {
      developer.log(
        'firestore delete failed',
        name: 'Task',
        error: e,
        stackTrace: st,
      );
    }
  }

  Map<String, dynamic> _toDoc(NoteData n) => {
        'id': n.id,
        'title': n.title,
        'description': n.description,
        'category': n.category,
        'colorValue': n.categoryColor.toARGB32(),
        'iconCodePoint': n.categoryIcon.codePoint,
        'statusIndex': n.status.index,
        'priorityIndex': n.priority.index,
        'dueDate': n.dueDate,
        'dueDateIso': n.dueDateIso,
        'assignee': n.assignee,
        'reminder': n.reminder,
        'checklist': n.checklist.map((c) => c.toJson()).toList(),
        'isPinned': n.isPinned,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  TaskRow _rowFromDoc(String id, Map<String, dynamic> data, String uid) {
    final checklist = (data['checklist'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ChecklistItemModel.fromJson)
        .toList();
    return TaskRow(
      id: id,
      uid: uid,
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      category: (data['category'] as String?) ?? '',
      colorValue: (data['colorValue'] as int?) ?? 0,
      iconCodePoint: (data['iconCodePoint'] as int?) ?? 0,
      statusIndex: (data['statusIndex'] as int?) ?? 0,
      priorityIndex: (data['priorityIndex'] as int?) ?? 1,
      dueDate: (data['dueDate'] as String?) ?? '',
      dueDateIso: data['dueDateIso'] as String?,
      assignee: (data['assignee'] as String?) ?? '',
      reminder: (data['reminder'] as String?) ?? '',
      checklistJson: jsonEncode(checklist),
      isPinned: (data['isPinned'] as bool?) ?? false,
      updatedAt: (data['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }
}
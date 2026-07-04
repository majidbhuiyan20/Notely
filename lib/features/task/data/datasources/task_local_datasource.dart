import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/task_row.dart';

/// Opens (and migrates) the per-app sqflite database used to cache tasks.
/// One single table `tasks` keyed by `(uid, id)` so users on the same
/// device with different accounts see different data.
class TaskLocalDataSource {
  TaskLocalDataSource({Database? dbOverride}) : _dbOverride = dbOverride;

  static const _dbName = 'notely.db';
  static const _table = 'tasks';
  static const _schemaVersion = 2;

  final Database? _dbOverride;
  Database? _db;

  Future<Database> _open() async {
    if (_dbOverride != null) return _dbOverride;
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    _db = await openDatabase(
      path,
      version: _schemaVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT NOT NULL,
            uid TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            category TEXT NOT NULL,
            color_value INTEGER NOT NULL,
            icon_code_point INTEGER NOT NULL,
            status_index INTEGER NOT NULL,
            priority_index INTEGER NOT NULL,
            due_date TEXT NOT NULL,
            due_date_iso TEXT,
            assignee TEXT NOT NULL,
            reminder TEXT NOT NULL,
            checklist_json TEXT NOT NULL,
            is_pinned INTEGER NOT NULL DEFAULT 0,
            updated_at INTEGER NOT NULL,
            PRIMARY KEY (uid, id)
          );
        ''');
        await db.execute(
          'CREATE INDEX idx_tasks_uid_due_iso '
          'ON $_table(uid, due_date_iso);',
        );
        await db.execute(
          'CREATE INDEX idx_tasks_uid_pinned '
          'ON $_table(uid, is_pinned);',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 → v2: add is_pinned column for the pin/unpin feature.
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_table ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0;',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_tasks_uid_pinned '
            'ON $_table(uid, is_pinned);',
          );
        }
      },
    );
    return _db!;
  }

  Future<List<TaskRow>> readAllForUser(String uid) async {
    final db = await _open();
    final rows = await db.query(
      _table,
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'updated_at DESC',
    );
    return rows.map(TaskRow.fromDb).toList();
  }

  Future<TaskRow?> readOne(String uid, String id) async {
    final db = await _open();
    final rows = await db.query(
      _table,
      where: 'uid = ? AND id = ?',
      whereArgs: [uid, id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TaskRow.fromDb(rows.first);
  }

  /// Insert or replace. Used for create + update.
  Future<void> upsert(TaskRow row) async {
    final db = await _open();
    await db.insert(
      _table,
      row.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String uid, String id) async {
    final db = await _open();
    await db.delete(
      _table,
      where: 'uid = ? AND id = ?',
      whereArgs: [uid, id],
    );
  }

  Future<void> deleteAllForUser(String uid) async {
    final db = await _open();
    await db.delete(_table, where: 'uid = ?', whereArgs: [uid]);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
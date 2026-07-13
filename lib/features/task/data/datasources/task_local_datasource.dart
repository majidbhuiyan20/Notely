import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/task_row.dart';

/// Tombstone row left behind when a user deletes a note offline. The
/// sync manager drains these on reconnect and removes them once the
/// remote delete succeeds.
class TaskTombstone {
  const TaskTombstone({
    required this.uid,
    required this.id,
    required this.deletedAt,
  });

  final String uid;
  final String id;
  final int deletedAt;
}

/// Opens (and migrates) the per-app sqflite database used to cache tasks.
/// One single table `tasks` keyed by `(uid, id)` so users on the same
/// device with different accounts see different data. Plus a small
/// `tasks_deleted` table for offline deletes that need replaying.
class TaskLocalDataSource {
  TaskLocalDataSource({Database? dbOverride}) : _dbOverride = dbOverride;

  static const _dbName = 'notely.db';
  static const _table = 'tasks';
  static const _tombstoneTable = 'tasks_deleted';
  static const _schemaVersion = 4;

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
        await _createTasksTable(db);
        await _createTombstonesTable(db);
        await _createIndexes(db);
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
        // v2 → v3: add due_time column for the calendar time-of-day feature.
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE $_table ADD COLUMN due_time TEXT NOT NULL DEFAULT \'\';',
          );
        }
        // v3 → v4: add is_dirty column + the tasks_deleted tombstone table.
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE $_table ADD COLUMN is_dirty INTEGER NOT NULL DEFAULT 0;',
          );
          await _createTombstonesTable(db);
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_tasks_uid_dirty '
            'ON $_table(uid, is_dirty) WHERE is_dirty = 1;',
          );
        }
      },
    );
    return _db!;
  }

  Future<void> _createTasksTable(Database db) async {
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
        due_time TEXT NOT NULL DEFAULT '',
        assignee TEXT NOT NULL,
        reminder TEXT NOT NULL,
        checklist_json TEXT NOT NULL,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        is_dirty INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (uid, id)
      );
    ''');
  }

  Future<void> _createTombstonesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_tombstoneTable (
        uid TEXT NOT NULL,
        id TEXT NOT NULL,
        deleted_at INTEGER NOT NULL,
        PRIMARY KEY (uid, id)
      );
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX idx_tasks_uid_due_iso '
      'ON $_table(uid, due_date_iso);',
    );
    await db.execute(
      'CREATE INDEX idx_tasks_uid_pinned '
      'ON $_table(uid, is_pinned);',
    );
    await db.execute(
      'CREATE INDEX idx_tasks_uid_dirty '
      'ON $_table(uid, is_dirty) WHERE is_dirty = 1;',
    );
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

  Future<List<TaskRow>> readDirtyForUser(String uid) async {
    final db = await _open();
    final rows = await db.query(
      _table,
      where: 'uid = ? AND is_dirty = 1',
      whereArgs: [uid],
      orderBy: 'updated_at ASC',
    );
    return rows.map(TaskRow.fromDb).toList();
  }

  Future<int> countDirtyForUser(String uid) async {
    final db = await _open();
    final res = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_table WHERE uid = ? AND is_dirty = 1',
      [uid],
    );
    return (res.first['c'] as int?) ?? 0;
  }

  Future<int> countTombstonesForUser(String uid) async {
    final db = await _open();
    final res = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_tombstoneTable WHERE uid = ?',
      [uid],
    );
    return (res.first['c'] as int?) ?? 0;
  }

  Future<List<TaskTombstone>> readTombstonesForUser(String uid) async {
    final db = await _open();
    final rows = await db.query(
      _tombstoneTable,
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'deleted_at ASC',
    );
    return rows
        .map(
          (r) => TaskTombstone(
            uid: r['uid'] as String,
            id: r['id'] as String,
            deletedAt: r['deleted_at'] as int,
          ),
        )
        .toList();
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

  /// Updates only the `is_dirty` column for an existing row. Called by
  /// the sync manager after a successful Firestore push so the row
  /// stops being considered "pending".
  Future<void> markClean(String uid, String id) async {
    final db = await _open();
    await db.update(
      _table,
      {'is_dirty': 0},
      where: 'uid = ? AND id = ?',
      whereArgs: [uid, id],
    );
  }

  /// Records a delete that hasn't yet been pushed to Firestore. The row
  /// is removed from the live [tasks] table but a tombstone is kept in
  /// [tasksDeleted] so the sync manager can replay the remote delete
  /// when connectivity returns.
  Future<void> markDeleted(String uid, String id) async {
    final db = await _open();
    await db.transaction((txn) async {
      await txn.delete(
        _table,
        where: 'uid = ? AND id = ?',
        whereArgs: [uid, id],
      );
      await txn.insert(
        _tombstoneTable,
        {
          'uid': uid,
          'id': id,
          'deleted_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> removeTombstone(String uid, String id) async {
    final db = await _open();
    await db.delete(
      _tombstoneTable,
      where: 'uid = ? AND id = ?',
      whereArgs: [uid, id],
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
    await db.transaction((txn) async {
      await txn.delete(_table, where: 'uid = ?', whereArgs: [uid]);
      await txn.delete(_tombstoneTable, where: 'uid = ?', whereArgs: [uid]);
    });
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

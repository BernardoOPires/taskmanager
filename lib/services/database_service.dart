import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  static const _dbName = 'tasks.db';
  static const _dbVersion = 5;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        priority TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        completed_at INTEGER,
        completed_by TEXT,
        photo_path TEXT,
        latitude REAL,
        longitude REAL,
        location_name TEXT,
        last_modified_at INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  Future<List<Task>> readAll() async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      orderBy: 'completed ASC, last_modified_at DESC',
    );
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<Task> createLocal(Task task) async {
    final db = await database;
    final map = task
        .copyWith(lastModifiedAt: DateTime.now(), isSynced: false)
        .toMap();

    map.remove('id');

    final id = await db.insert(
      'tasks',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return task.copyWith(id: id, isSynced: false);
  }

  Future<void> updateLocal(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> replaceLocalIdWithServerId(int oldId, int newId) async {
    final db = await database;

    await db.update(
      'tasks',
      {'id': newId, 'is_synced': 1},
      where: 'id = ?',
      whereArgs: [oldId],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.update(
      'sync_queue',
      {'task_id': newId},
      where: 'task_id = ?',
      whereArgs: [oldId],
    );
  }

  Future<void> deleteLocal(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> enqueue(String operation, Task task) async {
    final db = await database;

    await db.insert('sync_queue', {
      'task_id': task.id,
      'operation': operation,
      'payload': jsonEncode(task.toMap()),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getQueue() async {
    final db = await database;
    return db.query('sync_queue', orderBy: 'timestamp ASC');
  }

  Future<void> removeFromQueue(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markAsSynced(int id) async {
    final db = await database;

    await db.update(
      'tasks',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Task>> getTasksNearLocation({
    required double latitude,
    required double longitude,
    required double radiusInMeters,
  }) async {
    final db = await database;

    final latDelta = radiusInMeters / 111000.0;
    final lonDelta = radiusInMeters / 111000.0;

    final maps = await db.query(
      'tasks',
      where: 'latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?',
      whereArgs: [
        latitude - latDelta,
        latitude + latDelta,
        longitude - lonDelta,
        longitude + lonDelta,
      ],
    );

    return maps.map((m) => Task.fromMap(m)).toList();
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';
import '../models/schedule_model.dart';

class SqliteService {
  static final SqliteService _instance = SqliteService._internal();
  factory SqliteService() => _instance;
  static Database? _database;

  SqliteService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Quick fix for Web: Do not init DB, just throw/return to avoid crash
    if (kIsWeb) {
      throw Exception("SQLite is not supported on Web. Please use Android/Windows.");
    }
    
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Simplified for Android/iOS
    // If you need Windows support later, we can add it back once SSL issues are resolved.

    String path = join(await getDatabasesPath(), 'prepschedule_offline.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id TEXT PRIMARY KEY,
            username TEXT,
            password TEXT,
            email TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE schedules(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            remote_id TEXT,
            title TEXT,
            time TEXT,
            date TEXT,
            day TEXT,
            category TEXT,
            details TEXT,
            sync_status INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE schedules ADD COLUMN user_id TEXT');
        }
        if (oldVersion < 3) {
          // Recreate users table for TEXT ID
          await db.execute('DROP TABLE IF EXISTS users');
          await db.execute('''
            CREATE TABLE users(
              id TEXT PRIMARY KEY,
              username TEXT,
              password TEXT,
              email TEXT
            )
          ''');
        }
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE schedules ADD COLUMN remote_id TEXT');
          } catch (e) {
            print("Migration Error or Column Already Exists: $e");
          }
        }
      },
    );
  }

  Future<void> saveUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<User?> getUser(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByUsernameOrEmail(String identifier) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? OR email = ?',
      whereArgs: [identifier, identifier],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByUid(String uid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [uid],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Schedule CRUD
  Future<int> insertSchedule(ScheduleModel schedule) async {
    final db = await database;
    
    // If it has a remote_id, check for existing record to prevent duplicates
    if (schedule.remoteId != null) {
      final List<Map<String, dynamic>> existing = await db.query(
        'schedules',
        where: 'remote_id = ?',
        whereArgs: [schedule.remoteId],
      );
      
      if (existing.isNotEmpty) {
        // Update existing instead of inserting
        schedule.id = existing.first['id'];
        await db.update(
          'schedules',
          schedule.toMap(),
          where: 'id = ?',
          whereArgs: [schedule.id],
        );
        return schedule.id!;
      }
    }
    
    // Otherwise insert new
    int id = await db.insert('schedules', schedule.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    schedule.id = id;
    return id;
  }

  Future<List<ScheduleModel>> getAllSchedules(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'day ASC',
    );
    return List.generate(maps.length, (i) => ScheduleModel.fromMap(maps[i]));
  }

  Future<int> updateSchedule(ScheduleModel schedule) async {
    final db = await database;
    return await db.update(
      'schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> deleteSchedule(int id) async {
    final db = await database;
    return await db.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

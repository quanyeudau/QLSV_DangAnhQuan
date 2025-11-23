import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student.dart';

class StudentDb {
	StudentDb._();
	static final StudentDb instance = StudentDb._();
	Database? _db;

	Future<Database> get database async {
		if (_db != null) return _db!;
		_db = await _initDb();
		return _db!;
	}

	Future<Database> _initDb() async {
			final dbPath = await getDatabasesPath();
			final path = join(dbPath, 'students.db');
			// If DB file doesn't exist, try to copy a pre-populated DB from assets
			// (useful to ship initial data so other devices get the same content).
			// This only runs on non-web platforms.
			if (!kIsWeb) {
				final exists = await databaseExists(path);
				if (!exists) {
					try {
						// Attempt to load asset 'assets/students.db' and write to path.
						final data = await rootBundle.load('assets/students.db');
						final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
						final file = File(path);
						await file.create(recursive: true);
						await file.writeAsBytes(bytes, flush: true);
					} catch (e) {
						// asset not found or copy failed -> we'll let openDatabase create a fresh DB
						// You can place a pre-populated DB at assets/students.db to use this feature.
						debugPrint('No prepopulated DB copied: $e');
					}
				}
			}

			return await openDatabase(path, version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
	}

	Future<void> _onCreate(Database db, int version) async {
		await db.execute('''
			CREATE TABLE students(
				id TEXT PRIMARY KEY,
				name TEXT NOT NULL,
				score REAL NOT NULL,
				avatar_url TEXT
			)
		''');
	}

	Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
		if (oldVersion < 2) {
			// Add avatar_url column for new avatar feature
			await db.execute('ALTER TABLE students ADD COLUMN avatar_url TEXT');
		}
	}

	Future<List<Student>> getAllStudents() async {
		final db = await database;
		final maps = await db.query('students', orderBy: 'name ASC');
		return maps.map((m) => Student.fromMap(m)).toList();
	}

	Future<void> upsertStudent(Student student) async {
		final db = await database;
		await db.insert(
			'students',
			student.toMap(),
			conflictAlgorithm: ConflictAlgorithm.replace,
		);
	}

	Future<void> deleteStudent(String id) async {
		final db = await database;
		await db.delete('students', where: 'id = ?', whereArgs: [id]);
	}

	Future<void> updateStudentScore(String id, double newScore) async {
		final db = await database;
		await db.update(
			'students',
			{'score': newScore},
			where: 'id = ?',
			whereArgs: [id],
		);
	}

	/// Trả về đường dẫn file của database (useful for debugging)
	Future<String> getDbFilePath() async {
		final dbPath = await getDatabasesPath();
		return join(dbPath, 'students.db');
	}
}


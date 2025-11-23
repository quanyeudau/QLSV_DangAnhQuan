import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path/path.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../models/grade.dart';

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

			return await openDatabase(path, version: 4, onCreate: _onCreate, onUpgrade: _onUpgrade);
	}

	Future<void> _onCreate(Database db, int version) async {
		await db.execute('''
			CREATE TABLE students(
				id TEXT PRIMARY KEY,
				name TEXT NOT NULL,
				score REAL NOT NULL,
				avatar_url TEXT,
				email TEXT,
				phone TEXT,
				class_name TEXT,
				dob TEXT,
				address TEXT,
				status TEXT
			)
		''');

		// Courses table
		await db.execute('''
			CREATE TABLE courses(
				id TEXT PRIMARY KEY,
				name TEXT NOT NULL,
				credits INTEGER NOT NULL,
				instructor TEXT,
				schedule_code TEXT
			)
		''');

		// Grades / enrollments table
		await db.execute('''
			CREATE TABLE grades(
				student_id TEXT NOT NULL,
				course_id TEXT NOT NULL,
				midterm REAL,
				final REAL,
				total REAL,
				PRIMARY KEY(student_id, course_id),
				FOREIGN KEY(student_id) REFERENCES students(id) ON DELETE CASCADE,
				FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE CASCADE
			)
		''');
	}

	Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
		if (oldVersion < 2) {
			// Add avatar_url column for previous upgrade
			await db.execute('ALTER TABLE students ADD COLUMN avatar_url TEXT');
		}
		if (oldVersion < 3) {
			// Add new student info columns
			await db.execute('ALTER TABLE students ADD COLUMN email TEXT');
			await db.execute('ALTER TABLE students ADD COLUMN phone TEXT');
			await db.execute('ALTER TABLE students ADD COLUMN class_name TEXT');
			await db.execute('ALTER TABLE students ADD COLUMN dob TEXT');
			await db.execute('ALTER TABLE students ADD COLUMN address TEXT');
		}
		if (oldVersion < 4) {
			// Add status column and create courses/grades tables for version 4
			await db.execute('ALTER TABLE students ADD COLUMN status TEXT');
			await db.execute('''
				CREATE TABLE IF NOT EXISTS courses(
					id TEXT PRIMARY KEY,
					name TEXT NOT NULL,
					credits INTEGER NOT NULL,
					instructor TEXT,
					schedule_code TEXT
				)
			''');
			await db.execute('''
				CREATE TABLE IF NOT EXISTS grades(
					student_id TEXT NOT NULL,
					course_id TEXT NOT NULL,
					midterm REAL,
					final REAL,
					total REAL,
					PRIMARY KEY(student_id, course_id)
				)
			''');
		}
	}

	// Firestore helpers - only used on Android (per request)
	FirebaseFirestore get _firestore => FirebaseFirestore.instance;

	Future<void> _maybeSyncStudentToFirestore(Student student) async {
		if (!Platform.isAndroid) return;
		try {
			// ensure Firebase is initialized
			if (Firebase.apps.isEmpty) return;
			await _firestore.collection('students').doc(student.id).set(student.toMap());
		} catch (e) {
			debugPrint('Firestore sync student failed: $e');
		}
	}

	Future<void> _maybeDeleteStudentFromFirestore(String id) async {
		if (!Platform.isAndroid) return;
		try {
			if (Firebase.apps.isEmpty) return;
			await _firestore.collection('students').doc(id).delete();
		} catch (e) {
			debugPrint('Firestore delete student failed: $e');
		}
	}

	Future<void> _maybeSyncCourseToFirestore(Course c) async {
		if (!Platform.isAndroid) return;
		try {
			if (Firebase.apps.isEmpty) return;
			await _firestore.collection('courses').doc(c.id).set(c.toMap());
		} catch (e) {
			debugPrint('Firestore sync course failed: $e');
		}
	}

	Future<void> _maybeDeleteCourseFromFirestore(String id) async {
		if (!Platform.isAndroid) return;
		try {
			if (Firebase.apps.isEmpty) return;
			await _firestore.collection('courses').doc(id).delete();
		} catch (e) {
			debugPrint('Firestore delete course failed: $e');
		}
	}

	Future<void> _maybeSyncGradeToFirestore(Grade g) async {
		if (!Platform.isAndroid) return;
		try {
			if (Firebase.apps.isEmpty) return;
			await _firestore
				.collection('students')
				.doc(g.studentId)
				.collection('grades')
				.doc(g.courseId)
				.set(g.toMap());
		} catch (e) {
			debugPrint('Firestore sync grade failed: $e');
		}
	}

	Future<void> _maybeDeleteGradeFromFirestore(String studentId, String courseId) async {
		if (!Platform.isAndroid) return;
		try {
			if (Firebase.apps.isEmpty) return;
			await _firestore.collection('students').doc(studentId).collection('grades').doc(courseId).delete();
		} catch (e) {
			debugPrint('Firestore delete grade failed: $e');
		}
	}

	/* ----------------- Course CRUD ----------------- */

	Future<void> upsertCourse(Course c) async {
		final db = await database;
		await db.insert('courses', c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
		// sync to Firestore on Android
		await _maybeSyncCourseToFirestore(c);
	}

	Future<List<Course>> getAllCourses() async {
		final db = await database;
		final rows = await db.query('courses', orderBy: 'name ASC');
		return rows.map((r) => Course.fromMap(r)).toList();
	}

	Future<void> deleteCourse(String id) async {
		final db = await database;
		await db.delete('courses', where: 'id = ?', whereArgs: [id]);
		await _maybeDeleteCourseFromFirestore(id);
	}

	/* ----------------- Grades CRUD ----------------- */

	Future<void> upsertGrade(Grade g) async {
		final db = await database;
		await db.insert('grades', g.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
		await _maybeSyncGradeToFirestore(g);
	}

	Future<List<Grade>> getGradesForStudent(String studentId) async {
		final db = await database;
		final rows = await db.query('grades', where: 'student_id = ?', whereArgs: [studentId]);
		return rows.map((r) => Grade.fromMap(r)).toList();
	}

	Future<void> deleteGrade(String studentId, String courseId) async {
		final db = await database;
		await db.delete('grades', where: 'student_id = ? AND course_id = ?', whereArgs: [studentId, courseId]);
		await _maybeDeleteGradeFromFirestore(studentId, courseId);
	}

	/// Compute weighted average for a student's grade in a course.
	/// weights: {'mid':0.4, 'final':0.6} (should sum to 1.0)
	Future<double?> computeWeightedAverage(String studentId, String courseId, Map<String, double> weights) async {
		final db = await database;
		final rows = await db.query('grades', where: 'student_id = ? AND course_id = ?', whereArgs: [studentId, courseId]);
		if (rows.isEmpty) return null;
		final g = Grade.fromMap(rows.first);
		return g.computeWeighted(weights);
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
		await _maybeSyncStudentToFirestore(student);
	}

	Future<void> deleteStudent(String id) async {
		final db = await database;
		await db.delete('students', where: 'id = ?', whereArgs: [id]);
		await _maybeDeleteStudentFromFirestore(id);
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


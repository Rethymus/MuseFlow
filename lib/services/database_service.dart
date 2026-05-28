import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDatabase();
    return _database!;
  }

  Future<void> initialize() async {
    await database;
  }

  Future<Database> _initializeDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'museflow.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create structured data tables
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE note_tags (
        note_id TEXT NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (note_id, tag_id),
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        searched_at INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertTag(Map<String, dynamic> tag) async {
    final db = await database;
    return await db.insert('tags', tag);
  }

  Future<List<Map<String, dynamic>>> getAllTags() async {
    final db = await database;
    return await db.query('tags', orderBy: 'name');
  }

  Future<void> deleteTag(int tagId) async {
    final db = await database;
    await db.delete('tags', where: 'id = ?', whereArgs: [tagId]);
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
    }
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('srimanganti.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Naik ke versi 5: Paksa drop tabel biar kolom 'kewarganegaraan' kebuat
    return await openDatabase(
      path,
      version: 5, 
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS users');
        await db.execute('DROP TABLE IF EXISTS sesi');
        await db.execute('DROP TABLE IF EXISTS pagelaran_cache');
        await _createDB(db, newVersion);
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sesi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pagelaran_cache (
        id TEXT PRIMARY KEY,
        judul TEXT,
        hari TEXT,
        gambar_url TEXT,
        harga_wni INTEGER,
        harga_wna INTEGER
      )
    ''');

    // TAMBAHAN KOLOM KEWARGANEGARAAN
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE,
        password TEXT,
        nama_lengkap TEXT,
        no_whatsapp TEXT,
        kewarganegaraan TEXT
      )
    ''');
  }

  // ==========================================
  // FUNGSI SESI
  // ==========================================
  Future<void> simpanSesi(String email) async {
    final db = await database;
    await db.delete('sesi');
    await db.insert('sesi', {'email': email});
  }

  Future<String?> getSesi() async {
    final db = await database;
    final result = await db.query('sesi', limit: 1);
    if (result.isNotEmpty) {
      return result.first['email'] as String;
    }
    return null;
  }

  Future<void> hapusSesi() async {
    final db = await database;
    await db.delete('sesi');
  }

  // ==========================================
  // FUNGSI USER
  // ==========================================
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // ==========================================
  // FUNGSI CACHE PAGELARAN (OPSIONAL)
  // ==========================================
  Future<void> simpanCachePagelaran(List<Map<String, dynamic>> data) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('pagelaran_cache');
    for (var item in data) {
      batch.insert('pagelaran_cache', {
        'id': item['id'],
        'judul': item['judul'],
        'hari': item['hari'],
        'gambar_url': item['gambar_url'],
        'harga_wni': item['harga_wni'],
        'harga_wna': item['harga_wna'],
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachePagelaran() async {
    final db = await database;
    return await db.query('pagelaran_cache');
  }
}
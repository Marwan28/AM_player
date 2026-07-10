import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppStateRepository {
  static const _databaseName = 'am_player_app_state.db';
  static const _databaseVersion = 1;
  static const _homeTabKey = 'home_tab_index';

  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _databaseName);
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE app_state (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_ms INTEGER NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  Future<int> loadHomeTabIndex() async {
    final db = await _db;
    final rows = await db.query(
      'app_state',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_homeTabKey],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    final value = int.tryParse(rows.first['value'] as String? ?? '') ?? 0;
    if (value < 0 || value > 2) return 0;
    return value;
  }

  Future<void> saveHomeTabIndex(int index) async {
    if (index < 0 || index > 2) return;
    final db = await _db;
    await db.insert(
      'app_state',
      {
        'key': _homeTabKey,
        'value': '$index',
        'updated_ms': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

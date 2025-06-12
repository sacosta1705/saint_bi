// lib/services/database_service.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:saint_bi/models/permissions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:saint_bi/models/api_connection.dart';

class DatabaseService {
  static const String _databaseName = "saint_bi_connections.db";
  static const int _databaseVersion = 2;

  // --- Tabla de Conexiones ---
  static const String tableConnections = 'connections';
  static const String columnId = 'id';
  static const String columnBaseUrl = 'baseUrl';
  static const String columnUsername = 'username';
  static const String columnPassword = 'password';
  static const String columnPollingInterval = 'pollingIntervalSeconds';
  static const String columnCompanyName = 'companyName';
  static const String columnCompanyAlias = 'companyAlias';
  static const String columnTerminal = 'terminal';

  // --- Tabla de Configuración de la App ---
  static const String tableAppConfiguration = 'app_configuration';
  static const String columnConfigId = 'id';
  static const String columnAdminPasswordHash = 'admin_password_hash';
  static const String columnDefaultApiUser = 'default_api_user';
  static const String columnPermissions = 'permissions';

  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectoryPath = await getDatabasesPath();
    final path = join(documentsDirectoryPath, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableConnections (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnBaseUrl TEXT NOT NULL,
        $columnUsername TEXT NOT NULL,
        $columnPassword TEXT NOT NULL,
        $columnPollingInterval INTEGER NOT NULL,
        $columnCompanyName TEXT NOT NULL,
        $columnCompanyAlias TEXT NOT NULL UNIQUE,
        $columnTerminal TEXT NOT NULL,
        $columnPermissions TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableAppConfiguration (
        $columnConfigId INTEGER PRIMARY KEY DEFAULT 1 CHECK ($columnConfigId = 1),
        $columnAdminPasswordHash TEXT,
        $columnDefaultApiUser TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      final defaultPermissions = Permissions().toJson();
      await db.execute('''
        ALTER TABLE $tableConnections ADD COLUMN $columnPermissions TEXT NOT NULL DEFAULT '$defaultPermissions'
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS $tableConnections');
      await _onCreate(db, newVersion);
    }
  }

  Future<void> saveAppSettings(
      {String? adminPasswordHash, String? defaultApiUser}) async {
    final db = await instance.database;
    final currentSettings = await getAppSettings();

    final data = {
      columnConfigId: 1,
      columnAdminPasswordHash:
          adminPasswordHash ?? currentSettings[columnAdminPasswordHash],
      columnDefaultApiUser:
          defaultApiUser ?? currentSettings[columnDefaultApiUser],
    };

    await db.insert(
      tableAppConfiguration,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>> getAppSettings() async {
    final db = await instance.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableAppConfiguration,
        where: '$columnConfigId = ?',
        whereArgs: [1],
      );
      if (maps.isNotEmpty) {
        return maps.first;
      }
      // ignore: empty_catches
    } catch (e) {}
    return {};
  }

  Future<int> insertConnection(ApiConnection connection) async {
    final db = await instance.database;
    try {
      final id = await db.insert(
        tableConnections,
        connection.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      if (e.toString().toLowerCase().contains('unique constraint failed')) {
        throw Exception(
            'Ya existe una conexión guardada con el nombre de empresa "${connection.companyName}".');
      }
      rethrow;
    }
  }

  Future<List<ApiConnection>> getAllConnections() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query(tableConnections, orderBy: '$columnCompanyName ASC');
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => ApiConnection.fromMap(maps[i]));
  }

  Future<ApiConnection?> getConnectionByCompanyName(String companyName) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableConnections,
      where: '$columnCompanyName = ?',
      whereArgs: [companyName],
    );
    if (maps.isNotEmpty) return ApiConnection.fromMap(maps.first);
    return null;
  }

  Future<int> updateConnection(ApiConnection connection) async {
    final db = await instance.database;
    if (connection.id == null) return 0;
    try {
      final count = await db.update(
        tableConnections,
        connection.toMap(),
        where: '$columnId = ?',
        whereArgs: [connection.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return count;
    } catch (e) {
      if (e.toString().toLowerCase().contains('unique constraint failed')) {
        throw Exception(
            'Error al actualizar: Ya existe otra conexión con el nombre de empresa "${connection.companyName}".');
      }
      rethrow;
    }
  }

  Future<int> deleteConnection(int id) async {
    final db = await instance.database;
    return await db.delete(
      tableConnections,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<ApiConnection?> getConnectionByAlias(String alias) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableConnections,
      where: '$columnCompanyAlias = ?',
      whereArgs: [alias],
    );

    if (maps.isNotEmpty) return ApiConnection.fromMap(maps.first);
    return null;
  }
}

// lib/services/database_service.dart
import 'package:flutter/material.dart'; // Para debugPrint
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:saint_bi/models/api_connection.dart';

class DatabaseService {
  static const String _databaseName = "saint_bi_connections.db";
  static const int _databaseVersion = 1;

  static const String tableConnections = 'connections';
  static const String columnId = 'id';
  static const String columnBaseUrl = 'baseUrl';
  static const String columnUsername = 'username';
  static const String columnPassword = 'password';
  static const String columnPollingInterval = 'pollingIntervalSeconds';
  static const String columnCompanyName = 'companyName';
  static const String columnTerminal = 'terminal';

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
    debugPrint('Database path: $path');
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
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
        $columnCompanyName TEXT NOT NULL UNIQUE,
        $columnTerminal TEXT NOT NULL
      )
    ''');
    debugPrint('Table $tableConnections created');
  }

  Future<int> insertConnection(ApiConnection connection) async {
    final db = await instance.database;
    try {
      final id = await db.insert(
        tableConnections,
        connection.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint(
        'Connection inserted/replaced with id: $id, company: ${connection.companyName}',
      );
      return id;
    } catch (e) {
      debugPrint('Error inserting/replacing connection: $e');
      if (e.toString().toLowerCase().contains('unique constraint failed')) {
        throw Exception(
          'Ya existe una conexión guardada con el nombre de empresa "${connection.companyName}".',
        );
      }
      rethrow;
    }
  }

  Future<List<ApiConnection>> getAllConnections() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableConnections,
      orderBy: '$columnCompanyName ASC',
    );
    if (maps.isEmpty) {
      debugPrint('No connections found in DB.');
      return [];
    }
    final connections = List.generate(maps.length, (i) {
      return ApiConnection.fromMap(maps[i]);
    });
    debugPrint('Fetched ${connections.length} connections from DB.');
    return connections;
  }

  Future<ApiConnection?> getConnectionById(int id) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableConnections,
      where: '$columnId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ApiConnection.fromMap(maps.first);
    }
    debugPrint('Connection with id $id not found.');
    return null;
  }

  // MÉTODO AÑADIDO Y CORREGIDO
  Future<ApiConnection?> getConnectionByCompanyName(String companyName) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableConnections,
      where: '$columnCompanyName = ?',
      whereArgs: [
        companyName,
      ], // Asegurarse que el argumento se pasa como lista
    );
    if (maps.isNotEmpty) {
      return ApiConnection.fromMap(maps.first);
    }
    debugPrint('Connection with companyName "$companyName" not found in DB.');
    return null;
  }

  Future<int> updateConnection(ApiConnection connection) async {
    final db = await instance.database;
    if (connection.id == null) {
      debugPrint('Error: Attempted to update a connection with no ID.');
      return 0;
    }
    try {
      final count = await db.update(
        tableConnections,
        connection.toMap(),
        where: '$columnId = ?',
        whereArgs: [connection.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint(
        'Updated connection id: ${connection.id}, company: ${connection.companyName}, rows affected: $count',
      );
      return count;
    } catch (e) {
      debugPrint('Error updating connection: $e');
      if (e.toString().toLowerCase().contains('unique constraint failed')) {
        throw Exception(
          'Error al actualizar: Ya existe otra conexión con el nombre de empresa "${connection.companyName}".',
        );
      }
      rethrow;
    }
  }

  Future<int> deleteConnection(int id) async {
    final db = await instance.database;
    final count = await db.delete(
      tableConnections,
      where: '$columnId = ?',
      whereArgs: [id],
    );
    debugPrint('Deleted connection id: $id, rows affected: $count');
    return count;
  }

  Future<void> deleteAllConnections() async {
    final db = await instance.database;
    await db.delete(tableConnections);
    debugPrint('All connections deleted.');
  }
}

// lib/services/database_service.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:saint_bi/models/api_connection.dart';

class DatabaseService {
  static const String _databaseName = "saint_bi_connections.db";
  static const int _databaseVersion = 1; // Incrementar si cambias el esquema

  // --- Definición de la tabla y columnas ---
  static const String tableConnections = 'connections';
  static const String columnId = 'id';
  static const String columnBaseUrl = 'baseUrl';
  static const String columnUsername = 'username';
  static const String columnPassword = 'password';
  static const String columnPollingInterval = 'pollingIntervalSeconds';
  static const String columnCompanyName = 'companyName';
  static const String columnTerminal = 'terminal';

  // Singleton para la instancia de la base de datos
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
      // onUpgrade: _onUpgrade, // Implementar si necesitas migraciones
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableConnections (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnBaseUrl TEXT NOT NULL,
        $columnUsername TEXT NOT NULL,
        $columnPassword TEXT NOT NULL, -- Considerar encriptación para producción
        $columnPollingInterval INTEGER NOT NULL,
        $columnCompanyName TEXT NOT NULL UNIQUE, -- El nombre de la empresa debe ser único
        $columnTerminal TEXT NOT NULL
      )
    ''');
    debugPrint('Table $tableConnections created');
  }

  // --- Operaciones CRUD ---

  Future<int> insertConnection(ApiConnection connection) async {
    final db = await instance.database;
    try {
      final id = await db.insert(
        tableConnections,
        connection.toMap(),
        conflictAlgorithm: ConflictAlgorithm
            .replace, // O .fail para lanzar error si companyName es duplicado
      );
      debugPrint(
        'Connection inserted with id: $id, company: ${connection.companyName}',
      );
      return id;
    } catch (e) {
      debugPrint('Error inserting connection: $e');
      if (e.toString().toLowerCase().contains('unique constraint failed')) {
        // Personaliza el mensaje si es una violación de unicidad
        throw Exception(
          'Ya existe una conexión guardada con el nombre de empresa "${connection.companyName}".',
        );
      }
      rethrow; // Relanzar otras excepciones
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

  Future<int> updateConnection(ApiConnection connection) async {
    final db = await instance.database;
    // Asegúrate que el ID no sea nulo para la actualización
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
    // Útil para desarrollo/pruebas
    final db = await instance.database;
    await db.delete(tableConnections);
    debugPrint('All connections deleted.');
  }
}

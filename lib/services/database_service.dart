// lib/services/database_service.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:saint_intelligence/models/api_connection.dart';

class DatabaseService {
  static const String _databaseName = "saint.db";
  // PASO 1: Incrementar la versión para forzar la actualización
  static const int _databaseVersion = 1;

  // --- Tabla de Conexiones ---
  static const String tableConnections = 'connections';
  static const String columnConnId = 'id';
  static const String columnBaseUrl = 'baseUrl';
  static const String columnUsername = 'username';
  static const String columnPassword = 'password';
  static const String columnPollingInterval = 'pollingIntervalSeconds';
  static const String columnCompanyName = 'companyName';
  static const String columnCompanyAlias = 'companyAlias';
  static const String columnTerminal = 'terminal';
  static const String columnPermissions = 'permissions';
  static const String columnConnConfigId = 'configId';

  // --- Tabla de Configuración de la App ---
  static const String tableAppConfiguration = 'app_configuration';
  static const String columnAppConfigId = 'id';
  static const String columnAdminPasswordHash = 'admin_password_hash';
  static const String columnDefaultApiUser = 'default_api_user';

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
      onUpgrade: _onUpgrade, // Asegurarse de que onUpgrade está activo
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Se ejecuta solo cuando la BD se crea por primera vez
    await _createConnectionsTable(db);
    await _createAppConfigTable(db);
  }

  // Lógica de migración para actualizar la BD sin perder datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // El esquema para app_configuration era incorrecto en la versión 1.
      // La solución más segura es eliminarla y volverla a crear con la estructura correcta.
      await db.execute('DROP TABLE IF EXISTS $tableAppConfiguration');
      await _createAppConfigTable(db);

      // Para la tabla de conexiones, intentamos preservar los datos añadiendo las columnas que falten
      try {
        await db.execute(
            'ALTER TABLE $tableConnections ADD COLUMN $columnPermissions TEXT NOT NULL DEFAULT \'{"canViewSales":true}\'');
      } catch (e) {/* La columna ya existe, no hacer nada */}

      try {
        await db.execute(
            'ALTER TABLE $tableConnections ADD COLUMN $columnConnConfigId INTEGER NOT NULL DEFAULT 1');
      } catch (e) {/* La columna ya existe, no hacer nada */}
    }
  }

  Future<void> _createConnectionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableConnections (
        $columnConnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnBaseUrl TEXT NOT NULL,
        $columnUsername TEXT NOT NULL,
        $columnPassword TEXT NOT NULL,
        $columnPollingInterval INTEGER NOT NULL,
        $columnCompanyName TEXT NOT NULL,
        $columnCompanyAlias TEXT NOT NULL UNIQUE,
        $columnTerminal TEXT NOT NULL,
        $columnPermissions TEXT NOT NULL,
        $columnConnConfigId INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Future<void> _createAppConfigTable(Database db) async {
    // CORRECCIÓN AQUÍ: Usar la constante correcta para la columna primaria ('id')
    await db.execute('''
      CREATE TABLE $tableAppConfiguration (
        $columnAppConfigId INTEGER PRIMARY KEY DEFAULT 1 CHECK ($columnAppConfigId = 1),
        $columnAdminPasswordHash TEXT,
        $columnDefaultApiUser TEXT
      )
    ''');
  }

  Future<void> saveAppSettings(
      {String? adminPasswordHash, String? defaultApiUser}) async {
    final db = await instance.database;
    final currentSettings = await getAppSettings();

    final data = {
      columnAppConfigId: 1, // Correcto
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
        where: '$columnAppConfigId = ?', // Correcto
        whereArgs: [1],
      );
      if (maps.isNotEmpty) {
        return maps.first;
      }
    } catch (e) {
      print("Error al obtener la configuración de la app: $e");
    }
    return {};
  }

  // --- El resto de los métodos para 'connections' permanecen igual ---

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
            'Ya existe una conexión guardada con el alias "${connection.companyAlias}".');
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
        where: '$columnConnId = ?',
        whereArgs: [connection.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return count;
    } catch (e) {
      if (e.toString().toLowerCase().contains('unique constraint failed')) {
        throw Exception(
            'Error al actualizar: Ya existe otra conexión con el alias "${connection.companyAlias}".');
      }
      rethrow;
    }
  }

  Future<int> deleteConnection(int id) async {
    final db = await instance.database;
    return await db.delete(
      tableConnections,
      where: '$columnConnId = ?',
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

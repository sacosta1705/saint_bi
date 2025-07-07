import 'package:flutter/material.dart';

import 'package:saint_intelligence/models/api_connection.dart';
import 'package:saint_intelligence/services/database_service.dart';

class ConnectionNotifier extends ChangeNotifier {
  final DatabaseService _dbService;
  ConnectionNotifier(this._dbService);

  List<ApiConnection> _availableConnections = [];
  ApiConnection? _activeConnection;
  bool _isLoading = false;
  String? _errorMsg;

  List<ApiConnection> get availableConnections => _availableConnections;
  ApiConnection? get activeConnection => _activeConnection;
  bool get isLoading => _isLoading;
  String? get errorMsg => _errorMsg;

  Future<void> loadConnections() async {
    _isLoading = true;
    notifyListeners();

    try {
      _availableConnections = await _dbService.getAllConnections();
      _availableConnections.sort((a, b) =>
          a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()));

      if (_availableConnections.isNotEmpty && _activeConnection == null) {}
    } catch (e) {
      _errorMsg = 'Error critico al cargar las conexiones: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setActiveConnection(ApiConnection? conn) {
    if (_activeConnection?.id != conn?.id) {
      _activeConnection = conn;
      notifyListeners();
    }
  }

  Future<void> addConnection(ApiConnection conn) async {
    final newId = await _dbService.insertConnection(conn);
    final newConn = conn.copyWith(id: newId);
    _availableConnections.add(newConn);
    _availableConnections.sort((a, b) =>
        a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()));
    notifyListeners();
  }

  Future<void> updateConnection(ApiConnection conn) async {
    await _dbService.updateConnection(conn);
    final index = _availableConnections.indexWhere((c) => c.id == conn.id);
    if (index != -1) {
      _availableConnections[index] = conn;
      if (_activeConnection?.id == conn.id) {
        _activeConnection = conn;
      }
      notifyListeners();
    }
  }

  Future<void> deleteConnection(int connId) async {
    await _dbService.deleteConnection(connId);
    _availableConnections.removeWhere((c) => c.id == connId);
    if (_activeConnection?.id == connId) {
      _activeConnection = null;
    }
    notifyListeners();
  }
}

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:saint_intelligence/models/purchase_item.dart';

import 'package:saint_intelligence/services/saint_api.dart';
import 'package:saint_intelligence/services/saint_api_exceptions.dart';
import 'package:saint_intelligence/services/database_service.dart';
import 'package:saint_intelligence/models/api_connection.dart';
import 'package:saint_intelligence/models/login_response.dart';

// --- Importaciones para el Resumen Gerencial ---
import 'package:saint_intelligence/services/summary_calculator_service.dart';
import 'package:saint_intelligence/models/management_summary.dart';
import 'package:saint_intelligence/models/invoice.dart';
import 'package:saint_intelligence/models/invoice_item.dart';
import 'package:saint_intelligence/models/product.dart';
import 'package:saint_intelligence/models/account_receivable.dart';
import 'package:saint_intelligence/models/account_payable.dart';
import 'package:saint_intelligence/models/purchase.dart';
import 'package:saint_intelligence/models/inventory_operation.dart';
import 'package:saint_intelligence/models/configuration.dart';

// Constantes de mensajes para la UI
const String _uiAuthErrorMessage =
    'Error de autenticación. Revise credenciales o URL.';
const String _uiSessionExpiredMessage =
    'Sesión expirada. Intentando re-autenticar...';
const String _uiGenericErrorMessage = 'Error al comunicarse con el servidor.';
const String _uiNetworkErrorMessage =
    'Error de red. Verifique su conexión a internet.';
const String _uiNoConnectionSelectedMessage =
    'Seleccione o configure una conexión de empresa.';
const String _uiNoConnectionsAvailableMessage =
    'No hay conexiones configuradas. Por favor, añada una.';

class ManagementSummaryNotifier extends ChangeNotifier {
  final SaintApi _api = SaintApi();
  final ManagementSummaryCalculator _summaryCalculator =
      ManagementSummaryCalculator();
  final DatabaseService _dbService = DatabaseService.instance;

  List<Invoice> allInvoices = [];
  List<InvoiceItem> allInvoiceItems = [];
  List<Product> allProducts = [];
  List<AccountReceivable> allReceivables = [];
  List<Purchase> allPurchases = [];
  List<PurchaseItem> allPurchaseItems = [];
  List<AccountPayable> allPayables = [];
  List<InventoryOperation> allInventoryOps = [];

  // --- Estado unificado para el Resumen Gerencial ---
  ManagementSummary _summary = ManagementSummary();
  bool _isLoading = false;
  String? _errorMsg;
  String? _authtoken;
  Timer? _timer;
  bool _isReAuthenticating = false;

  DateTime? _startDate;
  DateTime? _endDate;

  ApiConnection? _activeConnection;
  List<ApiConnection> _availableConnections = [];

  // Getters actualizados
  ManagementSummary get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMsg => _errorMsg;
  bool get isAuthenticated => _authtoken != null && _authtoken!.isNotEmpty;
  int get pollingIntervalSeconds =>
      _activeConnection?.pollingIntervalSeconds ?? 9999999;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  ApiConnection? get activeConnection => _activeConnection;
  List<ApiConnection> get availableConnections => _availableConnections;

  ManagementSummaryNotifier() {
    _initializeDefaultDateRange();
    refreshAvailableConnections();
  }

  void _initializeDefaultDateRange() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate =
        DateTime(now.year, now.month + 1, 0); // Último día del mes actual
  }

  Future<void> refreshAvailableConnections({
    ApiConnection? newlySelectedFromSettings,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _availableConnections = await _dbService.getAllConnections();
      _availableConnections.sort(
        (a, b) =>
            a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()),
      );

      if (_availableConnections.isEmpty) {
        _errorMsg = _uiNoConnectionsAvailableMessage;
        clearActiveConnectionAndData(notify: false);
      } else if (newlySelectedFromSettings != null) {
        final found = _availableConnections.firstWhere(
          (c) => c.id == newlySelectedFromSettings.id,
          orElse: () => _availableConnections.first,
        );
        await setActiveConnection(found,
            fetchFullData: true, isInitialLoad: true);
      } else if (_activeConnection != null) {
        final currentActiveStillExists = _availableConnections.any(
          (c) => c.id == _activeConnection!.id,
        );
        if (!currentActiveStillExists) {
          clearActiveConnectionAndData(notify: false);
          _errorMsg = _uiNoConnectionSelectedMessage;
        } else {
          if (_errorMsg == _uiNoConnectionSelectedMessage ||
              _errorMsg == _uiNoConnectionsAvailableMessage) {
            _errorMsg = null;
          }
        }
      } else {
        _errorMsg = _uiNoConnectionSelectedMessage;
      }
    } catch (e) {
      _errorMsg =
          "Error crítico al cargar lista de conexiones: ${e.toString()}";
      clearActiveConnectionAndData(notify: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addConnectionToList(ApiConnection connection) {
    if (!_availableConnections.any((c) => c.id == connection.id)) {
      _availableConnections.add(connection);
      _availableConnections.sort((a, b) =>
          a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()));
      notifyListeners();
    }
  }

  void updateConnectionInList(ApiConnection connection) {
    final index =
        _availableConnections.indexWhere((c) => c.id == connection.id);
    if (index != -1) {
      _availableConnections[index] = connection;
      _availableConnections.sort((a, b) =>
          a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()));
      if (_activeConnection?.id == connection.id) {
        _activeConnection = connection;
      }
      notifyListeners();
    }
  }

  void removeConnectionFromList(int connectionId) {
    _availableConnections.removeWhere((c) => c.id == connectionId);
    if (_activeConnection?.id == connectionId) {
      clearActiveConnectionAndData();
      if (_availableConnections.isEmpty) {
        _errorMsg = _uiNoConnectionsAvailableMessage;
      } else {
        _errorMsg = 'Conexión activa eliminada. Por favor, seleccione otra.';
      }
    } else if (_availableConnections.isEmpty) {
      _errorMsg = _uiNoConnectionsAvailableMessage;
      clearActiveConnectionAndData();
    }
    notifyListeners();
  }

  Future<void> setActiveConnection(
    ApiConnection? connection, {
    bool fetchFullData = true,
    bool isInitialLoad = false,
  }) async {
    if (connection == null) {
      clearActiveConnectionAndData();
      return;
    }

    if (_activeConnection?.id == connection.id &&
        !fetchFullData &&
        !isInitialLoad) {
      if (_errorMsg == _uiNoConnectionSelectedMessage ||
          _errorMsg == _uiNoConnectionsAvailableMessage) {
        _errorMsg = null;
      }
      notifyListeners();
      return;
    }

    _activeConnection = connection;
    _authtoken = null;
    _summary = ManagementSummary();
    _errorMsg = null;
    _isLoading = fetchFullData;
    _isReAuthenticating = false;
    _stopPolling();

    notifyListeners();

    if (fetchFullData) {
      await fetchInitialData();
    }
  }

  void clearActiveConnectionAndData({bool notify = true}) {
    _activeConnection = null;
    _authtoken = null;
    _summary = ManagementSummary();
    _errorMsg = _availableConnections.isEmpty
        ? _uiNoConnectionsAvailableMessage
        : _uiNoConnectionSelectedMessage;
    _isLoading = false;
    _isReAuthenticating = false;
    _stopPolling();
    _initializeDefaultDateRange();
    if (notify) notifyListeners();
  }

  void _handleError(
    String message, {
    bool isAuthenticationIssue = false,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _errorMsg = message;
    if (isAuthenticationIssue) {
      _authtoken = null;
    }
    _isLoading = false;
    _isReAuthenticating = false;
    notifyListeners();
  }

  Future<void> filterByDateRange(DateTime? start, DateTime? end) async {
    if (_activeConnection == null) {
      _handleError(_uiNoConnectionSelectedMessage);
      return;
    }
    if (start != null && end != null && end.isBefore(start)) {
      _errorMsg = "La fecha final no puede ser anterior a la fecha de inicio.";
      _isLoading = false;
      notifyListeners();
      return;
    }

    _startDate = start;
    _endDate = end;
    _isLoading = true;
    _errorMsg = null;
    _summary = ManagementSummary();
    _stopPolling();
    notifyListeners();

    if (!isAuthenticated) {
      await fetchInitialData();
    } else {
      await _fetchSummaryData(isInitialFetchForCurrentOp: true);
      if (isAuthenticated && _errorMsg == null) {
        _startPollingInvoices();
      }
    }
  }

  Future<void> fetchInitialData() async {
    if (_activeConnection == null) {
      _handleError(_uiNoConnectionSelectedMessage);
      if (_isLoading) _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    if (!_isReAuthenticating) {
      _errorMsg = null;
      _authtoken = null;
      _summary = ManagementSummary();
      _stopPolling();
    }
    notifyListeners();

    try {
      final LoginResponse? loginResponse = await _api.login(
        baseurl: _activeConnection!.baseUrl,
        username: _activeConnection!.username,
        password: _activeConnection!.password,
        terminal: _activeConnection!.terminal,
      );

      if (loginResponse == null ||
          loginResponse.authToken == null ||
          loginResponse.authToken!.isEmpty) {
        throw AuthenticationException(
            "Login falló o no se recibió token/datos de empresa válidos.");
      }

      _authtoken = loginResponse.authToken;
      if (loginResponse.company != _activeConnection!.companyName) {
        _activeConnection =
            _activeConnection!.copyWith(companyName: loginResponse.company);
        await _dbService.updateConnection(_activeConnection!);
        final currentSelectedId = _activeConnection!.id;
        _availableConnections = await _dbService.getAllConnections();
        _availableConnections.sort((a, b) =>
            a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()));
        _activeConnection = _availableConnections.firstWhere(
            (c) => c.id == currentSelectedId,
            orElse: () => _activeConnection!);
      }

      _isReAuthenticating = false;

      if (isAuthenticated) {
        _errorMsg = null;
        await _fetchSummaryData(isInitialFetchForCurrentOp: true);

        if (_errorMsg == null) {
          _startPollingInvoices();
        } else {
          _stopPolling();
        }
      } else {
        _handleError(_uiAuthErrorMessage,
            isAuthenticationIssue: true,
            error: "Token inválido post-procesamiento de login.");
        _stopPolling();
      }
    } on AuthenticationException catch (e, stackTrace) {
      developer.log(e.toString());
      developer.log(stackTrace.toString());
      _handleError(_uiAuthErrorMessage,
          isAuthenticationIssue: true, error: e, stackTrace: stackTrace);
      _stopPolling();
    } on NetworkException catch (e, stackTrace) {
      developer.log(e.toString());
      developer.log(stackTrace.toString());
      _handleError(_uiNetworkErrorMessage, error: e, stackTrace: stackTrace);
    } on UnknownApiExpection catch (e, stackTrace) {
      developer.log(e.toString());
      developer.log(stackTrace.toString());
      _handleError(_uiGenericErrorMessage, error: e, stackTrace: stackTrace);
      _stopPolling();
    } catch (e, stackTrace) {
      developer.log(e.toString());
      developer.log(stackTrace.toString());
      _handleError(_uiGenericErrorMessage, error: e, stackTrace: stackTrace);
    } finally {
      if (_isLoading &&
          (_errorMsg != _uiSessionExpiredMessage || !_isReAuthenticating)) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> _fetchSummaryData({
    bool isInitialFetchForCurrentOp = false,
  }) async {
    if (_activeConnection == null || !isAuthenticated) {
      _handleError('No autenticado.',
          isAuthenticationIssue: true,
          error: "Fetch abortado: Sin conexión o token.");
      if (isInitialFetchForCurrentOp) _isLoading = false;
      notifyListeners();
      return;
    }

    if (!isInitialFetchForCurrentOp && _errorMsg != _uiSessionExpiredMessage) {
      _isLoading = true;
      if (_errorMsg != null && _errorMsg != _uiSessionExpiredMessage) {
        _errorMsg = null;
      }
      notifyListeners();
    }

    try {
      Map<String, String>? dateParams;
      if (_startDate != null && _endDate != null) {
        final adjustedStartDate = _startDate!.subtract(const Duration(days: 1));
        final adjustedEndDate = _endDate!.add(const Duration(days: 1));

        dateParams = {
          'fechae>': adjustedStartDate.toIso8601String().substring(0, 10),
          'fechae<': adjustedEndDate.toIso8601String().substring(0, 10),
        };
      }

      // Se aplican los dateParams solo a los endpoints que los soportan.
      final results = await Future.wait([
        // Endpoints transaccionales CON filtro de fecha
        _api.getInvoices(
            baseUrl: _activeConnection!.baseUrl,
            authtoken: _authtoken!,
            params: dateParams),
        _api.getInvoiceItems(
            baseUrl: _activeConnection!.baseUrl,
            authtoken: _authtoken!,
            params: dateParams),
        _api.getPurchases(
            baseUrl: _activeConnection!.baseUrl,
            authtoken: _authtoken!,
            params: dateParams),
        _api.getPurchaseItems(
          baseUrl: _activeConnection!.baseUrl,
          authtoken: _authtoken!,
          params: dateParams,
        ),

        // Endpoints de estado/maestros SIN filtro de fecha
        _api.getInventoryOperations(
            baseUrl: _activeConnection!.baseUrl, authtoken: _authtoken!),
        _api.getProducts(
            baseUrl: _activeConnection!.baseUrl, authtoken: _authtoken!),
        _api.getAccountsReceivable(
            baseUrl: _activeConnection!.baseUrl, authtoken: _authtoken!),
        _api.getAccountsPayable(
            baseUrl: _activeConnection!.baseUrl, authtoken: _authtoken!),
        _api.getConfiguration(
          id: _activeConnection!.configId,
          baseUrl: _activeConnection!.baseUrl,
          authtoken: _authtoken!,
        ),
      ]);

      allInvoices = List.from(results[0])
          .map<Invoice>((e) => Invoice.fromJson(e))
          .toList();
      allInvoiceItems = List.from(results[1])
          .map<InvoiceItem>((e) => InvoiceItem.fromJson(e))
          .toList();
      allPurchases = List.from(results[2])
          .map<Purchase>((e) => Purchase.fromJson(e))
          .toList();
      allPurchaseItems = List.from(results[3])
          .map<PurchaseItem>((e) => PurchaseItem.fromJson(e))
          .toList();
      allInventoryOps = List.from(results[4])
          .map<InventoryOperation>((e) => InventoryOperation.fromJson(e))
          .toList();
      allProducts = List.from(results[5])
          .map<Product>((e) => Product.fromJson(e))
          .toList();
      allReceivables = List.from(results[6])
          .map<AccountReceivable>((e) => AccountReceivable.fromJson(e))
          .toList();
      allPayables = List.from(results[7])
          .map<AccountPayable>((e) => AccountPayable.fromJson(e))
          .toList();

      final configResult = results[8];
      Configuration config;

      if (configResult is Map<String, dynamic>) {
        config = Configuration.fromJson(configResult);
      } else if (configResult is List && configResult.isNotEmpty) {
        config = Configuration.fromJson(configResult.first);
      } else {
        config = Configuration(monthlyBudget: 0.0);
      }

      _summary = _summaryCalculator.calculate(
        invoices: allInvoices,
        invoiceItems: allInvoiceItems,
        products: allProducts,
        receivables: allReceivables,
        payables: allPayables,
        purchases: allPurchases,
        inventoryOps: allInventoryOps,
        purchaseItems: allPurchaseItems,
        monthlyBudget: config.monthlyBudget,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (_errorMsg != _uiSessionExpiredMessage) _errorMsg = null;
      _isReAuthenticating = false;
    } on SessionExpiredException catch (e, stackTrace) {
      if (_isReAuthenticating) {
        _handleError(_uiAuthErrorMessage,
            isAuthenticationIssue: true, error: e, stackTrace: stackTrace);
        _stopPolling();
        return;
      }
      _errorMsg = _uiSessionExpiredMessage;
      _authtoken = null;
      _isReAuthenticating = true;
      notifyListeners();
      _stopPolling();
      await Future.delayed(const Duration(seconds: 1));
      await fetchInitialData();
      return;
    } on AuthenticationException catch (e, stackTrace) {
      developer.log(e.toString());
      developer.log(stackTrace.toString());
      _handleError(_uiAuthErrorMessage,
          isAuthenticationIssue: true, error: e, stackTrace: stackTrace);
      _stopPolling();
    } on NetworkException catch (e, stackTrace) {
      developer.log(e.toString());
      developer.log(stackTrace.toString());
      _handleError(_uiNetworkErrorMessage, error: e, stackTrace: stackTrace);
    } on UnknownApiExpection catch (e, stackTrace) {
      developer.log(e.toString());
      developer.log(stackTrace.toString());
      _handleError(_uiGenericErrorMessage, error: e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      developer.log(e.toString());
      developer.log(stackTrace.toString());
      _handleError(_uiGenericErrorMessage, error: e, stackTrace: stackTrace);
    } finally {
      if (_isLoading &&
          (_errorMsg != _uiSessionExpiredMessage || !_isReAuthenticating)) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  void _startPollingInvoices() {
    _stopPolling();
    if (isAuthenticated &&
        _activeConnection != null &&
        _activeConnection!.pollingIntervalSeconds > 0) {
      _timer = Timer.periodic(
          Duration(seconds: _activeConnection!.pollingIntervalSeconds),
          (timer) {
        if (_activeConnection == null || !isAuthenticated) {
          _stopPolling();
          return;
        }
        _fetchSummaryData(isInitialFetchForCurrentOp: false);
      });
    }
  }

  void _stopPolling() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  Future<void> logout() async {
    _stopPolling();
    _activeConnection = null;
    _authtoken = null;
    _summary = ManagementSummary();
    _errorMsg = null;
    _isLoading = false;
    _isReAuthenticating = false;
    _initializeDefaultDateRange();
    notifyListeners();
  }
}

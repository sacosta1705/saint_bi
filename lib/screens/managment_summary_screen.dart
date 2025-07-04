import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:saint_intelligence/analysis/screens/sales_forecast_screen.dart';
import 'package:saint_intelligence/models/account_payable.dart';
import 'package:saint_intelligence/models/account_receivable.dart';
import 'package:saint_intelligence/models/api_connection.dart';
import 'package:saint_intelligence/models/invoice.dart';
import 'package:saint_intelligence/providers/managment_summary_notifier.dart';
import 'package:saint_intelligence/screens/builders/transaction_list_item.dart';
import 'package:saint_intelligence/screens/connection_settings_screen.dart';
import 'package:saint_intelligence/config/app_colors.dart';
import 'package:saint_intelligence/screens/login_screen.dart';
import 'package:saint_intelligence/screens/transaction_list_screen.dart';
import 'package:saint_intelligence/services/database_service.dart';
import 'package:saint_intelligence/utils/security_service.dart';
import 'package:saint_intelligence/utils/formatters.dart';

const String _reloadDataTooltipText = 'Recargar Datos';
const String _settingsTooltipText = 'Configurar Conexiones';
const String _logoutTooltipText = 'Cerrar Sesión';
const String _connectingApiText = "Conectando con la API...";
const String _errorStateTitleText = "Error";
const String _defaultUiErrorText = "Ha ocurrido un error inesperado.";
const String _tryConnectButtonLabel = 'Intentar Conectar / Reintentar';
const String _reAuthenticatingMessageFromNotifier =
    'Sesión expirada. Intentando re-autenticar...';
const String _goToSettingsButtonText = 'Ir a Configuración';
const String _uiNoConnectionsAvailableMessage =
    'No hay conexiones disponibles. Por favor agregar una en la configuracion.';

class ManagementSummaryScreen extends StatefulWidget {
  const ManagementSummaryScreen({super.key});

  @override
  State<ManagementSummaryScreen> createState() =>
      _ManagementSummaryScreenState();
}

class _ManagementSummaryScreenState extends State<ManagementSummaryScreen> {
  @override
  void initState() {
    super.initState();
    // La inicialización de fechas ahora se hace en el Notifier
  }

  Future<void> _logout(BuildContext context) async {
    final notifier =
        Provider.of<ManagementSummaryNotifier>(context, listen: false);
    await notifier.logout();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _navigateToSettings(BuildContext context) async {
    final bool? isAuthenticated = await _showAdminPasswordDialog(context);

    if (isAuthenticated == true && mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const ConnectionSettingsScreen()),
      );

      final notifier =
          Provider.of<ManagementSummaryNotifier>(context, listen: false);

      if (result != null && result is ApiConnection) {
        await notifier.setActiveConnection(result, fetchFullData: true);
      } else {
        if (notifier.activeConnection != null) {
          await notifier.fetchInitialData();
        }
      }
    }
  }

  Future<bool?> _showAdminPasswordDialog(BuildContext context) {
    final passController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            String? errorText;
            bool isLoading = false;

            return AlertDialog(
              backgroundColor: AppColors.dialogBackground,
              title: const Text('Acceso de Administrador'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: passController,
                  obscureText: true,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    errorText: errorText,
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Ingrese la contraseña'
                      : null,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar',
                      style: TextStyle(color: AppColors.textSecondary)),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setStateInDialog(() => isLoading = true);
                            try {
                              final db = DatabaseService.instance;
                              final settings = await db.getAppSettings();
                              final storedHash = settings[
                                  DatabaseService.columnAdminPasswordHash];

                              if (storedHash == null) {
                                setStateInDialog(() => errorText =
                                    'Error: No hay contraseña configurada.');
                                return;
                              }

                              final isValid = SecurityService.verifyPassword(
                                  passController.text, storedHash);

                              if (isValid) {
                                Navigator.of(dialogContext).pop(true);
                              } else {
                                setStateInDialog(
                                    () => errorText = 'Contraseña incorrecta.');
                              }
                            } catch (e) {
                              setStateInDialog(
                                  () => errorText = 'Error: ${e.toString()}');
                            } finally {
                              setStateInDialog(() => isLoading = false);
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Ingresar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        titleSpacing: 16,
        title: Image.asset('assets/saint_logo_blanco.png', height: 38),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: _logoutTooltipText,
          ),
          IconButton(
            icon: const Icon(Icons.settings_applications_outlined),
            onPressed: () => _navigateToSettings(context),
            tooltip: _settingsTooltipText,
            color: AppColors.appBarForeground,
          ),
          Consumer<ManagementSummaryNotifier>(
            builder: (context, notifier, child) => IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed:
                  (notifier.isLoading || notifier.activeConnection == null)
                      ? null
                      : () => notifier.fetchInitialData(),
              tooltip: _reloadDataTooltipText,
              color: AppColors.appBarForeground,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ManagementSummaryNotifier>(
          builder: (context, notifier, child) {
            if (notifier.isLoading && !notifier.isAuthenticated) {
              return Center(child: _buildLoadingState(notifier: notifier));
            }
            if (notifier.errorMsg != null) {
              return Center(child: _buildErrorState(notifier, context));
            }
            if (!notifier.isAuthenticated ||
                notifier.activeConnection == null) {
              return Center(child: _buildErrorState(notifier, context));
            }

            final permissions = notifier.activeConnection!.permissions;
            if (!permissions.canViewSales) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No tienes permisos para ver ningún resumen.\nContacta al administrador.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            return Column(
              children: [
                _buildDateFilter(context, notifier), // WIDGET AÑADIDO
                Expanded(
                  child: _buildManagementSummaryBody(notifier, context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- WIDGET NUEVO: Selector de Fechas ---
  Widget _buildDateFilter(
      BuildContext context, ManagementSummaryNotifier notifier) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final startDateText = notifier.startDate != null
        ? dateFormat.format(notifier.startDate!)
        : 'Inicio';
    final endDateText =
        notifier.endDate != null ? dateFormat.format(notifier.endDate!) : 'Fin';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDateRange(context, notifier),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Período de Análisis',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      Text('$startDateText - $endDateText',
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list_off),
                tooltip: 'Limpiar filtro',
                onPressed: () => notifier.filterByDateRange(null, null),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange(
      BuildContext context, ManagementSummaryNotifier notifier) async {
    final initialRange = DateTimeRange(
      start: notifier.startDate ?? DateTime.now(),
      end: notifier.endDate ?? DateTime.now(),
    );

    final newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialRange,
      locale: const Locale('es', 'ES'),
    );

    if (newRange != null) {
      notifier.filterByDateRange(newRange.start, newRange.end);
    }
  }

  Widget _buildLoadingState({required ManagementSummaryNotifier notifier}) {
    String displayMessage = _connectingApiText;
    if (notifier.isLoading) {
      if (notifier.errorMsg == _reAuthenticatingMessageFromNotifier) {
        displayMessage = _reAuthenticatingMessageFromNotifier;
      } else if (notifier.activeConnection != null) {
        displayMessage =
            "Cargando datos para ${notifier.activeConnection!.companyName}...";
      }
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppColors.primaryOrange),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(displayMessage,
              style:
                  const TextStyle(fontSize: 15, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _buildErrorState(
      ManagementSummaryNotifier notifier, BuildContext context) {
    String title = _errorStateTitleText;
    String message = notifier.errorMsg ?? _defaultUiErrorText;
    IconData iconData = Icons.error_outline_rounded;
    Color iconColor = AppColors.statusMessageError;
    String buttonLabel = _tryConnectButtonLabel;
    VoidCallback onPressedAction = () {
      if (notifier.activeConnection != null) {
        notifier.fetchInitialData();
      }
    };

    if (notifier.errorMsg == _uiNoConnectionsAvailableMessage) {
      title = "Sin Conexiones";
      message =
          "No hay conexiones configuradas.\nPor favor, añada una para continuar.";
      iconData = Icons.settings_input_component_outlined;
      iconColor = AppColors.statusMessageInfo;
      buttonLabel = _goToSettingsButtonText;
      onPressedAction = () => _navigateToSettings(context);
    }

    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(iconData, color: iconColor, size: 60),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: iconColor, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: Icon(notifier.errorMsg == _uiNoConnectionsAvailableMessage
                ? Icons.settings
                : Icons.refresh_rounded),
            label: Text(buttonLabel, style: const TextStyle(fontSize: 16)),
            onPressed: notifier.isLoading ? null : onPressedAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: AppColors.textOnPrimaryOrange,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSummaryBody(
      ManagementSummaryNotifier notifier, BuildContext context) {
    final summary = notifier.summary;
    final deviceLocale = Localizations.localeOf(context).toString();

    return RefreshIndicator(
      onRefresh: () => notifier.fetchInitialData(),
      child: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const Icon(Icons.insights,
                  color: AppColors.primaryOrange, size: 32),
              title: const Text("Análisis y Proyecciones",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Estimar ventas futuras y más."),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SalesForecastScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildStyledSectionCard(
            title: "RESUMEN DE OPERACIONES",
            icon: Icons.show_chart,
            context: context,
            children: [
              _buildDataRow(
                "Total ventas netas:",
                formatNumber(summary.totalNetSales, deviceLocale),
                isTotal: true,
              ),
              const Divider(
                height: 24,
                thickness: 0,
                color: AppColors.primaryOrange,
              ),
              _buildDataRow("Ventas netas a crédito:",
                  formatNumber(summary.totalNetSalesCredit, deviceLocale),
                  onTap: () {
                final notifier = Provider.of<ManagementSummaryNotifier>(context,
                    listen: false);

                final creditInvoices = notifier.allInvoices
                    .where((inv) => inv.type == 'A' && inv.credit > 0)
                    .toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionListScreen<Invoice>(
                      title: "Facturas a credito",
                      items: creditInvoices,
                      itemBuilder: buildInvoiceListItem,
                    ),
                  ),
                );
              }),
              _buildDataRow(
                "Ventas netas de contado:",
                formatNumber(summary.totalNetSalesCash, deviceLocale),
                onTap: () {
                  final notifier = Provider.of<ManagementSummaryNotifier>(
                      context,
                      listen: false);

                  final cashInvoice = notifier.allInvoices
                      .where((inv) => inv.type == 'A' && inv.cash > 0)
                      .toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TransactionListScreen<Invoice>(
                          title: 'Facturas de contado',
                          items: cashInvoice,
                          itemBuilder: buildInvoiceListItem),
                    ),
                  );
                },
              ),
              _buildDataRow("N/D a Clientes:",
                  formatNumber(summary.netDebitNotes, deviceLocale)),
              _buildDataRow("N/C a Clientes:",
                  formatNumber(summary.netCreditNotes, deviceLocale)),
              const Divider(
                height: 24,
                thickness: 0.5,
                color: AppColors.primaryOrange,
              ),
              _buildDataRow("Costo de mercancia vendida:",
                  formatNumber(summary.costOfGoodsSold, deviceLocale)),
              _buildDataRow(
                "Utilidad bruta:",
                formatNumber(summary.grossProfit, deviceLocale),
                isTotal: true,
                valueColor: summary.grossProfit >= 0
                    ? AppColors.positiveValue
                    : AppColors.negativeValue,
              ),
              const Divider(
                height: 24,
                thickness: 0.5,
                color: AppColors.primaryOrange,
              ),
              _buildDataRow('Gastos y Costos fijos aproximados:',
                  formatNumber(summary.fixedCosts, deviceLocale)),
              // _buildDataRow("Gastos operativos:",
              //     formatNumber(summary.operatingExpenses, deviceLocale)),
              _buildDataRow(
                "Utilidad o pérdida operativa:",
                formatNumber(summary.netProfitOrLoss, deviceLocale),
                isTotal: true,
                valueColor: summary.netProfitOrLoss >= 0
                    ? AppColors.positiveValue
                    : AppColors.negativeValue,
              ),

              _buildDataRow(
                "Total Cuentas por Pagar:",
                formatNumber(summary.totalPayables, deviceLocale),
                onTap: () {
                  final notifier = Provider.of<ManagementSummaryNotifier>(
                      context,
                      listen: false);
                  final payables = notifier.allPayables
                      .where((ap) => ap.balance > 0 && ap.type != '50')
                      .toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TransactionListScreen<AccountPayable>(
                        title: 'Total Cuentas por pagar',
                        items: payables,
                        itemBuilder: buildAccountPayableListItem,
                      ),
                    ),
                  );
                },
              ),
              _buildDataRow("Total cuentas por Cobrar:",
                  formatNumber(summary.totalReceivables, deviceLocale),
                  onTap: () {
                final notifier = Provider.of<ManagementSummaryNotifier>(context,
                    listen: false);

                final receivables = notifier.allReceivables
                    .where((ar) => ar.balance > 0 && ar.type != '50')
                    .toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TransactionListScreen<AccountReceivable>(
                      title: 'Total cuentas por cobrar',
                      items: receivables,
                      itemBuilder: buildAccountReceivableListItem,
                    ),
                  ),
                );
              }),
              const Divider(
                height: 24,
                thickness: 0.5,
                color: AppColors.primaryOrange,
              ),
              _buildDataRow(
                  "Inventario total:",
                  isTotal: true,
                  formatNumber(
                      (summary.currentInventory - summary.fixtureInventory),
                      deviceLocale)),
              _buildDataRow("Inventario de enseres:",
                  formatNumber(summary.fixtureInventory, deviceLocale)),
              const Divider(
                height: 24,
                thickness: 0.5,
                color: AppColors.primaryOrange,
              ),
              _buildDataRow(
                "Cuentas por cobrar vencidas:",
                formatNumber(summary.overdueReceivables, deviceLocale),
                valueColor: summary.overduePayables > 0
                    ? AppColors.negativeValue
                    : null,
                onTap: () {
                  final notifier = Provider.of<ManagementSummaryNotifier>(
                      context,
                      listen: false);

                  final now = DateTime.now();
                  final overdue = notifier.allReceivables
                      .where((ar) => ar.balance > 0 && ar.dueDate.isBefore(now))
                      .toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TransactionListScreen<AccountReceivable>(
                        title: 'Cuentas por cobrar vencidas',
                        items: overdue,
                        itemBuilder: buildAccountReceivableListItem,
                      ),
                    ),
                  );
                },
              ),
              _buildDataRow(
                "Cuentas por Pagar Vencidas:",
                formatNumber(summary.overduePayables, deviceLocale),
                valueColor: summary.overduePayables > 0
                    ? AppColors.negativeValue
                    : null,
                onTap: () {
                  final notifier = Provider.of<ManagementSummaryNotifier>(
                      context,
                      listen: false);
                  final now = DateTime.now();
                  final overdue = notifier.allPayables
                      .where((ap) => ap.balance > 0 && ap.dueDate.isBefore(now))
                      .toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TransactionListScreen(
                        title: 'Cuentas por pagar vencidas',
                        items: overdue,
                        itemBuilder: buildAccountPayableListItem,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          _buildStyledSectionCard(
            title: "RESUMEN DE IMPUESTOS",
            icon: Icons.receipt_long,
            context: context,
            children: [
              _buildDataRow(
                  "Total I.V.A. por Pagar:",
                  formatNumber(
                      (summary.salesVat - summary.purchasesVat), deviceLocale),
                  isTotal: true,
                  valueColor: (summary.salesVat - summary.purchasesVat) < 0
                      ? AppColors.statusMessageError
                      : AppColors.statusMessageSuccess),
              const Divider(
                height: 24,
                thickness: 0.5,
                color: AppColors.primaryOrange,
              ),
              _buildDataRow("I.V.A. en Ventas:",
                  formatNumber(summary.salesVat, deviceLocale)),
              _buildDataRow("IVA Retenido por Clientes:",
                  formatNumber(summary.salesIvaWithheld, deviceLocale)),
              _buildDataRow("I.S.L.R. Retenido por Clientes:",
                  formatNumber(summary.salesIslrWithheld, deviceLocale)),
              const Divider(
                height: 24,
                thickness: 0.5,
                color: AppColors.primaryOrange,
              ),
              _buildDataRow("I.V.A. en Compras:",
                  formatNumber(summary.purchasesVat, deviceLocale)),
              _buildDataRow("IVA Retenido a Proveedores:",
                  formatNumber(summary.purchasesIvaWithheld, deviceLocale)),
              _buildDataRow("I.S.L.R. Retenido a Proveedores:",
                  formatNumber(summary.purchasesIslrWithheld, deviceLocale)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStyledSectionCard({
    required String title,
    required IconData icon,
    required BuildContext context,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(12)),
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.primaryBlue,
            child: Row(
              children: [
                Icon(icon, color: AppColors.iconOnPrimary, size: 22),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnPrimaryBlue,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: children,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value,
      {Color? valueColor, bool isTotal = false, VoidCallback? onTap}) {
    final Color finalValueColor = valueColor ?? AppColors.textPrimary;

    final labelStyle = TextStyle(
        fontSize: 16,
        color: AppColors.textSecondary,
        fontWeight: isTotal ? FontWeight.w500 : FontWeight.normal);

    final valueStyle = TextStyle(
        fontSize: 17,
        fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
        color: finalValueColor);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Text(label, style: labelStyle),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: Text(
                value,
                style: valueStyle,
                textAlign: TextAlign.end,
              ),
            ),
            if (onTap != null)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

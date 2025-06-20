import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saint_intelligence/models/api_connection.dart';

import 'package:saint_intelligence/providers/managment_summary_notifier.dart';
import 'package:saint_intelligence/screens/connection_settings_screen.dart';
import 'package:saint_intelligence/config/app_colors.dart';
import 'package:saint_intelligence/screens/login_screen.dart';
import 'package:saint_intelligence/services/database_service.dart';
import 'package:saint_intelligence/utils/security_service.dart';

// const String _screenTitleText = 'Saint BI: Resumen Gerencial';
const String _reloadDataTooltipText = 'Recargar Datos';
const String _settingsTooltipText = 'Configurar Conexiones';
const String _logoutTooltipText = 'Cerrar Sesión';
const String _connectingApiText = "Conectando con la API...";
const String _errorStateTitleText = "Error";
const String _defaultUiErrorText = "Ha ocurrido un error inesperado.";
const String _tryConnectButtonLabel = 'Intentar Conectar / Reintentar';
const String _reAuthenticatingMessageFromNotifier =
    'Sesión expirada. Intentando re-autenticar...';
// const String _selectDateRangeTooltipText = 'Seleccionar Rango';
// const String _todayButtonText = 'Hoy';
// const String _clearFilterButtonText = 'Quitar Filtro';
// const String _allDatesText = 'Todas las fechas';
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
  // Future<void> _pickDateRange(
  //     BuildContext context, ManagementSummaryNotifier notifier) async {
  //   if (notifier.activeConnection == null) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //           content: Text('Por favor, primero seleccione una empresa.'),
  //           backgroundColor: AppColors.statusMessageWarning));
  //     }
  //     return;
  //   }

  //   final DateTimeRange? pickedRange = await showDateRangePicker(
  //     context: context,
  //     initialDateRange: (notifier.startDate != null && notifier.endDate != null)
  //         ? DateTimeRange(start: notifier.startDate!, end: notifier.endDate!)
  //         : null,
  //     firstDate: DateTime(2000),
  //     lastDate: DateTime.now().add(const Duration(days: 365)),
  //     locale: const Locale('es', 'ES'),
  //     helpText: 'SELECCIONAR RANGO',
  //     cancelText: 'CANCELAR',
  //     confirmText: 'APLICAR',
  //     builder: (context, child) => child!,
  //   );

  //   if (pickedRange != null && mounted) {
  //     bool hasChanged =
  //         (notifier.startDate?.isAtSameMomentAs(pickedRange.start) != true) ||
  //             (notifier.endDate?.isAtSameMomentAs(pickedRange.end) != true);
  //     if (hasChanged) {
  //       await notifier.filterByDateRange(pickedRange.start, pickedRange.end);
  //     }
  //   }
  // }

  String _formatNumber(double number, String locale) {
    if (number.abs() < 1000000) {
      return NumberFormat.decimalPatternDigits(
        locale: locale,
        decimalDigits: 2,
      ).format(number);
    } else {
      return NumberFormat.compact(locale: locale).format(number);
    }
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

            return _buildManagementSummaryBody(notifier, context);
          },
        ),
      ),
    );
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
    final currencyFormat = NumberFormat.decimalPatternDigits(
        locale: deviceLocale, decimalDigits: 2);

    return RefreshIndicator(
      onRefresh: () => notifier.fetchInitialData(),
      child: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          _buildStyledSectionCard(
            title: "RESUMEN DE OPERACIONES",
            icon: Icons.show_chart,
            context: context,
            children: [
              _buildDataRow("Ventas netas a crédito:",
                  _formatNumber(summary.totalNetSalesCredit, deviceLocale)),
              _buildDataRow("Ventas netas de contado:",
                  _formatNumber(summary.totalNetSalesCash, deviceLocale)),
              _buildDataRow("Total ventas netas:",
                  _formatNumber(summary.totalNetSales, deviceLocale),
                  isTotal: true),
              const Divider(height: 24, thickness: 0.5),
              _buildDataRow("Costo de mercancia vendida:",
                  _formatNumber(summary.costOfGoodsSold, deviceLocale)),
              _buildDataRow("Utilidad bruta:",
                  _formatNumber(summary.grossProfit, deviceLocale),
                  isTotal: true,
                  valueColor: summary.grossProfit >= 0
                      ? AppColors.positiveValue
                      : AppColors.negativeValue),
              const Divider(height: 24, thickness: 0.5),
              _buildDataRow("Gastos operativos:",
                  _formatNumber(summary.operatingExpenses, deviceLocale)),
              _buildDataRow("Utilidad o pérdida operativa:",
                  _formatNumber(summary.netProfitOrLoss, deviceLocale),
                  isTotal: true,
                  valueColor: summary.netProfitOrLoss >= 0
                      ? AppColors.positiveValue
                      : AppColors.negativeValue),
            ],
          ),
          _buildStyledSectionCard(
            title: "ESTADO FINANCIERO",
            icon: Icons.account_balance_wallet,
            context: context,
            children: [
              _buildDataRow("Valor de inventario actual:",
                  _formatNumber(summary.currentInventory, deviceLocale)),
              const Divider(height: 24, thickness: 0.5),
              _buildDataRow("Cuentas por cobrar vencidas:",
                  _formatNumber(summary.overdueReceivables, deviceLocale),
                  valueColor: summary.overduePayables > 0
                      ? AppColors.negativeValue
                      : null),
              _buildDataRow("Total cuentas por cobrar:",
                  _formatNumber(summary.totalReceivables, deviceLocale),
                  isTotal: true),
              const Divider(height: 24, thickness: 0.5),
              _buildDataRow("Cuentas por Pagar Vencidas:",
                  _formatNumber(summary.overduePayables, deviceLocale),
                  valueColor: summary.overduePayables > 0
                      ? AppColors.negativeValue
                      : null),
              _buildDataRow("Total Cuentas por Pagar:",
                  _formatNumber(summary.totalPayables, deviceLocale),
                  isTotal: true),
              _buildStyledSectionCard(
                title: "RESUMEN DE IMPUESTOS",
                icon: Icons.receipt_long,
                context: context,
                children: [
                  _buildDataRow("I.V.A. en Ventas (Débito Fiscal):",
                      _formatNumber(summary.salesVat, deviceLocale)),
                  _buildDataRow("I.V.A. en Compras (Crédito Fiscal):",
                      _formatNumber(summary.purchasesVat, deviceLocale)),
                  _buildDataRow(
                      "Total I.V.A. por Pagar:",
                      _formatNumber((summary.salesVat - summary.purchasesVat),
                          deviceLocale),
                      isTotal: true),
                  const Divider(height: 24, thickness: 0.5),
                  _buildDataRow("IVA Retenido por Clientes (a favor):",
                      _formatNumber(summary.salesIvaWithheld, deviceLocale)),
                  _buildDataRow(
                      "IVA Retenido a Proveedores (por pagar):",
                      _formatNumber(
                          summary.purchasesIvaWithheld, deviceLocale)),
                ],
              ),
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
            color: AppColors.accentColor,
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
      {Color? valueColor, bool isTotal = false}) {
    final Color finalValueColor = valueColor ?? AppColors.textPrimary;

    final labelStyle = TextStyle(
        fontSize: 16,
        color: AppColors.textSecondary,
        fontWeight: isTotal ? FontWeight.w500 : FontWeight.normal);

    final valueStyle = TextStyle(
        fontSize: 17,
        fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
        color: finalValueColor);

    return Padding(
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
          )
        ],
      ),
    );
  }

  // Barra de filtros de fecha. Se extrae de _buildSalesCard para reutilizarla.
  // Widget _buildDateFilterBar(
  //     ManagementSummaryNotifier notifier, BuildContext context) {
  //   final dateFormat = DateFormat('dd/MM/yyyy', 'es_ES');

  //   return Container(
  //     padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
  //     margin:
  //         const EdgeInsets.only(bottom: 8.0, top: 8.0, left: 8.0, right: 8.0),
  //     decoration: BoxDecoration(
  //         color: AppColors.cardBackground,
  //         borderRadius: BorderRadius.circular(12.0),
  //         boxShadow: [
  //           BoxShadow(
  //               color: Colors.grey,
  //               spreadRadius: 1,
  //               blurRadius: 5,
  //               offset: const Offset(0, 2))
  //         ]),
  //     child: Column(
  //       children: [
  //         Text(
  //             (notifier.startDate == null && notifier.endDate == null)
  //                 ? _allDatesText
  //                 : 'Rango: ${dateFormat.format(notifier.startDate!)} - ${dateFormat.format(notifier.endDate!)}',
  //             style: const TextStyle(
  //                 fontSize: 15,
  //                 fontWeight: FontWeight.w600,
  //                 color: AppColors.primaryBlue),
  //             textAlign: TextAlign.center),
  //         const SizedBox(height: 10),
  //         Wrap(
  //           alignment: WrapAlignment.center,
  //           spacing: 8.0,
  //           runSpacing: 4.0,
  //           children: [
  //             TextButton.icon(
  //                 icon: const Icon(Icons.date_range,
  //                     size: 20, color: AppColors.primaryOrange),
  //                 label: const Text(_selectDateRangeTooltipText,
  //                     style: TextStyle(
  //                         color: AppColors.primaryOrange,
  //                         fontWeight: FontWeight.w500)),
  //                 onPressed: notifier.isLoading
  //                     ? null
  //                     : () => _pickDateRange(context, notifier)),
  //             TextButton(
  //                 onPressed: notifier.isLoading
  //                     ? null
  //                     : () {
  //                         final now = DateTime.now();
  //                         final todayNormalized =
  //                             DateTime(now.year, now.month, now.day);
  //                         notifier.filterByDateRange(
  //                             todayNormalized, todayNormalized);
  //                       },
  //                 child: const Text(_todayButtonText,
  //                     style: TextStyle(
  //                         color: AppColors.primaryBlue,
  //                         fontWeight: FontWeight.w500))),
  //             if (notifier.startDate != null || notifier.endDate != null)
  //               TextButton(
  //                   onPressed: notifier.isLoading
  //                       ? null
  //                       : () => notifier.filterByDateRange(null, null),
  //                   child: const Text(_clearFilterButtonText,
  //                       style: TextStyle(
  //                           color: AppColors.textSecondary,
  //                           fontWeight: FontWeight.w500))),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

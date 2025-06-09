import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saint_bi/models/api_connection.dart';
// IMPORTANTE: Añadir este import
import 'package:saint_bi/providers/invoice_notifier.dart';
import 'package:saint_bi/screens/connection_settings_screen.dart';
import 'package:saint_bi/config/app_colors.dart';
import 'package:saint_bi/screens/login_screen.dart';
import 'package:saint_bi/services/database_service.dart';
import 'package:saint_bi/utils/security_service.dart';

// Constantes de texto
const String _screenTitleText = 'Saint: Resumen de operaciones';
const String _reloadDataTooltipText = 'Recargar Datos';
const String _settingsTooltipText = 'Configurar Conexiones';
const String _logoutTooltipText = 'Cerrar Sesión';
const String _connectingApiText = "Conectando con la API...";
const String _errorStateTitleText = "Error";
const String _defaultUiErrorText = "Ha ocurrido un error inesperado.";
const String _tryConnectButtonLabel = 'Intentar Conectar / Reintentar';
const String _summaryCardTitleText = 'Resumen de Transacciones de Venta';
const String _totalSalesLabelText = 'Total Ventas';
const String _totalReturnsLabelText = 'Total Devoluciones';
const String _totalTaxesLabelText = 'Total Impuestos';
const String _invoicesCountSuffixText = 'facturas';
const String _returnsCountSuffixText = 'notas';
const String _reAuthenticatingMessageFromNotifier =
    'Sesión expirada. Intentando re-autenticar...';
const String _selectDateRangeTooltipText = 'Seleccionar Rango';
const String _todayButtonText = 'Hoy';
const String _clearFilterButtonText = 'Quitar Filtro';
const String _allDatesText = 'Todas las fechas';
const String _goToSettingsButtonText = 'Ir a Configuración';
const String _uiNoConnectionsAvailableMessage =
    'No hay conexiones disponibles. Por favor agregar una en la configuracion.';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _logout(BuildContext context) async {
    final notifier = Provider.of<InvoiceNotifier>(context, listen: false);
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

      final notifier = Provider.of<InvoiceNotifier>(context, listen: false);

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

  Future<void> _pickDateRange(
      BuildContext context, InvoiceNotifier notifier) async {
    if (notifier.activeConnection == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Por favor, primero seleccione una empresa.'),
            backgroundColor: AppColors.statusMessageWarning));
      }
      return;
    }

    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: (notifier.startDate != null && notifier.endDate != null)
          ? DateTimeRange(start: notifier.startDate!, end: notifier.endDate!)
          : null,
      firstDate: DateTime(1997),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
      helpText: 'SELECCIONAR RANGO',
      cancelText: 'CANCELAR',
      confirmText: 'APLICAR',
      builder: (context, child) => child!,
    );

    if (pickedRange != null && mounted) {
      bool hasChanged =
          (notifier.startDate?.isAtSameMomentAs(pickedRange.start) != true) ||
              (notifier.endDate?.isAtSameMomentAs(pickedRange.end) != true);
      if (hasChanged) {
        await notifier.filterByDateRange(pickedRange.start, pickedRange.end);
      }
    }
  }

  Widget _buildDataRow(String label, String value,
      {Color valueColor = AppColors.textPrimary, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 5,
              child: Text(label,
                  style: TextStyle(
                      fontSize: fontSize - 1, color: AppColors.textSecondary),
                  textAlign: TextAlign.start)),
          const SizedBox(width: 12),
          Expanded(
              flex: 7,
              child: Text(value,
                  style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: valueColor),
                  textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _buildLoadingState(
      {String message = _connectingApiText,
      required InvoiceNotifier notifier}) {
    String displayMessage = message;
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

  Widget _buildErrorState(InvoiceNotifier notifier, BuildContext context) {
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

  // Este widget ahora solo construye la tarjeta de Ventas.
  Widget _buildSalesCard(InvoiceNotifier notifier, BuildContext context) {
    final summary = notifier.invoiceSummary;
    final dateFormat = DateFormat('dd/MM/yyyy', 'es_ES');

    return Column(
      children: [
        // Controles de fecha
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          margin: const EdgeInsets.only(
              bottom: 16.0, top: 8.0, left: 8.0, right: 8.0),
          decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2))
              ]),
          child: Column(
            children: [
              Text(
                  (notifier.startDate == null && notifier.endDate == null)
                      ? _allDatesText
                      : 'Rango: ${dateFormat.format(notifier.startDate!)} - ${dateFormat.format(notifier.endDate!)}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  TextButton.icon(
                      icon: const Icon(Icons.date_range,
                          size: 20, color: AppColors.primaryOrange),
                      label: const Text(_selectDateRangeTooltipText,
                          style: TextStyle(
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.w500)),
                      onPressed: notifier.isLoading
                          ? null
                          : () => _pickDateRange(context, notifier)),
                  TextButton(
                      onPressed: notifier.isLoading
                          ? null
                          : () {
                              final now = DateTime.now();
                              final todayNormalized =
                                  DateTime(now.year, now.month, now.day);
                              notifier.filterByDateRange(
                                  todayNormalized, todayNormalized);
                            },
                      child: const Text(_todayButtonText,
                          style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w500))),
                  if (notifier.startDate != null || notifier.endDate != null)
                    TextButton(
                        onPressed: notifier.isLoading
                            ? null
                            : () => notifier.filterByDateRange(null, null),
                        child: const Text(_clearFilterButtonText,
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500))),
                ],
              ),
            ],
          ),
        ),
        // Tarjeta de datos de ventas
        Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: AppColors.cardBackground,
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                    "$_summaryCardTitleText para \"${notifier.activeConnection!.companyName}\"",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue)),
                const SizedBox(height: 25),
                _buildDataRow(
                    '$_totalSalesLabelText (${summary.salesCount} $_invoicesCountSuffixText):',
                    NumberFormat.currency(
                            locale: 'es_VE', symbol: 'Bs. ', decimalDigits: 2)
                        .format(summary.totalSales),
                    valueColor: AppColors.positiveValue,
                    fontSize: 16.5),
                const SizedBox(height: 8),
                _buildDataRow(
                    '$_totalReturnsLabelText (${summary.returnsCount} $_returnsCountSuffixText):',
                    NumberFormat.currency(
                            locale: 'es_VE', symbol: 'Bs. ', decimalDigits: 2)
                        .format(summary.totalReturns),
                    valueColor: AppColors.negativeValue,
                    fontSize: 16.5),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15.0),
                    child:
                        Divider(thickness: 1, color: AppColors.dividerColor)),
                _buildDataRow(
                    _totalTaxesLabelText,
                    NumberFormat.currency(
                            locale: 'es_VE', symbol: 'Bs. ', decimalDigits: 2)
                        .format(summary.totalTax),
                    valueColor: AppColors.neutralValue,
                    fontSize: 16.5),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(_screenTitleText,
            style: TextStyle(fontWeight: FontWeight.bold)),
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
              color: AppColors.appBarForeground),
          Consumer<InvoiceNotifier>(
              builder: (context, notifier, child) => IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed:
                      (notifier.isLoading || notifier.activeConnection == null)
                          ? null
                          : () => notifier.fetchInitialData(),
                  tooltip: _reloadDataTooltipText,
                  color: AppColors.appBarForeground)),
        ],
      ),
      // --- INICIO DE LA IMPLEMENTACIÓN DE PERMISOS ---
      body: Consumer<InvoiceNotifier>(
        builder: (context, notifier, child) {
          // Primero, manejamos los estados que impiden mostrar contenido
          if (notifier.isLoading && !notifier.isAuthenticated) {
            return _buildLoadingState(notifier: notifier);
          }
          if (notifier.errorMsg != null) {
            return _buildErrorState(notifier, context);
          }
          if (!notifier.isAuthenticated || notifier.activeConnection == null) {
            return _buildErrorState(notifier, context);
          }

          // Si llegamos aquí, estamos autenticados y tenemos una conexión.
          // Ahora, verificamos los permisos.
          final permissions = notifier.activeConnection!.permissions;

          List<Widget> visibleCards = [];

          if (permissions.canViewSales) {
            visibleCards.add(_buildSalesCard(notifier, context));
          }
          // Si después de chequear, no hay tarjetas para mostrar, informamos al usuario.
          if (visibleCards.isEmpty) {
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

          // Si hay tarjetas, las mostramos en una lista.
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            children: visibleCards,
          );
        },
      ),
      // --- FIN DE LA IMPLEMENTACIÓN DE PERMISOS ---
    );
  }
}

// Widget de marcador de posición para futuras tarjetas. Puedes moverlo a su propio archivo.
class _PlaceholderCard extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderCard({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 8),
            const Text(
              '(Este es un marcador de posición para una futura implementación)',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

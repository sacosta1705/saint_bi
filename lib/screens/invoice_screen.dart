// lib/screens/invoice_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saint_bi/models/api_connection.dart';
import 'package:saint_bi/providers/invoice_notifier.dart';
import 'package:saint_bi/screens/connection_settings_screen.dart';

// Constantes de texto (sin cambios respecto a tu versión)
const String _screenTitleText = 'Resumen de Ventas Saint BI 📊';
const String _reloadDataTooltipText = 'Recargar Datos';
const String _settingsTooltipText = 'Configurar Conexiones';
const String _connectingApiText = "Conectando con la API...";
const String _errorStateTitleText =
    "Error"; // Puedes cambiarlo a "Error Inesperado" si prefieres
const String _defaultUiErrorText = "Ha ocurrido un error inesperado.";
const String _tryConnectButtonLabel = 'Intentar Conectar / Reintentar';
const String _summaryCardTitleText = 'Resumen de Transacciones de Venta';
const String _totalSalesLabelText = 'Total Ventas';
const String _totalReturnsLabelText = 'Total Devoluciones';
const String _totalTaxesLabelText = 'Total Impuestos';
const String _invoicesCountSuffixText = 'facturas';
const String _returnsCountSuffixText = 'notas';
const String _updatingDataText = "Actualizando...";
const String _liveDataText = "Datos en vivo.";
const String _pollingIntervalSuffixText = "seg.";
const String _warningTitleText = 'Advertencia';
const String _reAuthenticatingMessageFromNotifier =
    'Sesión expirada. Intentando re-autenticar...';
const String _selectDateRangeTooltipText = 'Seleccionar Rango';
const String _todayButtonText = 'Hoy';
const String _clearFilterButtonText = 'Quitar Filtro';
const String _allDatesText = 'Todas las fechas';
const String _noConnectionSelectedText = 'Ninguna empresa seleccionada';
const String _selectCompanyHintText = 'Seleccionar Empresa Conectada';
const String _noConnectionsAvailableText = 'No hay conexiones configuradas.';
const String _goToSettingsButtonText = 'Ir a Configuración de Conexiones';
const String _uiNoConnectionSelectedMessage =
    'Seleccione o configure una conexión de empresa.';
const String _uiNoConnectionsAvailableMessage =
    'No hay conexiones configuradas. Por favor, añada una.';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InvoiceNotifier>(context, listen: false)
          .refreshAvailableConnections();
    });
  }

  Future<void> _pickDateRange(
    BuildContext context,
    InvoiceNotifier notifier,
  ) async {
    if (notifier.activeConnection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, primero seleccione una empresa.')),
      );
      return;
    }

    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: (notifier.startDate != null && notifier.endDate != null)
          ? DateTimeRange(start: notifier.startDate!, end: notifier.endDate!)
          : (notifier.startDate != null)
              ? DateTimeRange(
                  start: notifier.startDate!, end: notifier.startDate!)
              : (notifier.endDate != null)
                  ? DateTimeRange(
                      start: notifier.endDate!, end: notifier.endDate!)
                  : null,
      firstDate: DateTime(1997),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
      helpText: 'SELECCIONAR RANGO DE FECHAS',
      cancelText: 'CANCELAR',
      confirmText: 'APLICAR',
      errorFormatText: 'Formato de fecha inválido.',
      errorInvalidText: 'Fecha fuera de rango.',
      errorInvalidRangeText: 'Rango de fechas inválido.',
      fieldStartHintText: 'Fecha de inicio',
      fieldEndHintText: 'Fecha de fin',
      fieldStartLabelText: 'Desde',
      fieldEndLabelText: 'Hasta',
      // El builder ahora solo devuelve el child, sin envolverlo en un Theme widget.
      // Heredará el tema del MaterialApp.
      builder: (context, child) {
        return child!;
      },
    );

    if (pickedRange != null) {
      bool hasChanged =
          (notifier.startDate?.isAtSameMomentAs(pickedRange.start) != true) ||
              (notifier.endDate?.isAtSameMomentAs(pickedRange.end) != true);
      if (hasChanged) {
        await notifier.filterByDateRange(pickedRange.start, pickedRange.end);
      }
    }
  }

  Widget _buildDataRow(
    String label,
    String value, {
    Color valueColor = Colors.black87,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: fontSize, color: Colors.grey.shade700),
              textAlign: TextAlign.start,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
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
      } else if (notifier.activeConnection != null &&
          (notifier.startDate != null || notifier.endDate != null)) {
        final dateFormat = DateFormat('dd/MM/yyyy', 'es_ES');
        String rangeText;
        if (notifier.startDate != null && notifier.endDate != null) {
          rangeText =
              "${dateFormat.format(notifier.startDate!)} - ${dateFormat.format(notifier.endDate!)}";
        } else if (notifier.startDate != null) {
          rangeText = "desde ${dateFormat.format(notifier.startDate!)}";
        } else {
          rangeText = "hasta ${dateFormat.format(notifier.endDate!)}";
        }
        displayMessage =
            "Cargando datos para ${notifier.activeConnection!.companyName}\n($rangeText)...";
      } else if (notifier.activeConnection != null) {
        displayMessage =
            "Cargando datos para ${notifier.activeConnection!.companyName}...";
      } else if (notifier.availableConnections.isEmpty &&
          notifier.errorMsg == null) {
        displayMessage = "Verificando conexiones guardadas...";
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(displayMessage,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _buildErrorState(InvoiceNotifier notifier, BuildContext context) {
    bool noConnectionsConfigured = notifier.availableConnections.isEmpty &&
        (notifier.errorMsg == _uiNoConnectionSelectedMessage ||
            notifier.errorMsg == _uiNoConnectionsAvailableMessage) &&
        !notifier.isLoading;

    bool noConnectionSelectedFromList = notifier.activeConnection == null &&
        notifier.availableConnections.isNotEmpty &&
        (notifier.errorMsg == _uiNoConnectionSelectedMessage ||
            notifier.errorMsg == _uiNoConnectionsAvailableMessage) &&
        !notifier.isLoading;

    String title = _errorStateTitleText;
    String message = notifier.errorMsg ?? _defaultUiErrorText;
    IconData iconData = Icons.error_outline_rounded;
    Color iconColor = Colors.red.shade700; // Color por defecto para errores
    String buttonLabel = _tryConnectButtonLabel;
    VoidCallback onPressedAction = () {
      if (notifier.activeConnection != null) {
        notifier.fetchInitialData();
      } else {
        notifier.refreshAvailableConnections();
      }
    };

    if (noConnectionsConfigured) {
      title = "Sin Conexiones";
      message =
          "$_noConnectionsAvailableText\nPor favor, añada una en la configuración para comenzar.";
      iconData = Icons.settings_input_component_outlined;
      iconColor = Colors.blueGrey.shade700;
      buttonLabel = _goToSettingsButtonText;
      onPressedAction = () => _navigateToSettings(context);
    } else if (noConnectionSelectedFromList) {
      title = "Seleccione Empresa";
      message =
          "Por favor, elija una empresa del listado para visualizar sus datos.";
      iconData = Icons.info_outline_rounded; // Ícono más neutral
      iconColor =
          Theme.of(context).colorScheme.primary; // Usar color primario del tema
      return Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, color: iconColor, size: 60),
            const SizedBox(height: 20),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: iconColor, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(iconData, color: iconColor, size: 60),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: iconColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          const SizedBox(height: 30),
          if (!noConnectionSelectedFromList || noConnectionsConfigured)
            ElevatedButton.icon(
              icon: Icon(noConnectionsConfigured
                  ? Icons.settings_applications_rounded
                  : Icons.refresh_rounded),
              label: Text(buttonLabel, style: const TextStyle(fontSize: 15)),
              onPressed: notifier.isLoading ? null : onPressedAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: noConnectionsConfigured
                    ? Colors.blueGrey.shade700
                    : Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompanySelector(InvoiceNotifier notifier, BuildContext context) {
    if (notifier.isLoading && notifier.availableConnections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                )),
            const SizedBox(width: 12),
            Text("Cargando conexiones...",
                style: TextStyle(
                    fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
          ],
        ),
      );
    }
    if (notifier.availableConnections.isEmpty && !notifier.isLoading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: DropdownButtonFormField<ApiConnection>(
        decoration: InputDecoration(
          labelText: _selectCompanyHintText,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Theme.of(context).primaryColor)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide:
                BorderSide(color: Theme.of(context).primaryColor, width: 2.0),
          ),
          prefixIcon: Icon(Icons.business_rounded,
              color: Theme.of(context).primaryColor),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0),
          filled: true,
          fillColor: Colors.white,
        ),
        isExpanded: true,
        value: notifier.activeConnection,
        hint: Text(_selectCompanyHintText,
            style: TextStyle(color: Colors.grey.shade600)),
        items: notifier.availableConnections.map((ApiConnection connection) {
          return DropdownMenuItem<ApiConnection>(
            value: connection,
            child: Text(connection.companyName,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: notifier.isLoading
            ? null
            : (ApiConnection? newValue) {
                if (newValue != null) {
                  if (notifier.activeConnection?.id != newValue.id ||
                      notifier.activeConnection == null) {
                    notifier.setActiveConnection(newValue, fetchFullData: true);
                  }
                }
              },
      ),
    );
  }

  Widget _buildDataDisplay(InvoiceNotifier notifier, BuildContext context) {
    final summary = notifier.invoiceSummary;
    final pollingInterval = notifier.pollingIntervalSeconds;
    final dateFormat = DateFormat('dd/MM/yyyy', 'es_ES');

    String liveDataInfo = _noConnectionSelectedText;
    if (notifier.activeConnection != null && notifier.isAuthenticated) {
      liveDataInfo =
          "$_liveDataText Actualizando cada $pollingInterval $_pollingIntervalSuffixText para \"${notifier.activeConnection!.companyName}\"";
      if (notifier.startDate != null || notifier.endDate != null) {
        String rangeText;
        if (notifier.startDate != null && notifier.endDate != null) {
          rangeText =
              "${dateFormat.format(notifier.startDate!)} - ${dateFormat.format(notifier.endDate!)}";
        } else if (notifier.startDate != null) {
          rangeText = "Desde ${dateFormat.format(notifier.startDate!)}";
        } else {
          rangeText = "Hasta ${dateFormat.format(notifier.endDate!)}";
        }
        liveDataInfo += " (Filtro: $rangeText)";
      }
    } else if (notifier.activeConnection != null &&
        notifier.errorMsg == _reAuthenticatingMessageFromNotifier) {
      liveDataInfo = _reAuthenticatingMessageFromNotifier;
    } else if (notifier.activeConnection != null &&
        notifier.errorMsg != null &&
        notifier.errorMsg != _uiNoConnectionSelectedMessage &&
        notifier.errorMsg != _uiNoConnectionsAvailableMessage &&
        notifier.errorMsg !=
            "La fecha final no puede ser anterior a la fecha de inicio.") {
      liveDataInfo = "";
    } else if (notifier.activeConnection == null &&
        notifier.availableConnections.isNotEmpty) {
      liveDataInfo = "Seleccione una empresa del listado para ver los datos.";
    } else if (notifier.availableConnections.isEmpty) {
      liveDataInfo = _noConnectionsAvailableText;
    }

    String statusMessage = liveDataInfo;
    Color statusMessageColor = Colors.green.shade700;
    FontStyle statusMessageFontStyle = FontStyle.italic;

    if (notifier.errorMsg != null &&
        notifier.errorMsg !=
            "La fecha final no puede ser anterior a la fecha de inicio." &&
        notifier.errorMsg != _uiNoConnectionSelectedMessage &&
        notifier.errorMsg != _uiNoConnectionsAvailableMessage) {
      if (notifier.errorMsg == _reAuthenticatingMessageFromNotifier) {
        statusMessageColor = Colors.orange.shade800;
      } else if (notifier.activeConnection != null) {
        statusMessage = "Error al actualizar datos. Verifique la conexión.";
        statusMessageColor = Colors.red.shade700;
      }
    } else if (notifier.activeConnection == null &&
        notifier.availableConnections.isNotEmpty) {
      statusMessageColor = Colors.blueGrey.shade700;
    } else if (notifier.availableConnections.isEmpty && !notifier.isLoading) {
      statusMessageColor = Colors.grey.shade700;
    }

    String dateFilterDisplayText;
    if (notifier.startDate == null && notifier.endDate == null) {
      dateFilterDisplayText = _allDatesText;
    } else if (notifier.startDate != null && notifier.endDate == null) {
      dateFilterDisplayText =
          'Desde: ${dateFormat.format(notifier.startDate!)}';
    } else if (notifier.startDate == null && notifier.endDate != null) {
      dateFilterDisplayText = 'Hasta: ${dateFormat.format(notifier.endDate!)}';
    } else {
      dateFilterDisplayText =
          'Rango: ${dateFormat.format(notifier.startDate!)} - ${dateFormat.format(notifier.endDate!)}';
    }

    final bool showDateControlsAndSummary =
        notifier.activeConnection != null && notifier.isAuthenticated;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showDateControlsAndSummary) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
              child: Column(
                children: [
                  Text(
                    dateFilterDisplayText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryColorDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (notifier.errorMsg ==
                      "La fecha final no puede ser anterior a la fecha de inicio.")
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        notifier.errorMsg!,
                        style:
                            TextStyle(color: Colors.red.shade700, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.date_range, size: 18),
                        label: const Text(_selectDateRangeTooltipText),
                        onPressed: notifier.isLoading
                            ? null
                            : () => _pickDateRange(context, notifier),
                      ),
                      TextButton(
                        onPressed: notifier.isLoading
                            ? null
                            : () {
                                final now = DateTime.now();
                                final todayNormalized =
                                    DateTime(now.year, now.month, now.day);
                                bool isTodaySelected =
                                    (notifier.startDate?.year ==
                                            todayNormalized.year &&
                                        notifier.startDate?.month ==
                                            todayNormalized.month &&
                                        notifier.startDate?.day ==
                                            todayNormalized.day &&
                                        notifier.endDate?.year ==
                                            todayNormalized.year &&
                                        notifier.endDate?.month ==
                                            todayNormalized.month &&
                                        notifier.endDate?.day ==
                                            todayNormalized.day);

                                if (!isTodaySelected) {
                                  notifier.filterByDateRange(
                                      todayNormalized, todayNormalized);
                                }
                              },
                        child: const Text(_todayButtonText),
                      ),
                      if (notifier.startDate != null ||
                          notifier.endDate != null)
                        TextButton(
                          onPressed: notifier.isLoading
                              ? null
                              : () => notifier.filterByDateRange(null, null),
                          child: const Text(_clearFilterButtonText),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(thickness: 0.8),
            const SizedBox(height: 10),
          ],
          if (notifier.activeConnection != null &&
              notifier.errorMsg != null &&
              notifier.isAuthenticated &&
              !notifier.isLoading &&
              notifier.errorMsg != _reAuthenticatingMessageFromNotifier &&
              notifier.errorMsg !=
                  "La fecha final no puede ser anterior a la fecha de inicio." &&
              notifier.errorMsg != _uiNoConnectionSelectedMessage &&
              notifier.errorMsg != _uiNoConnectionsAvailableMessage)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 18, top: 5),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300, width: 0.8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange.shade700, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$_warningTitleText: ${notifier.errorMsg}',
                      style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          if (showDateControlsAndSummary &&
              (notifier.errorMsg == null ||
                  notifier.errorMsg == _reAuthenticatingMessageFromNotifier ||
                  notifier.errorMsg ==
                      "La fecha final no puede ser anterior a la fecha de inicio."))
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 20.0, horizontal: 15.0),
                child: Column(
                  children: [
                    Text(
                      "$_summaryCardTitleText para \"${notifier.activeConnection!.companyName}\"",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 25),
                    _buildDataRow(
                      '$_totalSalesLabelText (${summary.salesCount} $_invoicesCountSuffixText):',
                      NumberFormat.currency(
                              locale: 'es_VE', symbol: 'Bs. ', decimalDigits: 2)
                          .format(summary.totalSales),
                      valueColor: Colors.green.shade700,
                      fontSize: 14,
                    ),
                    const SizedBox(height: 5),
                    _buildDataRow(
                      '$_totalReturnsLabelText (${summary.returnsCount} $_returnsCountSuffixText):',
                      NumberFormat.currency(
                              locale: 'es_VE', symbol: 'Bs. ', decimalDigits: 2)
                          .format(summary.totalReturns),
                      valueColor: Colors.red.shade600,
                      fontSize: 14,
                    ),
                    const Divider(
                        height: 35, thickness: 0.8, indent: 10, endIndent: 10),
                    _buildDataRow(
                      _totalTaxesLabelText,
                      NumberFormat.currency(
                              locale: 'es_VE', symbol: 'Bs. ', decimalDigits: 2)
                          .format(summary.totalTax),
                      valueColor: Theme.of(context).primaryColorDark,
                      fontSize: 14,
                    ),
                  ],
                ),
              ),
            )
          else if (notifier.activeConnection == null &&
              notifier.availableConnections.isNotEmpty &&
              !notifier.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 50.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 50, color: Colors.blueGrey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    statusMessage, // "Seleccione una empresa..."
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: statusMessageColor),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 25),
          if (notifier.isLoading &&
              notifier.activeConnection != null &&
              notifier.errorMsg != _reAuthenticatingMessageFromNotifier)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2.5)),
                const SizedBox(width: 10),
                Text(_updatingDataText,
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade700)),
              ],
            )
          else if (statusMessage.isNotEmpty &&
              (notifier.activeConnection != null ||
                  notifier.errorMsg == _reAuthenticatingMessageFromNotifier ||
                  notifier.availableConnections.isEmpty))
            Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: statusMessageColor,
                  fontStyle: statusMessageFontStyle),
            ),
        ],
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConnectionSettingsScreen()),
    ).then((valueFromSettings) {
      final notifier = Provider.of<InvoiceNotifier>(context, listen: false);
      notifier.refreshAvailableConnections(
          newlySelectedFromSettings: valueFromSettings is ApiConnection
              ? valueFromSettings
              : notifier.activeConnection);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(_screenTitleText),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_applications_outlined),
            onPressed: () => _navigateToSettings(context),
            tooltip: _settingsTooltipText,
          ),
          Consumer<InvoiceNotifier>(
            builder: (context, notifier, child) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed:
                    (notifier.isLoading || notifier.activeConnection == null)
                        ? null
                        : () {
                            notifier.fetchInitialData();
                          },
                tooltip: _reloadDataTooltipText,
              );
            },
          ),
        ],
      ),
      body: Consumer<InvoiceNotifier>(
        builder: (context, notifier, child) {
          Widget companySelector = _buildCompanySelector(notifier, context);
          Widget bodyContent;

          if (notifier.isLoading &&
              notifier.availableConnections.isEmpty &&
              notifier.activeConnection == null) {
            bodyContent = _buildLoadingState(
                message: "Verificando conexiones...", notifier: notifier);
          } else if (notifier.availableConnections.isEmpty &&
              !notifier.isLoading) {
            bodyContent = _buildErrorState(notifier, context);
          } else if (notifier.activeConnection == null &&
              notifier.availableConnections.isNotEmpty &&
              !notifier.isLoading) {
            bodyContent = SingleChildScrollView(
                child: _buildDataDisplay(notifier, context));
          } else if (notifier.isLoading && notifier.activeConnection != null) {
            if (notifier.invoiceSummary.salesCount == 0 &&
                notifier.invoiceSummary.returnsCount == 0 &&
                notifier.errorMsg != _reAuthenticatingMessageFromNotifier) {
              bodyContent = _buildLoadingState(notifier: notifier);
            } else {
              bodyContent = SingleChildScrollView(
                  child: _buildDataDisplay(notifier, context));
            }
          } else if (notifier.activeConnection != null &&
              notifier.errorMsg != null &&
              notifier.errorMsg != _uiNoConnectionSelectedMessage &&
              notifier.errorMsg != _uiNoConnectionsAvailableMessage &&
              notifier.errorMsg !=
                  "La fecha final no puede ser anterior a la fecha de inicio.") {
            bodyContent = _buildErrorState(notifier, context);
          } else if (notifier.activeConnection != null &&
              notifier.isAuthenticated) {
            bodyContent = SingleChildScrollView(
                child: _buildDataDisplay(notifier, context));
          } else {
            if ((notifier.errorMsg == _uiNoConnectionSelectedMessage ||
                    notifier.errorMsg == _uiNoConnectionsAvailableMessage) &&
                notifier.availableConnections.isNotEmpty) {
              bodyContent = SingleChildScrollView(
                  child: _buildDataDisplay(notifier, context));
            } else {
              bodyContent = _buildErrorState(notifier, context);
            }
          }

          return Column(
            children: [
              companySelector,
              Expanded(
                child: Center(child: bodyContent),
              ),
            ],
          );
        },
      ),
    );
  }
}

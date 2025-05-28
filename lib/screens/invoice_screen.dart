// lib/screens/invoice_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saint_bi/providers/invoice_notifier.dart';

const String _screenTitleText = 'Resumen de Ventas Saint BI 📊';
const String _reloadDataTooltipText = 'Recargar Datos';
const String _connectingApiText = "Conectando con la API...";
const String _errorStateTitleText = "Error";
const String _defaultUiErrorText = "Ha ocurrido un error inesperado.";
const String _connectionInstructionsText =
    "Verifique su conexión y la configuración del servidor.";
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
const String _selectDateRangeTooltipText = 'Seleccionar Rango'; // Modificado
const String _todayButtonText = 'Hoy';
const String _clearFilterButtonText = 'Quitar Filtro';
const String _allDatesText = 'Todas las fechas';

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

  Future<void> _pickDateRange(
    BuildContext context,
    InvoiceNotifier notifier,
  ) async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: (notifier.startDate != null && notifier.endDate != null)
          ? DateTimeRange(start: notifier.startDate!, end: notifier.endDate!)
          : (notifier.startDate != null)
          ? DateTimeRange(start: notifier.startDate!, end: notifier.startDate!)
          : (notifier.endDate != null)
          ? DateTimeRange(start: notifier.endDate!, end: notifier.endDate!)
          : null,
      firstDate: DateTime(1997),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      bool hasChanged = true;
      if (notifier.startDate?.year == pickedRange.start.year &&
          notifier.startDate?.month == pickedRange.start.month &&
          notifier.startDate?.day == pickedRange.start.day &&
          notifier.endDate?.year == pickedRange.end.year &&
          notifier.endDate?.month == pickedRange.end.month &&
          notifier.endDate?.day == pickedRange.end.day) {
        hasChanged = false;
      }

      // if ((notifier.startDate == null) ||
      //     (notifier.startDate != null) ||
      //     (notifier.endDate == null) ||
      //     (notifier.endDate != null)) {}

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

  Widget _buildLoadingState({String message = _connectingApiText}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Text(message, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildErrorState(InvoiceNotifier notifier, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade700,
            size: 70,
          ),
          const SizedBox(height: 25),
          Text(
            notifier.errorMsg ??
                _errorStateTitleText, // Mostrar error específico del notifier si existe
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14, // Ajustar tamaño si es error del notifier
              fontWeight: (notifier.errorMsg != null)
                  ? FontWeight.normal
                  : FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          if (notifier.errorMsg ==
              null) // Solo mostrar titulo "Error" si no hay mensaje específico
            const SizedBox.shrink()
          else
            const SizedBox(height: 10), // Espacio si hay mensaje
          // No mostrar el error por defecto si ya hay uno del notifier
          if (notifier.errorMsg == null)
            Text(
              _defaultUiErrorText,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.red.shade700),
            ),

          const SizedBox(height: 20),
          const Text(
            _connectionInstructionsText,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 35),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text(_tryConnectButtonLabel),
            onPressed: notifier.isLoading
                ? null
                : () {
                    notifier.filterByDateRange(
                      notifier.startDate,
                      notifier.endDate,
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataDisplay(InvoiceNotifier notifier, BuildContext context) {
    final summary = notifier.invoiceSummary;
    final pollingInterval = notifier.pollingIntervalSeconds;
    final dateFormat = DateFormat('dd/MM/yyyy', 'es_ES');

    String liveDataMessage =
        "$_liveDataText Actualizando cada $pollingInterval $_pollingIntervalSuffixText";
    if (notifier.startDate != null || notifier.endDate != null) {
      String rangeText;
      if (notifier.startDate != null && notifier.endDate != null) {
        rangeText =
            "${dateFormat.format(notifier.startDate!)} - ${dateFormat.format(notifier.endDate!)}";
      } else if (notifier.startDate != null) {
        rangeText = "Desde ${dateFormat.format(notifier.startDate!)}";
      } else {
        // Solo endDate != null
        rangeText = "Hasta ${dateFormat.format(notifier.endDate!)}";
      }
      liveDataMessage += " (Filtro: $rangeText)";
    }

    String statusMessage = liveDataMessage;
    Color statusMessageColor = Colors.green;
    FontStyle statusMessageFontStyle = FontStyle.normal;

    if (notifier.errorMsg != null &&
        notifier.errorMsg !=
            "La fecha final no puede ser anterior a la fecha de inicio.") {
      // No mostrar error de rango como "status" de reintento
      if (notifier.errorMsg == _reAuthenticatingMessageFromNotifier) {
        statusMessage = notifier.errorMsg!;
        statusMessageColor = Colors.orange.shade800;
        statusMessageFontStyle = FontStyle.italic;
      }
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
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
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    TextButton.icon(
                      icon: const Icon(
                        Icons.date_range,
                        size: 14,
                      ), // Icono cambiado
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
                              // Normalizar 'now' a medianoche para comparar solo la fecha
                              final todayNormalized = DateTime(
                                now.year,
                                now.month,
                                now.day,
                              );
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
                                  notifier.endDate?.day == todayNormalized.day);

                              if (!isTodaySelected) {
                                notifier.filterByDateRange(
                                  todayNormalized,
                                  todayNormalized,
                                );
                              }
                            },
                      child: const Text(_todayButtonText),
                    ),
                    // Solo mostrar si hay un filtro aplicado (al menos una fecha)
                    if (notifier.startDate != null || notifier.endDate != null)
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
          const Divider(),
          const SizedBox(height: 10),

          // ... (resto del widget _buildDataDisplay sin cambios en la lógica de mostrar errores o el Card)
          if (notifier.errorMsg != null &&
              notifier.isAuthenticated &&
              !notifier.isLoading &&
              notifier.errorMsg != _reAuthenticatingMessageFromNotifier &&
              notifier.errorMsg !=
                  "La fecha final no puede ser anterior a la fecha de inicio.") // No mostrar error de rango aquí
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade400),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade800,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$_warningTitleText: ${notifier.errorMsg}',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 15.0,
              ),
              child: Column(
                children: [
                  const Text(
                    _summaryCardTitleText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildDataRow(
                    '$_totalSalesLabelText (${summary.salesCount} $_invoicesCountSuffixText):',
                    summary.totalSales.toStringAsFixed(2),
                    valueColor: Colors.green.shade700,
                    fontSize: 14,
                  ),
                  const SizedBox(height: 5),
                  _buildDataRow(
                    '$_totalReturnsLabelText (${summary.returnsCount} $_returnsCountSuffixText):',
                    summary.totalReturns.toStringAsFixed(2),
                    valueColor: Colors.red.shade600,
                    fontSize: 14,
                  ),
                  const Divider(
                    height: 35,
                    thickness: 1,
                    indent: 10,
                    endIndent: 10,
                  ),
                  _buildDataRow(
                    _totalTaxesLabelText,
                    summary.totalTax.toStringAsFixed(2),
                    valueColor: Theme.of(context).primaryColorDark,
                    fontSize: 14,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),

          if (notifier.isLoading &&
              notifier.isAuthenticated &&
              notifier.errorMsg != _reAuthenticatingMessageFromNotifier)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 10),
                const Text(
                  _updatingDataText,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            )
          else if (notifier.isAuthenticated ||
              notifier.errorMsg == _reAuthenticatingMessageFromNotifier)
            Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: statusMessageColor,
                fontStyle: statusMessageFontStyle,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(_screenTitleText),
        actions: [
          Consumer<InvoiceNotifier>(
            builder: (context, notifier, child) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: notifier.isLoading
                    ? null
                    : () {
                        notifier.filterByDateRange(
                          notifier.startDate,
                          notifier.endDate,
                        );
                      },
                tooltip: _reloadDataTooltipText,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Consumer<InvoiceNotifier>(
          builder: (context, notifier, child) {
            String loadingMessage = _connectingApiText;
            if (notifier.isLoading) {
              // Solo cambiar mensaje de carga si realmente está cargando
              if (notifier.errorMsg == _reAuthenticatingMessageFromNotifier) {
                loadingMessage = _reAuthenticatingMessageFromNotifier;
              } else if (notifier.startDate != null ||
                  notifier.endDate != null) {
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
                loadingMessage = "Cargando datos para $rangeText...";
              }
            }

            if (notifier.isLoading &&
                ((!notifier.isAuthenticated && notifier.errorMsg == null) ||
                    (notifier.errorMsg ==
                            _reAuthenticatingMessageFromNotifier &&
                        notifier.invoiceSummary.salesCount == 0 &&
                        notifier.invoiceSummary.returnsCount == 0) ||
                    ((notifier.startDate != null || notifier.endDate != null) &&
                        notifier.invoiceSummary.salesCount == 0 &&
                        notifier.invoiceSummary.returnsCount == 0 &&
                        notifier.errorMsg !=
                            "La fecha final no puede ser anterior a la fecha de inicio.") // Cargando para un nuevo rango sin datos previos
                    )) {
              return _buildLoadingState(message: loadingMessage);
            }

            if (!notifier.isAuthenticated &&
                notifier.errorMsg != null &&
                notifier.errorMsg != _reAuthenticatingMessageFromNotifier) {
              return _buildErrorState(notifier, context);
            }

            if (notifier.isAuthenticated ||
                (notifier.invoiceSummary.salesCount > 0 ||
                    notifier.invoiceSummary.returnsCount > 0) ||
                notifier.errorMsg ==
                    "La fecha final no puede ser anterior a la fecha de inicio.") {
              return SingleChildScrollView(
                child: _buildDataDisplay(notifier, context),
              );
            }

            return _buildErrorState(notifier, context);
          },
        ),
      ),
    );
  }
}

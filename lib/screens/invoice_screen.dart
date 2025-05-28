// lib/screens/invoice_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importar para formateo de fechas
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
const String _selectDateTooltipText = 'Seleccionar Fecha';
const String _todayButtonText = 'Hoy';
const String _clearFilterButtonText = 'Quitar Filtro';
const String _allDatesText = 'Todas las fechas';
const String _dataForText = 'Datos para:';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar los datos de hoy al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = Provider.of<InvoiceNotifier>(context, listen: false);
      if (notifier.selectedDate == null) {
        notifier.filterByDate(DateTime.now());
      }
    });
  }

  Future<void> _pickDate(BuildContext context, InvoiceNotifier notifier) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: notifier.selectedDate ?? DateTime.now(),
      firstDate: DateTime(1997),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate != null) {
      bool isSameDate = false;
      if (notifier.selectedDate != null) {
        isSameDate =
            pickedDate.year == notifier.selectedDate!.year &&
            pickedDate.month == notifier.selectedDate!.month &&
            pickedDate.day == notifier.selectedDate!.day;
      }
      if (!isSameDate) {
        await notifier.filterByDate(pickedDate);
      }
    }
  }

  Widget _buildDataRow(
    String label,
    String value, {
    Color valueColor = Colors.black87,
    double fontSize = 20,
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
        Text(message, style: const TextStyle(fontSize: 16)),
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
            _errorStateTitleText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            notifier.errorMsg ?? _defaultUiErrorText,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.red.shade700),
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
                    notifier.filterByDate(notifier.selectedDate);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataDisplay(InvoiceNotifier notifier, BuildContext context) {
    final summary = notifier.invoiceSummary;
    final pollingInterval = notifier.pollingIntervalSeconds;

    String liveDataMessage =
        "$_liveDataText Actualizando cada $pollingInterval $_pollingIntervalSuffixText";
    if (notifier.selectedDate != null) {
      liveDataMessage +=
          " (Filtro: ${DateFormat('dd/MM/yyyy', 'es_ES').format(notifier.selectedDate!)})";
    }

    String statusMessage = liveDataMessage;
    Color statusMessageColor = Colors.green;
    FontStyle statusMessageFontStyle = FontStyle.normal;

    if (notifier.errorMsg != null) {
      if (notifier.errorMsg == _reAuthenticatingMessageFromNotifier) {
        statusMessage = notifier.errorMsg!;
        statusMessageColor = Colors.orange.shade800;
        statusMessageFontStyle = FontStyle.italic;
      }
    }

    String dateFilterText = notifier.selectedDate == null
        ? _allDatesText
        : "$_dataForText ${DateFormat('dd/MM/yyyy', 'es_ES').format(notifier.selectedDate!)}";

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
                  dateFilterText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text(_selectDateTooltipText),
                      onPressed: notifier.isLoading
                          ? null
                          : () => _pickDate(context, notifier),
                    ),
                    TextButton(
                      onPressed: notifier.isLoading
                          ? null
                          : () {
                              final now = DateTime.now();
                              bool isTodaySelected = false;
                              if (notifier.selectedDate != null) {
                                isTodaySelected =
                                    now.year == notifier.selectedDate!.year &&
                                    now.month == notifier.selectedDate!.month &&
                                    now.day == notifier.selectedDate!.day;
                              }
                              if (!isTodaySelected) {
                                notifier.filterByDate(now);
                              }
                            },
                      child: const Text(_todayButtonText),
                    ),
                    if (notifier.selectedDate !=
                        null) // Solo mostrar si hay un filtro aplicado
                      TextButton(
                        onPressed: notifier.isLoading
                            ? null
                            : () => notifier.filterByDate(null),
                        child: const Text(_clearFilterButtonText),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          const SizedBox(height: 10),

          if (notifier.errorMsg != null &&
              notifier.isAuthenticated &&
              !notifier.isLoading &&
              notifier.errorMsg != _reAuthenticatingMessageFromNotifier)
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
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildDataRow(
                    '$_totalSalesLabelText (${summary.salesCount} $_invoicesCountSuffixText):',
                    summary.totalSales.toStringAsFixed(2),
                    valueColor: Colors.green.shade700,
                    fontSize: 18,
                  ),
                  const SizedBox(height: 5),
                  _buildDataRow(
                    '$_totalReturnsLabelText (${summary.returnsCount} $_returnsCountSuffixText):',
                    summary.totalReturns.toStringAsFixed(2),
                    valueColor: Colors.red.shade600,
                    fontSize: 18,
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
                    fontSize: 20,
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
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            )
          else if (notifier.isAuthenticated ||
              notifier.errorMsg == _reAuthenticatingMessageFromNotifier)
            Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
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
                        notifier.filterByDate(notifier.selectedDate);
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
            if (notifier.isLoading &&
                ((!notifier.isAuthenticated && notifier.errorMsg == null) ||
                    (notifier.errorMsg ==
                            _reAuthenticatingMessageFromNotifier &&
                        notifier.invoiceSummary.salesCount == 0 &&
                        notifier.invoiceSummary.returnsCount == 0))) {
              return _buildLoadingState(
                message:
                    notifier.errorMsg == _reAuthenticatingMessageFromNotifier
                    ? _reAuthenticatingMessageFromNotifier
                    : (notifier.selectedDate != null
                          ? "Cargando datos para ${DateFormat('dd/MM/yyyy', 'es_ES').format(notifier.selectedDate!)}..."
                          : _connectingApiText),
              );
            }

            if (!notifier.isAuthenticated &&
                notifier.errorMsg != null &&
                notifier.errorMsg != _reAuthenticatingMessageFromNotifier) {
              return _buildErrorState(notifier, context);
            }

            if (notifier.isAuthenticated ||
                (notifier.invoiceSummary.salesCount > 0 ||
                    notifier.invoiceSummary.returnsCount > 0)) {
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

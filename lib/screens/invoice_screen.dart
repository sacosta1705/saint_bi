// lib/screens/invoice_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saint_bi/models/api_connection.dart'; // NUEVO
import 'package:saint_bi/providers/invoice_notifier.dart';
import 'package:saint_bi/screens/connection_settings_screen.dart'; // NUEVO

// Constantes de texto (mantener las existentes, añadir nuevas si es necesario)
const String _screenTitleText = 'Resumen de Ventas Saint BI 📊';
const String _reloadDataTooltipText = 'Recargar Datos';
const String _settingsTooltipText = 'Configurar Conexiones'; // NUEVO
const String _connectingApiText = "Conectando con la API...";
const String _errorStateTitleText = "Error Inesperado"; // Cambiado
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
const String _updatingDataText = "Actualizando datos..."; // Cambiado
const String _liveDataText = "Datos en vivo.";
const String _pollingIntervalSuffixText = "seg.";
const String _warningTitleText = 'Advertencia';
const String _reAuthenticatingMessageFromNotifier =
    'Sesión expirada. Intentando re-autenticar...';
const String _selectDateRangeTooltipText =
    'Seleccionar Rango de Fechas'; // Cambiado
const String _todayButtonText = 'Hoy';
const String _clearFilterButtonText = 'Quitar Filtro';
const String _allDatesText = 'Todas las fechas';
const String _noConnectionSelectedText = 'Ninguna empresa seleccionada';
const String _selectCompanyHintText =
    'Seleccionar Empresa Conectada'; // Cambiado
const String _noConnectionsAvailableText = 'No hay conexiones configuradas.';
const String _goToSettingsButtonText =
    'Ir a Configuración de Conexiones'; // Cambiado
const String _uiNoConnectionSelectedMessage =
    'Seleccione o configure una conexión de empresa.';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  @override
  void initState() {
    super.initState();
    // Al iniciar la pantalla, pedir al notifier que cargue las conexiones disponibles.
    // Esto es importante si se navega directamente a esta pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InvoiceNotifier>(
        context,
        listen: false,
      ).refreshAvailableConnections();
    });
  }

  Future<void> _pickDateRange(
    BuildContext context,
    InvoiceNotifier notifier,
  ) async {
    if (notifier.activeConnection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, primero seleccione una empresa.'),
        ),
      );
      return;
    }
    // El resto de la lógica de _pickDateRange se mantiene igual
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: (notifier.startDate != null && notifier.endDate != null)
          ? DateTimeRange(start: notifier.startDate!, end: notifier.endDate!)
          : (notifier.startDate != null)
          ? DateTimeRange(
              start: notifier.startDate!,
              end: notifier.startDate!,
            ) // Si solo hay start, usarlo para ambos
          : (notifier.endDate != null)
          ? DateTimeRange(
              start: notifier.endDate!,
              end: notifier.endDate!,
            ) // Si solo hay end, usarlo para ambos
          : null, // Si ninguno está definido, no hay rango inicial
      firstDate: DateTime(1997), // Un año razonable para el inicio de los datos
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ), // Permitir seleccionar hasta un año en el futuro
      locale: const Locale('es', 'ES'), // Para formato de calendario en español
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            // Puedes basarlo en el tema actual: Theme.of(context).copyWith(...)
            colorScheme: ColorScheme.light(
              primary: Theme.of(
                context,
              ).primaryColor, // Usa el color primario de tu app
              onPrimary: Colors.white, // Color del texto sobre el primario
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme
                  .primary, // Para que los botones del picker usen el color primario
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      // Comprobar si el rango realmente cambió para evitar recargas innecesarias
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
        crossAxisAlignment:
            CrossAxisAlignment.start, // Alineación por si el texto es largo
        children: [
          Expanded(
            flex: 2, // Dar más espacio a la etiqueta si es necesario
            child: Text(
              label,
              style: TextStyle(fontSize: fontSize, color: Colors.grey.shade700),
              textAlign: TextAlign.start,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3, // Dar más espacio al valor
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

  Widget _buildLoadingState({
    String message = _connectingApiText,
    required InvoiceNotifier notifier,
  }) {
    String displayMessage = message;
    // Personalizar mensaje de carga basado en el estado del notifier
    if (notifier.isLoading) {
      // Doble chequeo, ya que este widget se llama cuando isLoading es true
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
          // Solo endDate
          rangeText = "hasta ${dateFormat.format(notifier.endDate!)}";
        }
        displayMessage =
            "Cargando datos para ${notifier.activeConnection!.companyName}\n($rangeText)...";
      } else if (notifier.activeConnection != null) {
        displayMessage =
            "Cargando datos para ${notifier.activeConnection!.companyName}...";
      } else if (notifier.availableConnections.isEmpty &&
          notifier.errorMsg == null) {
        // Esto es cuando el notifier se inicia y llama a refreshAvailableConnections por primera vez
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
          child: Text(
            displayMessage,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(InvoiceNotifier notifier, BuildContext context) {
    // Determinar si el error es por falta de configuración de conexiones
    bool noConnectionsConfigured =
        notifier.availableConnections.isEmpty &&
        notifier.errorMsg == _uiNoConnectionSelectedMessage &&
        !notifier.isLoading; // Solo si no está cargando la lista

    bool noConnectionSelectedFromList =
        notifier.activeConnection == null &&
        notifier.availableConnections.isNotEmpty &&
        notifier.errorMsg == _uiNoConnectionSelectedMessage &&
        !notifier.isLoading;

    String title =
        _errorStateTitleText; // Título por defecto para errores generales
    String message = notifier.errorMsg ?? _defaultUiErrorText;
    IconData iconData = Icons.error_outline_rounded;
    Color iconColor = Colors.red.shade700;
    String buttonLabel = _tryConnectButtonLabel;
    VoidCallback onPressedAction = () {
      if (notifier.activeConnection != null) {
        notifier.fetchInitialData(); // Reintentar la conexión activa
      } else {
        notifier
            .refreshAvailableConnections(); // Si no hay activa, refrescar lista
      }
    };

    if (noConnectionsConfigured) {
      title = "Sin Conexiones";
      message =
          _noConnectionsAvailableText +
          "\nPor favor, añade una en la configuración.";
      iconData = Icons.settings_input_component_outlined;
      iconColor = Colors.blueGrey.shade700;
      buttonLabel = _goToSettingsButtonText;
      onPressedAction = () => _navigateToSettings(context);
    } else if (noConnectionSelectedFromList) {
      // Este estado se maneja mejor mostrando el dropdown y un mensaje en _buildDataDisplay
      // Por lo tanto, este widget de error no debería mostrarse en este caso específico
      // si el _buildDataDisplay ya está manejándolo.
      // Si llegamos aquí con este estado, es un fallback.
      title = "Seleccione Empresa";
      message =
          "Por favor, seleccione una empresa del listado para ver los datos.";
      iconData = Icons.business_center_outlined;
      iconColor = Theme.of(context).primaryColor;
      // Para este caso, el botón no es tan relevante como el dropdown
      // Se podría ocultar el botón o no hacer nada.
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: iconColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message, // Ya contiene el mensaje adecuado
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          const SizedBox(height: 30),
          // Solo mostrar botón si no es el caso de "seleccione de la lista"
          if (!noConnectionSelectedFromList || noConnectionsConfigured)
            ElevatedButton.icon(
              icon: Icon(
                noConnectionsConfigured
                    ? Icons.settings_applications_rounded
                    : Icons.refresh_rounded,
              ),
              label: Text(buttonLabel, style: const TextStyle(fontSize: 15)),
              onPressed: notifier.isLoading
                  ? null
                  : onPressedAction, // Deshabilitar si ya está cargando
              style: ElevatedButton.styleFrom(
                backgroundColor: noConnectionsConfigured
                    ? Colors.blueGrey.shade700
                    : Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // NUEVO: Widget para el selector de empresa
  Widget _buildCompanySelector(InvoiceNotifier notifier, BuildContext context) {
    // No mostrar si la lista de conexiones disponibles aún se está cargando y está vacía
    if (notifier.isLoading && notifier.availableConnections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Center(
          child: Text(
            "Cargando lista de conexiones...",
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ),
      );
    }
    // No mostrar si no hay conexiones y ya terminó de cargar (el error state lo indicará)
    if (notifier.availableConnections.isEmpty && !notifier.isLoading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: DropdownButtonFormField<ApiConnection>(
        decoration: InputDecoration(
          labelText: _selectCompanyHintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          prefixIcon: Icon(
            Icons.business_rounded,
            color: Theme.of(context).primaryColor,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 15.0,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        isExpanded: true,
        value:
            notifier.activeConnection, // Puede ser null si ninguna está activa
        hint: const Text(
          _selectCompanyHintText,
          style: TextStyle(color: Colors.black54),
        ),
        items: notifier.availableConnections.map((ApiConnection connection) {
          return DropdownMenuItem<ApiConnection>(
            value: connection,
            child: Text(
              connection.companyName,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: notifier.isLoading
            ? null
            : (ApiConnection? newValue) {
                if (newValue != null) {
                  // Solo recargar datos si la selección es realmente diferente a la actual
                  // o si la conexión activa es null.
                  if (notifier.activeConnection?.id != newValue.id ||
                      notifier.activeConnection == null) {
                    notifier.setActiveConnection(newValue, fetchFullData: true);
                  }
                  // Si es la misma, no hacer nada para evitar recargas innecesarias.
                  // El estado `activeConnection` ya está seteado.
                }
              },
        // validator: (value) => value == null ? 'Por favor, seleccione una empresa' : null, // Opcional
      ),
    );
  }

  // MODIFICADO: Para mostrar datos o mensajes relevantes
  Widget _buildDataDisplay(InvoiceNotifier notifier, BuildContext context) {
    final summary = notifier.invoiceSummary;
    final pollingInterval =
        notifier.pollingIntervalSeconds; // Ya toma de la conexión activa
    final dateFormat = DateFormat(
      'dd/MM/yyyy',
      'es_ES',
    ); // Formato de fecha en español

    // Mensaje sobre el estado de los datos y polling
    String liveDataInfo = _noConnectionSelectedText; // Mensaje por defecto
    if (notifier.activeConnection != null && notifier.isAuthenticated) {
      // Solo si hay conexión activa Y está autenticado
      liveDataInfo =
          "$_liveDataText Actualizando cada $pollingInterval $_pollingIntervalSuffixText para ${notifier.activeConnection!.companyName}";
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
        liveDataInfo += " (Filtro: $rangeText)";
      }
    } else if (notifier.activeConnection != null &&
        !notifier.isAuthenticated &&
        notifier.errorMsg == _reAuthenticatingMessageFromNotifier) {
      // Si hay conexión activa, pero no autenticado y está re-autenticando
      liveDataInfo = _reAuthenticatingMessageFromNotifier;
    } else if (notifier.activeConnection != null &&
        notifier.errorMsg != null &&
        notifier.errorMsg != _uiNoConnectionSelectedMessage &&
        notifier.errorMsg !=
            "La fecha final no puede ser anterior a la fecha de inicio.") {
      // Si hay conexión activa pero hay un error que no es el de "sin seleccionar" o "rango inválido"
      liveDataInfo =
          ""; // No mostrar info de "en vivo" si hay un error de conexión/API
    } else if (notifier.activeConnection == null &&
        notifier.availableConnections.isNotEmpty) {
      liveDataInfo = "Seleccione una empresa del listado para ver los datos.";
    }

    // Mensaje de estado general (puede ser el liveDataInfo o un mensaje de error específico)
    String statusMessage = liveDataInfo;
    Color statusMessageColor =
        Colors.green.shade700; // Color por defecto para "en vivo"
    FontStyle statusMessageFontStyle = FontStyle.italic;

    if (notifier.errorMsg != null &&
        notifier.errorMsg !=
            "La fecha final no puede ser anterior a la fecha de inicio." &&
        notifier.errorMsg != _uiNoConnectionSelectedMessage) {
      // No mostrar error de rango o no selección como status general
      if (notifier.errorMsg == _reAuthenticatingMessageFromNotifier) {
        statusMessage =
            notifier.errorMsg!; // Ya está en liveDataInfo si es el caso
        statusMessageColor = Colors.orange.shade800;
      } else if (notifier.activeConnection != null) {
        // Si hay conexión activa pero otro error
        // El error principal se mostrará en _buildErrorState o como advertencia.
        // El statusMessage aquí podría quedar vacío o indicar "Error al actualizar".
        statusMessage = "Error al actualizar datos. Verifique la conexión.";
        statusMessageColor = Colors.red.shade700;
      }
    } else if (notifier.activeConnection == null &&
        notifier.availableConnections.isNotEmpty) {
      statusMessageColor = Colors.blueGrey; // Color para "seleccione empresa"
    }

    // Texto para el filtro de fecha actual
    String dateFilterDisplayText;
    if (notifier.startDate == null && notifier.endDate == null) {
      dateFilterDisplayText = _allDatesText;
    } else if (notifier.startDate != null && notifier.endDate == null) {
      dateFilterDisplayText =
          'Desde: ${dateFormat.format(notifier.startDate!)}';
    } else if (notifier.startDate == null && notifier.endDate != null) {
      dateFilterDisplayText = 'Hasta: ${dateFormat.format(notifier.endDate!)}';
    } else {
      // Ambas no nulas
      dateFilterDisplayText =
          'Rango: ${dateFormat.format(notifier.startDate!)} - ${dateFormat.format(notifier.endDate!)}';
    }

    final bool showDateControlsAndSummary =
        notifier.activeConnection != null && notifier.isAuthenticated;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // Alineación principal
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // El selector de empresa (_buildCompanySelector) se muestra fuera de este widget, en el builder principal.

          // Controles de fecha (solo si hay conexión activa y autenticada)
          if (showDateControlsAndSummary) ...[
            Padding(
              padding: const EdgeInsets.only(
                bottom: 16.0,
                top: 8.0,
              ), // Espacio si el dropdown está arriba
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
                      "La fecha final no puede ser anterior a la fecha de inicio.") // Error específico de rango de fechas
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        notifier.errorMsg!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    // Para que los botones se ajusten en pantallas pequeñas
                    alignment: WrapAlignment.center,
                    spacing: 8.0, // Espacio horizontal entre botones
                    runSpacing: 4.0, // Espacio vertical si se envuelven
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
                                    notifier.endDate?.day ==
                                        todayNormalized.day);

                                if (!isTodaySelected) {
                                  // Solo aplicar si no está ya seleccionado
                                  notifier.filterByDateRange(
                                    todayNormalized,
                                    todayNormalized,
                                  );
                                }
                              },
                        child: const Text(_todayButtonText),
                      ),
                      // Solo mostrar si hay un filtro aplicado (al menos una fecha)
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

          // Mostrar advertencias si hay conexión activa pero también un error persistente (que no sea de re-autenticación o rango inválido)
          if (notifier.activeConnection != null &&
              notifier.errorMsg != null &&
              notifier
                  .isAuthenticated && // Autenticado pero con error (ej. red temporal al hacer polling, o API devolvió error)
              !notifier
                  .isLoading && // No mostrar si ya está el loader principal
              notifier.errorMsg != _reAuthenticatingMessageFromNotifier &&
              notifier.errorMsg !=
                  "La fecha final no puede ser anterior a la fecha de inicio." &&
              notifier.errorMsg !=
                  _uiNoConnectionSelectedMessage) // No mostrar como advertencia si es solo "sin conexión seleccionada"
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
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$_warningTitleText: ${notifier.errorMsg}',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Card de resumen (solo mostrar si hay conexión activa, autenticado y sin errores que impidan mostrar datos)
          if (showDateControlsAndSummary &&
              notifier.errorMsg == null) // Solo si no hay errores mayores
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20.0,
                  horizontal: 15.0,
                ),
                child: Column(
                  children: [
                    Text(
                      "$_summaryCardTitleText para ${notifier.activeConnection!.companyName}", // Incluir nombre de la empresa
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildDataRow(
                      '$_totalSalesLabelText (${summary.salesCount} $_invoicesCountSuffixText):',
                      // Usar NumberFormat para formato de moneda local
                      NumberFormat.currency(
                        locale: 'es_VE',
                        symbol: 'Bs. ',
                        decimalDigits: 2,
                      ).format(summary.totalSales),
                      valueColor: Colors.green.shade700,
                      fontSize: 14,
                    ),
                    const SizedBox(height: 5),
                    _buildDataRow(
                      '$_totalReturnsLabelText (${summary.returnsCount} $_returnsCountSuffixText):',
                      NumberFormat.currency(
                        locale: 'es_VE',
                        symbol: 'Bs. ',
                        decimalDigits: 2,
                      ).format(summary.totalReturns),
                      valueColor: Colors.red.shade600,
                      fontSize: 14,
                    ),
                    const Divider(
                      height: 35,
                      thickness: 0.8,
                      indent: 10,
                      endIndent: 10,
                    ),
                    _buildDataRow(
                      _totalTaxesLabelText,
                      NumberFormat.currency(
                        locale: 'es_VE',
                        symbol: 'Bs. ',
                        decimalDigits: 2,
                      ).format(summary.totalTax),
                      valueColor: Theme.of(context).primaryColorDark,
                      fontSize: 14,
                    ),
                  ],
                ),
              ),
            )
          // Mensaje si no hay conexión activa pero sí hay conexiones disponibles (invitando a seleccionar)
          else if (notifier.activeConnection == null &&
              notifier.availableConnections.isNotEmpty &&
              !notifier.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 50.0,
              ), // Más padding para centrar mejor
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 50,
                    color: Colors.blueGrey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Seleccione una empresa del listado superior para ver el resumen de ventas.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 25),

          // Mensaje de "Actualizando..." o "Datos en vivo"
          // Solo mostrar si hay conexión activa y no es el mensaje de re-autenticación (que ya se muestra)
          if (notifier.isLoading &&
              notifier.activeConnection != null &&
              notifier.errorMsg != _reAuthenticatingMessageFromNotifier)
            Row(
              // Loader secundario para polling o actualización de filtro
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 10),
                Text(
                  _updatingDataText,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            )
          else if (statusMessage
              .isNotEmpty) // Solo mostrar si hay mensaje de status
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

  // NUEVO: Método para navegar a la pantalla de configuración
  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConnectionSettingsScreen()),
    ).then((value) {
      // Al volver de la pantalla de configuración, refrescar la lista de conexiones.
      // El `value` podría usarse si ConnectionSettingsScreen devuelve algo útil (ej. la conexión recién añadida/editada)
      final notifier = Provider.of<InvoiceNotifier>(context, listen: false);
      notifier.refreshAvailableConnections(
        newlySelected: (value is ApiConnection
            ? value
            : notifier.activeConnection),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(_screenTitleText),
        actions: [
          // NUEVO: Botón para configurar conexiones
          IconButton(
            icon: const Icon(Icons.settings_applications_outlined),
            onPressed: () => _navigateToSettings(context),
            tooltip: _settingsTooltipText,
          ),
          // Botón de recargar (sin cambios en su lógica fundamental)
          Consumer<InvoiceNotifier>(
            builder: (context, notifier, child) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                // Deshabilitar si está cargando o si no hay conexión activa para recargar
                onPressed:
                    (notifier.isLoading || notifier.activeConnection == null)
                    ? null
                    : () {
                        // Decide si recargar con el filtro actual o datos iniciales
                        if (notifier.startDate != null ||
                            notifier.endDate != null) {
                          notifier.filterByDateRange(
                            notifier.startDate,
                            notifier.endDate,
                          );
                        } else {
                          notifier
                              .fetchInitialData(); // Llama a fetchInitialData para la conexión activa
                        }
                      },
                tooltip: _reloadDataTooltipText,
              );
            },
          ),
        ],
      ),
      body: Consumer<InvoiceNotifier>(
        builder: (context, notifier, child) {
          // Widget para el selector de empresa, se muestra siempre que haya conexiones o se estén cargando
          Widget companySelector = _buildCompanySelector(notifier, context);

          Widget bodyContent;

          // Caso 1: Cargando la lista de conexiones por primera vez (y no hay ninguna aún)
          if (notifier.isLoading &&
              notifier.availableConnections.isEmpty &&
              notifier.activeConnection == null) {
            bodyContent = _buildLoadingState(
              message: "Verificando conexiones guardadas...",
              notifier: notifier,
            );
          }
          // Caso 2: No hay conexiones configuradas (y ya terminó de cargar la lista)
          else if (notifier.availableConnections.isEmpty &&
              !notifier.isLoading) {
            bodyContent = _buildErrorState(
              notifier,
              context,
            ); // Mostrará "Sin Conexiones" y botón a config
          }
          // Caso 3: Hay conexiones pero ninguna activa (y no está cargando datos para alguna)
          // Esto es manejado por _buildDataDisplay que mostrará un mensaje para seleccionar.
          // O si el errorMsg es _uiNoConnectionSelectedMessage, _buildErrorState lo podría manejar.
          else if (notifier.activeConnection == null &&
              notifier.availableConnections.isNotEmpty &&
              !notifier.isLoading) {
            // Si el error específico es de no selección, el _buildErrorState lo maneja bien con su lógica interna.
            // Si no hay error pero no hay conexión activa (ej. al inicio con conexiones disponibles),
            // _buildDataDisplay mostrará el mensaje de "Seleccione empresa..."
            bodyContent = SingleChildScrollView(
              child: _buildDataDisplay(notifier, context),
            );
          }
          // Caso 4: Cargando datos para una conexión activa (ya sea inicial, por filtro, o por polling)
          else if (notifier.isLoading && notifier.activeConnection != null) {
            // Si es una carga donde NO hay datos previos para mostrar (resumen vacío)
            if (notifier.invoiceSummary.salesCount == 0 &&
                notifier.invoiceSummary.returnsCount == 0 &&
                notifier.errorMsg != _reAuthenticatingMessageFromNotifier) {
              bodyContent = _buildLoadingState(
                notifier: notifier,
              ); // Loader principal
            } else {
              // Hay datos antiguos o se está re-autenticando, mostrar la UI normal.
              // El indicador de "Actualizando..." dentro de _buildDataDisplay se encargará si es polling.
              bodyContent = SingleChildScrollView(
                child: _buildDataDisplay(notifier, context),
              );
            }
          }
          // Caso 5: Error específico (API, Red, Autenticación) para la conexión activa
          // (Excluyendo el mensaje de "sin conexión seleccionada" o error de rango, que se manejan en DataDisplay)
          else if (notifier.activeConnection != null &&
              notifier.errorMsg != null &&
              notifier.errorMsg != _uiNoConnectionSelectedMessage &&
              notifier.errorMsg !=
                  "La fecha final no puede ser anterior a la fecha de inicio.") {
            bodyContent = _buildErrorState(notifier, context);
          }
          // Caso 6: Conexión activa, autenticada y sin errores (o con error de rango que se muestra en DataDisplay)
          else if (notifier.activeConnection != null &&
              notifier.isAuthenticated) {
            bodyContent = SingleChildScrollView(
              child: _buildDataDisplay(notifier, context),
            );
          }
          // Caso 7: Fallback - podría ser un estado de error no autenticado para la conexión activa
          else {
            bodyContent = _buildErrorState(notifier, context);
          }

          return Column(
            children: [
              companySelector, // Mostrar siempre el selector si hay conexiones o se está cargando la lista
              Expanded(child: Center(child: bodyContent)),
            ],
          );
        },
      ),
    );
  }
}

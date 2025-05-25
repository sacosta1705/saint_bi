import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saint_bi/providers/invoice_notifier.dart'; // Ajusta la ruta si es necesario

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  @override
  void initState() {
    super.initState();
    // Iniciar la carga de datos cuando el widget se construye por primera vez
    // Usamos addPostFrameCallback para asegurarnos de que el context esté disponible
    // y evitar errores si se llama a notifyListeners durante la construcción.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Puedes decidir si quieres iniciar la carga automáticamente o con un botón.
      // Para este ejemplo, iniciaremos con un botón en la UI si no está autenticado.
      // Si quieres cargar automáticamente:
      // Provider.of<InvoiceNotifier>(context, listen: false).fetchInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturas Saint - En Vivo 📊'),
        actions: [
          // Botón de recarga manual
          Consumer<InvoiceNotifier>(
            builder: (context, notifier, child) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: notifier.isLoading
                    ? null
                    : () {
                        // Deshabilita si ya está cargando
                        notifier.fetchInitialData();
                      },
                tooltip: 'Recargar Datos',
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Consumer<InvoiceNotifier>(
          builder: (context, notifier, child) {
            // Estado de Carga Inicial (antes del primer intento de login)
            if (notifier.isLoading &&
                !notifier.isAuthenticated &&
                notifier.invoiceCount == 0) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Conectando con la API..."),
                ],
              );
            }

            // Si no está autenticado (después del intento inicial o si falló)
            if (!notifier.isAuthenticated) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 60,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      notifier.errorMsg ??
                          'No se ha podido conectar con el servidor API.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Asegúrate de haber configurado correctamente la URL base, credenciales y que el Saint Sync Server esté accesible.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('Intentar Conectar / Autenticar'),
                      onPressed: notifier.isLoading
                          ? null
                          : () {
                              notifier.fetchInitialData();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Autenticado y mostrando datos
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Mensaje de error/advertencia durante el polling (si no es un error de autenticación)
                  if (notifier.errorMsg != null &&
                      notifier.isAuthenticated &&
                      !notifier.isLoading)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Advertencia: ${notifier.errorMsg}',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Text(
                    'Número Total de Facturas de Venta Registradas:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${notifier.invoiceCount}',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Indicador sutil de que el polling está activo y cargando en segundo plano
                  if (notifier.isLoading &&
                      notifier.isAuthenticated &&
                      notifier.invoiceCount > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Actualizando...",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    )
                  else if (notifier
                      .isAuthenticated) // Para mostrar cuándo fue la última vez que se intentó (incluso si hubo error no fatal)
                    Text(
                      "Datos en vivo. Actualizando periódicamente.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

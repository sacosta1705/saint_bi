class AppConstants {
  // Mensajes para la UI
  static const String authErrorMessage =
      'Error de autenticación. Revise credenciales o URL.';
  static const String sessionExpiredMessage =
      'Sesión expirada. Intentando re-autenticar...';
  static const String genericErrorMessage =
      'Error al comunicarse con el servidor.';
  static const String networkErrorMessage =
      'Error de red. Verifique su conexión a internet.';
  static const String noConnectionSelectedMessage =
      'Seleccione o configure una conexión de empresa.';
  static const String noConnectionsAvailableMessage =
      'No hay conexiones configuradas. Por favor, añada una.';

  // Tooltips y etiquetas
  static const String reloadDataTooltipText = 'Recargar Datos';
  static const String settingsTooltipText = 'Configurar Conexiones';
  static const String logoutTooltipText = 'Cerrar Sesión';
  static const String tryConnectButtonLabel = 'Intentar Conectar / Reintentar';
  static const String goToSettingsButtonText = 'Ir a Configuración';

  // Tipos de Documentos de Facturación
  static const String invoiceTypeSale = 'A';
  static const String invoiceTypeReturn = 'B';

  // Tipos de Documentos de Compra
  static const String purchaseTypeInvoice = 'H';
  static const String purchaseTypeReturn = 'I';

  // Otros tipos (ejemplos, añadir los que falten)
  static const String receivableTypeAdvance = '50';
  static const String payableTypeAdvance = '50';
}

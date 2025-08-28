import 'package:flutter/material.dart';

class AppColors {
  // Paleta Principal
  static const Color primaryBlue = Color(0xFF0D47A1);
  static const Color primaryDarkBlue = Color(0xFF002171);
  static const Color accentOrange = Color(0xFFFF6F00);

  // Fondos
  static const Color scaffoldBackground = Color(0xFFF0F2F5);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Texto
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6E6E73);
  static const Color textOnPrimary = Colors.white;

  // Colores Semánticos
  static const Color positiveValue = Color(0xFF28A745);
  static const Color negativeValue = Color(0xFFDC3545);
  static const Color neutralValue = primaryBlue;

  // UI
  static const Color iconColor = Color(0xFF8A8A8E);
  static const Color dividerColor = Color(0xFFE5E5EA);

  // Degradados para Tarjetas de KPI
  static const Gradient kpiGradientBlue = LinearGradient(
    colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient kpiGradientGreen = LinearGradient(
    colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient kpiGradientOrange = LinearGradient(
    colors: [Color(0xFFFB8C00), Color(0xFFE65100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient kpiGradientRed = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Colores Principales
  static const Color primaryOrange = Color(0xFFF36B21);
  static const Color textOnPrimaryBlue = Colors.white;
  static const Color textOnPrimaryOrange = Colors.white;
  static const Color textLight = Colors.white70;
  static const Color dialogBackground = Colors.white;
  static const Color accentColor = Color.fromARGB(255, 241, 120, 55);
  static const Color iconOnPrimary = Colors.white;

  static const Color buttonPrimaryBackground = primaryBlue;
  static const Color buttonPrimaryText = textOnPrimaryBlue;

  static const Color buttonSecondaryBackground = primaryOrange;
  static const Color buttonSecondaryText = textOnPrimaryOrange;

  static const Color inputBorderColor = Colors.grey;
  static const Color inputFocusedBorderColor = primaryBlue;
  static const Color inputPrefixIconColor = primaryBlue;

  static const Color appBarBackground = primaryBlue;
  static const Color appBarForeground = textOnPrimaryBlue;

  // Colores para mensajes de estado
  static const Color statusMessageInfo = Colors.blueGrey;
  static const Color statusMessageWarning = Colors.orange;
  static const Color statusMessageError = Color(0xFFD32F2F);
  static const Color statusMessageSuccess = Colors.green;

  // Colores para el Dropdown
  static const Color dropdownFillColor = Colors.white;
  static const Color dropdownBorderColor = Colors.grey;
  static const Color dropdownFocusedBorderColor = primaryBlue;
  static const Color dropdownIconColor = primaryBlue;
  static const Color dropdownHintColor = Colors.black54;
  static const Color dropdownTextColor = textPrimary;
}

import 'package:flutter/material.dart';

class AppColors {
  // Colores Principales
  static const Color primaryBlue = Color(0xFF253279);
  static const Color primaryOrange = Color(0xFFF36B21);

  // Colores de Texto
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimaryBlue = Colors.white;
  static const Color textOnPrimaryOrange = Colors.white;
  static const Color textLight = Colors.white70;

  // Colores de Fondo
  static const Color scaffoldBackground = Color(0xFFF4F6F8);
  static const Color cardBackground = Colors.white;
  static const Color dialogBackground = Colors.white;

  // Colores de Énfasis y Acento
  static const Color accentColor = primaryOrange;
  static const Color positiveValue = Colors.green;
  static const Color negativeValue = Colors.red;
  static const Color neutralValue = primaryBlue;

  // Colores de UI Adicionales
  static const Color iconColor = Color(0xFF757575);
  static const Color iconOnPrimary = Colors.white;
  static const Color dividerColor = Color(0xFFE0E0E0);

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

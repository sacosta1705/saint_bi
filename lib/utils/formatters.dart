import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String getDeviceLocale(BuildContext context) {
  return Localizations.localeOf(context).toString();
}

String formatNumber(double number, String locale) {
  if (number.abs() < 1000000) {
    return NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    ).format(number);
  } else {
    return NumberFormat.compact(locale: locale).format(number);
  }
}

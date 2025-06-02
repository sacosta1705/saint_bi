import 'package:saint_bi/models/purchase.dart';

class PurchaseParser {
  static Purchase fromJson(Map<String, dynamic> json) {
    try {
      final String uniqueNum = _parseString(json['nrounico'], 'nrounico');
      final String type = _parseString(json['tipocom'], 'tipocom');
      final String docNumber = _parseString(json['numerod'], 'numerod');
      final double exchange = _parseDouble(json['factor'], 'factor');
      final double amountEx = _parseDouble(json['montomex'], 'montomex');
      final double amount = _parseDouble(json['monto'], 'monto');
      final double amountTax = _parseDouble(json['mtotax'], 'mtotax');
      final double debit = _parseDouble(json['contado'], 'contado');
      final double credit = _parseDouble(json['credito'], 'credito');
      final String date = _parseString(json['fechae'], 'fechae');

      return Purchase(
        uniqueNum: uniqueNum,
        type: type,
        docNumber: docNumber,
        exchange: exchange,
        amountEx: amountEx,
        amount: amount,
        amountTax: amountTax,
        debit: debit,
        credit: credit,
        date: date,
      );
    } catch (e) {
      rethrow;
    }
  }

  static String _parseString(
    dynamic value,
    String fieldName, {
    String defaultValue = '',
  }) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString().isNotEmpty ? value.toString() : defaultValue;
  }

  static double _parseDouble(
    dynamic value,
    String fieldName, {
    double defaultValue = 0.0,
  }) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
      return defaultValue;
    }

    return defaultValue;
  }
}

import 'package:flutter/material.dart';

import 'package:saint_bi/models/invoice.dart';

class InvoiceParser {
  static Invoice fromJson(Map<String, dynamic> json) {
    try {
      final String docNumber = _parseString(json['numerod'], 'numerod');
      final String type = _parseString(json['tipofac'], 'tipofac');
      final String clientId = _parseString(json['codclie'], 'codclie');
      final String clientName = _parseString(json['descrip'], 'client_descrip');
      final String salesPerson = _parseString(json['codvend'], 'codvend');
      final double amount = _parseDouble(json['monto'], 'monto');
      final double amountEx = _parseDouble(json['montomex'], 'montomex');
      final double amountTax = _parseDouble(json['mtotax'], 'mtotax');
      final double exchange = _parseDouble(json['factor'], 'factor');
      final String date = _parseString(json['fechae'], 'fechae');

      debugPrint(
        'Parsed fields: doc=$docNumber, type=$type, clientID=$clientId, client=$clientName, amount=$amount',
      );

      return Invoice(
        docnumber: docNumber,
        clientid: clientId,
        client: clientName,
        type: type,
        salesperson: salesPerson,
        amount: amount,
        amountex: amountEx,
        amounttax: amountTax,
        exchange: exchange,
        date: date,
      );
    } catch (e) {
      debugPrint(
        'CRITICAL: Error al parsear Invoice JSON. Objeto JSON: $json. Error: ${e.toString()}',
      );
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
    if (value == null) {
      debugPrint(
        'Campo double nulo: "$fieldName". Usando valor por defecto: $defaultValue',
      );
      return defaultValue;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
      debugPrint(
        'No se pudo parsear String a double para el campo "$fieldName": "$value". Usando valor por defecto: $defaultValue',
      );
      return defaultValue;
    }
    debugPrint(
      'Tipo inesperado para double "$fieldName": ${value.runtimeType} (Valor: "$value"). Usando valor por defecto: $defaultValue',
    );
    return defaultValue;
  }
}

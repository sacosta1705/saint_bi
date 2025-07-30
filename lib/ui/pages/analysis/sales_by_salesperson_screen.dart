// lib/ui/pages/analysis/sales_by_salesperson_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:saint_bi/core/bloc/summary/summary_bloc.dart';
import 'package:saint_bi/core/data/models/invoice.dart';
import 'package:saint_bi/core/utils/constants.dart';
import 'package:saint_bi/core/utils/formatters.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';

class SalesBySalespersonScreen extends StatelessWidget {
  const SalesBySalespersonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final summaryState = context.watch<SummaryBloc>().state;
    final deviceLocale = getDeviceLocale(context);

    // 1. Procesar los datos
    final salesBySalesperson = _calculateSalesBySalesperson(
      summaryState.allInvoices,
    );

    // Determinar el valor máximo para el eje Y, con un margen del 20%
    final double maxY = salesBySalesperson.isEmpty
        ? 100
        : salesBySalesperson.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return Scaffold(
      appBar: AppBar(title: const Text('Top 10 Vendedores por Ventas')),
      body: salesBySalesperson.isEmpty
          ? const Center(
              child: Text(
                'No hay datos de ventas para mostrar.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: salesBySalesperson.length * 70.0,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final salesperson = salesBySalesperson.keys.elementAt(
                            group.x,
                          );
                          final amount = rod.toY;
                          return BarTooltipItem(
                            '$salesperson\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: formatNumber(amount, deviceLocale),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final salesperson = salesBySalesperson.keys
                                .elementAt(value.toInt());
                            return SideTitleWidget(
                              meta: meta,
                              space: 4.0,
                              child: Text(
                                salesperson,
                                style: const TextStyle(fontSize: 10),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                          reservedSize: 32,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const Text('');

                            return SideTitleWidget(
                              meta: meta,
                              space: 4.0,
                              child: Text(
                                NumberFormat.compact().format(value),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    barGroups: salesBySalesperson.entries
                        .mapIndexed(
                          (index, entry) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value,
                                color: AppColors.primaryBlue,
                                width: 25,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
    );
  }

  Map<String, double> _calculateSalesBySalesperson(List<Invoice> invoices) {
    // Filtrar solo ventas y agrupar por vendedor
    final groupedSales = groupBy(
      invoices.where((inv) => inv.type == AppConstants.invoiceTypeSale),
      (Invoice inv) => inv.salesperson,
    );

    // Sumar los montos para cada vendedor
    final salesMap = groupedSales.map((salesperson, invoices) {
      final totalAmount = invoices.fold(0.0, (sum, inv) => sum + inv.amount);
      return MapEntry(salesperson, totalAmount);
    });

    // Ordenar de mayor a menor y tomar el top 10
    final sortedEntries = salesMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = sortedEntries.take(10);

    return Map.fromEntries(topEntries);
  }
}

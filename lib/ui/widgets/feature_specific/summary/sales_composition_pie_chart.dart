import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:saint_bi/core/data/models/management_summary.dart';
import 'package:saint_bi/core/utils/formatters.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';

class SalesCompositionPieChart extends StatelessWidget {
  final ManagementSummary summary;

  const SalesCompositionPieChart({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final deviceLocale = getDeviceLocale(context);
    final totalSales = summary.totalNetSales;

    // Evitar división por cero si no hay ventas
    if (totalSales == 0) {
      return const SizedBox.shrink();
    }

    final creditPercentage = (summary.totalNetSalesCredit / totalSales) * 100;
    final cashPercentage = (summary.totalNetSalesCash / totalSales) * 100;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Composición de Ventas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDarkBlue,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: AppColors.primaryBlue,
                      value: summary.totalNetSalesCredit,
                      title: '${creditPercentage.toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: AppColors.accentOrange,
                      value: summary.totalNetSalesCash,
                      title: '${cashPercentage.toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildLegend(
              color: AppColors.primaryBlue,
              text: 'Ventas a Crédito',
              value: formatNumber(summary.totalNetSalesCredit, deviceLocale),
            ),
            const SizedBox(height: 8),
            _buildLegend(
              color: AppColors.accentOrange,
              text: 'Ventas de Contado',
              value: formatNumber(summary.totalNetSalesCash, deviceLocale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend({
    required Color color,
    required String text,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

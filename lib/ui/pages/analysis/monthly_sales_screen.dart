import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:saint_bi/core/bloc/monthly_sales/monthly_sales_bloc.dart';
import 'package:saint_bi/core/utils/chart_utils.dart'; // <-- IMPORTAR NUEVA UTILIDAD
import 'package:saint_bi/core/utils/formatters.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';

class MonthlySalesScreen extends StatefulWidget {
  const MonthlySalesScreen({super.key});

  @override
  State<MonthlySalesScreen> createState() => _MonthlySalesScreenState();
}

class _MonthlySalesScreenState extends State<MonthlySalesScreen> {
  @override
  void initState() {
    super.initState();
    final currentYear = context.read<MonthlySalesBloc>().state.year;
    context.read<MonthlySalesBloc>().add(MonthlySalesYearChanged(currentYear));
  }

  void _changeYear(int increment) {
    final newYear = context.read<MonthlySalesBloc>().state.year + increment;
    context.read<MonthlySalesBloc>().add(MonthlySalesYearChanged(newYear));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ventas Anuales por Mes')),
      body: BlocBuilder<MonthlySalesBloc, MonthlySalesState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildYearSelector(state),
              Expanded(
                child: Center(
                  child: switch (state.status) {
                    MonthlySalesStatus.loading =>
                      const CircularProgressIndicator(),
                    MonthlySalesStatus.failure => Text(
                      'Error: ${state.error ?? "Desconocido"}',
                    ),
                    MonthlySalesStatus.success =>
                      state.monthlySales.values.every((v) => v == 0)
                          ? const Text(
                              'No hay datos de ventas para el año seleccionado.',
                            )
                          : _MonthlySalesBarChart(
                              salesData: state.monthlySales,
                            ),
                    _ => const Text('Seleccione un año para ver las ventas.'),
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildYearSelector(MonthlySalesState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: state.status == MonthlySalesStatus.loading
                    ? null
                    : () => _changeYear(-1),
                tooltip: 'Año Anterior',
              ),
              Text(
                state.year.toString(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: state.status == MonthlySalesStatus.loading
                    ? null
                    : () => _changeYear(1),
                tooltip: 'Año Siguiente',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthlySalesBarChart extends StatelessWidget {
  final Map<int, double> salesData;

  const _MonthlySalesBarChart({required this.salesData});

  @override
  Widget build(BuildContext context) {
    final deviceLocale = getDeviceLocale(context);
    final List<Color> barColors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.red.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.cyan.shade300,
      Colors.pink.shade300,
      Colors.teal.shade300,
      Colors.amber.shade300,
      Colors.indigo.shade300,
      Colors.brown.shade300,
      Colors.lime.shade300,
    ];

    final salesValues = salesData.values.where((v) => v > 0);
    final double maxValue = salesValues.isNotEmpty
        ? salesValues.reduce((a, b) => a > b ? a : b)
        : 0;
    final double maxY = maxValue * 1.2;

    // --- SE USA LA FUNCIÓN GLOBAL ---
    final double interval = getEfficientInterval(maxY);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        width: 600,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final month = _getMonthName(group.x);
                  return BarTooltipItem(
                    '$month\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: formatNumber(rod.toY, deviceLocale),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: interval,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const Text('');
                    return Text(
                      NumberFormat.compact().format(value),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Text(
                    _getMonthName(value.toInt()),
                    style: const TextStyle(fontSize: 10),
                  ),
                  reservedSize: 20,
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
            ),
            borderData: FlBorderData(show: false),
            barGroups: salesData.entries
                .mapIndexed(
                  (index, entry) => BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: barColors[index % barColors.length],
                        width: 22,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return monthNames[month];
  }
}

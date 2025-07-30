// lib/ui/pages/analysis/ols_forecast_screen.dart

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:saint_bi/core/bloc/summary/summary_bloc.dart';
import 'package:saint_bi/core/data/models/analysis/time_series_point.dart';
import 'package:saint_bi/core/services/analysis/forecasting_service.dart';
import 'package:saint_bi/core/utils/constants.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';
import 'dart:math';

class OLSForecastScreen extends StatefulWidget {
  const OLSForecastScreen({super.key});

  @override
  State<OLSForecastScreen> createState() => _OLSForecastScreenState();
}

class _OLSForecastScreenState extends State<OLSForecastScreen> {
  final _forecastingService = ForecastingService();
  List<TimeSeriesPoint> _historicalSales = [];
  List<TimeSeriesPoint> _displayHistoricalData = [];
  List<TimeSeriesPoint> _displayTrendLine = [];
  List<TimeSeriesPoint> _displayForecastedData = [];

  bool _isLoading = true;
  int _forecastedPeriods = 12;

  // MODIFICACIÓN 1: El valor por defecto ahora es mensual.
  Set<ChartGranularity> _selection = {ChartGranularity.monthly};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _prepareAndRunForecast());
  }

  void _prepareAndRunForecast() {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final summaryState = context.read<SummaryBloc>().state;

    if (_historicalSales.isEmpty && summaryState.allInvoices.isNotEmpty) {
      final Map<DateTime, double> dailyTotals = {};
      for (var invoice in summaryState.allInvoices.where(
        (inv) => inv.type == AppConstants.invoiceTypeSale,
      )) {
        try {
          final date = DateFormat('yyyy-MM-dd').parse(invoice.date, true);
          dailyTotals.update(
            date,
            (value) => value + invoice.amount,
            ifAbsent: () => invoice.amount,
          );
        } catch (e) {
          // Ignorar fechas inválidas
        }
      }
      _historicalSales = dailyTotals.entries
          .map((e) => TimeSeriesPoint(time: e.key, value: e.value))
          .toList();
      _historicalSales.sort((a, b) => a.time.compareTo(b.time));
    }

    final selectedGranularity = _selection.first;
    List<TimeSeriesPoint> aggregatedData = _aggregateData(
      _historicalSales,
      selectedGranularity,
    );
    _displayHistoricalData = aggregatedData;

    // MODIFICACIÓN 2: Se cambia el mínimo de 2 a 3 puntos de datos.
    if (aggregatedData.length >= 3) {
      final result = _forecastingService.calculateOLSForecast(
        historicalData: aggregatedData,
        periodsToForecast: _forecastedPeriods,
        granularity: selectedGranularity,
      );
      _displayTrendLine = result.trendLine;
      _displayForecastedData = result.forecastedPoints;
    } else {
      _displayTrendLine = [];
      _displayForecastedData = [];
    }

    if (mounted) setState(() => _isLoading = false);
  }

  List<TimeSeriesPoint> _aggregateData(
    List<TimeSeriesPoint> dailyData,
    ChartGranularity granularity,
  ) {
    if (dailyData.isEmpty) return [];

    final groups = groupBy(dailyData, (TimeSeriesPoint p) {
      switch (granularity) {
        // Casos 'daily' y 'weekly' eliminados
        case ChartGranularity.monthly:
          return '${p.time.year}-${p.time.month}';
        case ChartGranularity.yearly:
          return p.time.year;
        default:
          return '${p.time.year}-${p.time.month}'; // Default a mensual
      }
    });

    return groups.entries.map((entry) {
      final totalValue = entry.value
          .map((p) => p.value)
          .reduce((a, b) => a + b);
      // Aseguramos que la fecha representativa sea el inicio del período
      DateTime representativeDate;
      switch (granularity) {
        case ChartGranularity.monthly:
          representativeDate = DateTime(
            entry.value.first.time.year,
            entry.value.first.time.month,
            1,
          );
          break;
        case ChartGranularity.yearly:
          representativeDate = DateTime(entry.value.first.time.year, 1, 1);
          break;
        default:
          representativeDate = entry.value.first.time;
      }
      return TimeSeriesPoint(time: representativeDate, value: totalValue);
    }).toList()..sort((a, b) => a.time.compareTo(b.time));
  }

  @override
  Widget build(BuildContext context) {
    // MODIFICACIÓN 3: Mensaje de error actualizado para reflejar el nuevo mínimo.
    final bool hasEnoughData = _displayHistoricalData.length >= 3;

    return Scaffold(
      appBar: AppBar(title: const Text('Proyección de Ventas (Lineal)')),
      body: !hasEnoughData && !_isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Se necesitan datos de al menos 3 períodos (meses o años) para generar una proyección lineal confiable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          : Column(
              children: [
                _buildControls(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                          child: SizedBox(
                            width:
                                (_displayHistoricalData.length +
                                    _displayForecastedData.length) *
                                80.0, // Más ancho
                            child: LineChart(_buildChartData()),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Parámetros del Modelo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // MODIFICACIÓN 4: Se eliminan los botones 'Diario' y 'Semanal'.
              SegmentedButton<ChartGranularity>(
                segments: const [
                  ButtonSegment(
                    value: ChartGranularity.monthly,
                    label: Text('Mensual'),
                  ),
                  ButtonSegment(
                    value: ChartGranularity.yearly,
                    label: Text('Anual'),
                  ),
                ],
                selected: _selection,
                onSelectionChanged: (newSelection) {
                  if (newSelection.isNotEmpty) {
                    setState(() {
                      _selection = newSelection;
                      _prepareAndRunForecast();
                    });
                  }
                },
              ),
              Row(
                children: [
                  const Text(
                    'Períodos a proyectar:',
                    style: TextStyle(fontSize: 13),
                  ),
                  Expanded(
                    child: Slider(
                      value: _forecastedPeriods.toDouble(),
                      min: 1,
                      max: 24,
                      divisions: 23,
                      label: _forecastedPeriods.toString(),
                      onChanged: (v) =>
                          setState(() => _forecastedPeriods = v.round()),
                      onChangeEnd: (v) => _prepareAndRunForecast(),
                    ),
                  ),
                  Text(_forecastedPeriods.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  LineChartData _buildChartData() {
    final historicalSpots = _displayHistoricalData
        .mapIndexed((i, e) => FlSpot(i.toDouble(), e.value))
        .toList();
    final trendSpots = _displayTrendLine
        .mapIndexed((i, e) => FlSpot(i.toDouble(), e.value))
        .toList();

    List<FlSpot> forecastSpots = [];
    if (trendSpots.isNotEmpty) {
      forecastSpots.add(trendSpots.last); // Conectar la línea
      forecastSpots.addAll(
        _displayForecastedData.mapIndexed(
          (i, e) => FlSpot((historicalSpots.length + i).toDouble(), e.value),
        ),
      );
    }

    final allValues = [
      ..._displayHistoricalData.map((p) => p.value),
      ..._displayForecastedData.map((p) => p.value),
    ];
    double maxY = 100;
    if (allValues.isNotEmpty) {
      maxY = allValues.reduce(max) * 1.2;
    }

    return LineChartData(
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: historicalSpots,
          isCurved: false,
          color: AppColors.primaryBlue,
          barWidth: 2.5,
          dotData: const FlDotData(show: true),
        ),
        LineChartBarData(
          spots: trendSpots,
          isCurved: false,
          color: AppColors.primaryOrange,
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: forecastSpots,
          isCurved: false,
          color: AppColors.primaryOrange,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          dashArray: [5, 5],
        ),
      ],
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              if (value == 0 || value >= maxY) return const SizedBox.shrink();
              return SideTitleWidget(
                meta: meta,
                space: 4,
                child: Text(
                  NumberFormat.compact().format(value),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              final allPoints = [
                ..._displayHistoricalData,
                ..._displayForecastedData,
              ];
              if (index >= allPoints.length) return const SizedBox.shrink();

              final date = allPoints[index].time;
              String text = '';
              switch (_selection.first) {
                case ChartGranularity.monthly:
                  text = DateFormat('MMM yy', 'es_ES').format(date);
                  break;
                case ChartGranularity.yearly:
                  text = DateFormat('yyyy').format(date);
                  break;
                default:
                  text = DateFormat('dd/MM').format(date);
                  break;
              }
              return SideTitleWidget(
                meta: meta,
                space: 4,
                child: Text(text, style: const TextStyle(fontSize: 10)),
              );
            },
          ),
        ),
      ),
    );
  }
}

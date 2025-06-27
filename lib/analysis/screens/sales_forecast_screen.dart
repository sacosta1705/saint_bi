import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import 'package:saint_intelligence/analysis/models/time_series_point.dart';
import 'package:saint_intelligence/analysis/services/forecasting_service.dart';
import 'package:saint_intelligence/config/app_colors.dart';
import 'package:saint_intelligence/providers/managment_summary_notifier.dart';

enum ChartGranularity { daily, weekly, monthly, yearly }

class SalesForecastScreen extends StatefulWidget {
  const SalesForecastScreen({super.key});

  @override
  State<SalesForecastScreen> createState() => _SalesForecastScreenState();
}

class _SalesForecastScreenState extends State<SalesForecastScreen> {
  final _forecastingService = ForecastingService();
  List<TimeSeriesPoint> _historicalSales = [];
  List<TimeSeriesPoint> _displayHistoricalData = [];
  List<TimeSeriesPoint> _displayForecastedData = [];

  bool _isLoading = false;
  int _forecastedPeriods = 12;
  double _alpha = 0.4;

  Set<ChartGranularity> _selection = {ChartGranularity.daily};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _prepareAndRunForecast());
  }

  void _prepareAndRunForecast() {
    if (!mounted) return;

    setState(() => _isLoading = true);

    final notifier =
        Provider.of<ManagementSummaryNotifier>(context, listen: false);

    if (_historicalSales.isEmpty) {
      final Map<DateTime, double> dailySales = {};
      for (var invoice in notifier.allInvoices) {
        if (invoice.type == 'A') {
          try {
            final date = DateFormat('yyyy-MM-dd').parse(invoice.date, true);
            dailySales.update(date, (value) => value + invoice.amount,
                ifAbsent: () => invoice.amount);
          } catch (e) {}
        }
      }
      _historicalSales = dailySales.entries
          .map((entry) => TimeSeriesPoint(time: entry.key, value: entry.value))
          .toList();
      _historicalSales.sort((a, b) => a.time.compareTo(b.time));
    }

    final selectedGranularity = _selection.first;
    List<TimeSeriesPoint> historicalForForecast = [];

    switch (selectedGranularity) {
      case ChartGranularity.daily:
        historicalForForecast = _historicalSales;
        break;
      case ChartGranularity.weekly:
        historicalForForecast = _aggregateDataByWeek(_historicalSales);
        break;
      case ChartGranularity.monthly:
        historicalForForecast = _aggregateDataByMonth(_historicalSales);
        break;
      case ChartGranularity.yearly:
        historicalForForecast = _aggregateDataByYear(_historicalSales);
        break;
    }

    _displayHistoricalData = historicalForForecast;

    if (selectedGranularity != ChartGranularity.yearly &&
        historicalForForecast.isNotEmpty) {
      _displayForecastedData = _forecastingService.calculateSES(
        historicalData: historicalForForecast,
        periodsToForecast: _forecastedPeriods,
        alpha: _alpha,
      );
    } else {
      _displayForecastedData = [];
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
  }

  List<TimeSeriesPoint> _aggregateDataByWeek(List<TimeSeriesPoint> dailyData) {
    final weeklyGroups =
        groupBy(dailyData, (p) => '${p.time.year}-${_weekNumber(p.time)}');
    return weeklyGroups.values.map((pointsInWeek) {
      final totalValue =
          pointsInWeek.map((p) => p.value).reduce((a, b) => a + b);
      final representativeDate = pointsInWeek.first.time;
      return TimeSeriesPoint(time: representativeDate, value: totalValue);
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  List<TimeSeriesPoint> _aggregateDataByMonth(List<TimeSeriesPoint> dailyData) {
    final monthlyGroups =
        groupBy(dailyData, (p) => '${p.time.year}-${p.time.month}');

    return monthlyGroups.values.map((pointsInMoth) {
      final totalValue =
          pointsInMoth.map((p) => p.value).reduce((a, b) => a + b);
      final representativeDate = DateTime(
          pointsInMoth.first.time.year, pointsInMoth.first.time.month, 1);
      return TimeSeriesPoint(time: representativeDate, value: totalValue);
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  List<TimeSeriesPoint> _aggregateDataByYear(List<TimeSeriesPoint> dailyData) {
    final yearlyGroups = groupBy(dailyData, (p) => p.time.year);
    return yearlyGroups.values.map((pointsInYear) {
      final totalValue =
          pointsInYear.map((p) => p.value).reduce((a, b) => a + b);
      final representativeDate = DateTime(pointsInYear.first.time.year, 1, 1);
      return TimeSeriesPoint(time: representativeDate, value: totalValue);
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  int _weekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat("D").format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyeccion de ventas'),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Calculando proyeccion...'),
                ],
              ),
            )
          : _historicalSales.isEmpty
              ? const Center(
                  child: Text('No hay suficientes datos para una proyeccion.'),
                )
              : Column(
                  children: [
                    _buildControls(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
                        child: LineChart(_buildChartData()),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildControls() {
    final selectedGranularity = _selection.first;
    String forecastLabel;
    switch (selectedGranularity) {
      case ChartGranularity.daily:
        forecastLabel = 'Dias a proyectar';
        break;
      case ChartGranularity.weekly:
        forecastLabel = 'Semanas a proyectar';
        break;
      case ChartGranularity.monthly:
        forecastLabel = 'Meses a proyectar';
        break;
      case ChartGranularity.yearly:
        forecastLabel = 'Años a proyectar';
        break;
    }
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Parametros del Modelo (Suavizado Exponencial)'),
              SegmentedButton<ChartGranularity>(
                segments: [
                  ButtonSegment(
                      value: ChartGranularity.daily, label: Text('Diario')),
                  ButtonSegment(
                      value: ChartGranularity.daily, label: Text('Semanal')),
                  ButtonSegment(
                      value: ChartGranularity.daily, label: Text('Mensual')),
                  ButtonSegment(
                      value: ChartGranularity.daily, label: Text('Anual')),
                ],
                selected: _selection,
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selection = newSelection;
                    _prepareAndRunForecast();
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('$forecastLabel:'),
                  Expanded(
                    child: Slider(
                      value: _forecastedPeriods.toDouble(),
                      min: 1,
                      max: selectedGranularity == ChartGranularity.daily
                          ? 90
                          : 24,
                      divisions: selectedGranularity == ChartGranularity.daily
                          ? 89
                          : 23,
                      label: _forecastedPeriods.toString(),
                      onChanged: (v) =>
                          setState(() => _forecastedPeriods = v.round()),
                      onChangeEnd: (v) => _prepareAndRunForecast(),
                    ),
                  ),
                  Text(_forecastedPeriods.toString())
                ],
              ),
              Row(
                children: [
                  const Text('Sensibilidad:'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Slider(
                      value: _alpha,
                      min: 0.1,
                      max: 0.9,
                      divisions: 8,
                      label: _alpha.toStringAsPrecision(1),
                      onChanged: (value) {
                        setState(
                          () {
                            _alpha = value;
                          },
                        );
                      },
                      onChangeEnd: (value) => _prepareAndRunForecast(),
                    ),
                  ),
                  Text(_alpha.toStringAsPrecision(1))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  LineChartData _buildChartData() {
    final List<FlSpot> historicalSpots = _displayHistoricalData
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();
    final List<FlSpot> forecastSpots = [];

    if (_displayForecastedData.isNotEmpty) {
      forecastSpots.add(historicalSpots.last);
      for (int i = 0; i < _displayForecastedData.length; i++) {
        forecastSpots.add(FlSpot(
            (historicalSpots.length - 1 + i + 1).toDouble(),
            _displayForecastedData[i].value));
      }
    }

    return LineChartData(
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: _getTooltipItems,
        ),
      ),
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: _bottomTitleWidgets)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        // Línea de datos históricos
        LineChartBarData(
          spots: historicalSpots,
          isCurved: true,
          color: AppColors.primaryBlue,
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
        // Línea de proyección
        LineChartBarData(
          spots: forecastSpots,
          isCurved: true,
          color: AppColors.primaryOrange,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          dashArray: [5, 5], // Línea punteada
        ),
      ],
    );
  }

  List<LineTooltipItem?> _getTooltipItems(List<LineBarSpot> touchedBarSpots) {
    return touchedBarSpots
        .map((barSpot) {
          final int index = barSpot.x.toInt();
          final isForecast = barSpot.barIndex == 1;
          final dataList =
              isForecast ? _displayForecastedData : _displayHistoricalData;
          final pointIndex =
              isForecast ? index - _displayHistoricalData.length : index;

          if (pointIndex < 0 || pointIndex >= dataList.length) return null;

          final timeSeriesPoint = dataList[pointIndex];
          final granularity = _selection.first;
          String dateText;

          switch (granularity) {
            case ChartGranularity.daily:
              dateText =
                  DateFormat('EEEm dd MMM yyyy').format(timeSeriesPoint.time);
              break;

            case ChartGranularity.weekly:
              dateText =
                  "Semana del ${DateFormat('dd/MM/yy').format(timeSeriesPoint.time)}";
              break;

            case ChartGranularity.monthly:
              dateText = DateFormat('MMMM yyyy').format(timeSeriesPoint.time);
              break;

            case ChartGranularity.yearly:
              dateText = DateFormat('yyyy').format(timeSeriesPoint.time);
              break;
          }

          return LineTooltipItem(
            '${timeSeriesPoint.value.toStringAsFixed(2)}\n',
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: dateText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          );
        })
        .whereType<LineTooltipItem>()
        .toList();
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10, color: Colors.black54);
    String text = '';
    int index = value.toInt();
    final granularity = _selection.first;
    final List<TimeSeriesPoint> dataList;
    final int pointIndex;

    if (index < _displayHistoricalData.length) {
      dataList = _displayHistoricalData;
      pointIndex = index;
    } else {
      dataList = _displayForecastedData;
      pointIndex = index - _displayHistoricalData.length;
    }

    if (pointIndex >= 0 && pointIndex < dataList.length) {
      final DateTime date = dataList[pointIndex].time;
      // Lógica de intervalo para evitar sobreposición en vistas densas.
      int interval = 1;
      if (granularity == ChartGranularity.daily) {
        interval = _displayHistoricalData.length > 30 ? 7 : 5;
      }
      if (granularity == ChartGranularity.weekly) {
        interval = _displayHistoricalData.length > 20 ? 2 : 1;
      }
      if (granularity == ChartGranularity.monthly) {
        interval = _displayHistoricalData.length > 24 ? 3 : 1;
      }

      if (index % interval == 0) {
        switch (granularity) {
          case ChartGranularity.daily:
            text = DateFormat('dd/MM').format(date);
            break;
          case ChartGranularity.weekly:
            text = DateFormat('dd/MM').format(date);
            break; // Muestra inicio de semana
          case ChartGranularity.monthly:
            text = DateFormat('MMM yy', 'es_ES').format(date);
            break;
          case ChartGranularity.yearly:
            text = DateFormat('yyyy').format(date);
            break;
        }
      }
    }

    return SideTitleWidget(
      meta: meta,
      space: 8.0,
      child: Text(text, style: style),
    );
  }
}

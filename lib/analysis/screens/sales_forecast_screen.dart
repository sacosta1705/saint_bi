import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import 'package:saint_intelligence/analysis/models/time_series_point.dart';
import 'package:saint_intelligence/analysis/services/forecasting_service.dart';
import 'package:saint_intelligence/config/app_colors.dart';
import 'package:saint_intelligence/providers/managment_summary_notifier.dart';

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

  bool _isLoading = true;
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
        granularity: selectedGranularity,
      );
    } else {
      _displayForecastedData = [];
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<TimeSeriesPoint> _aggregateDataByWeek(List<TimeSeriesPoint> dailyData) {
    if (dailyData.isEmpty) return [];
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
    if (dailyData.isEmpty) return [];
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
    if (dailyData.isEmpty) return [];
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
    final totalDataPoints =
        _displayHistoricalData.length + _displayForecastedData.length;
    final double pointWidth = 50.0;
    final double calculatedChartWidth = totalDataPoints * pointWidth;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyección de ventas'),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
      ),
      body: _historicalSales.isEmpty && _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Calculando proyección...'),
                ],
              ),
            )
          : _historicalSales.isEmpty && !_isLoading
              ? const Center(
                  child: Text('No hay suficientes datos para una proyección.'),
                )
              : Column(
                  children: [
                    _buildControls(),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding:
                                    const EdgeInsets.fromLTRB(0, 16, 16, 32),
                                child: SizedBox(
                                  width: calculatedChartWidth > screenWidth
                                      ? calculatedChartWidth
                                      : screenWidth,
                                  height: 400,
                                  child: LineChart(_buildChartData()),
                                ),
                              ),
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
        forecastLabel = 'Días a proyectar';
        break;
      case ChartGranularity.weekly:
        forecastLabel = 'Semanas a proyectar';
        break;
      case ChartGranularity.monthly:
        forecastLabel = 'Meses a proyectar';
        break;
      case ChartGranularity.yearly:
        forecastLabel = 'Pronóstico no disponible';
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
              Text('Parámetros del Modelo',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ChartGranularity>(
                  segments: const [
                    ButtonSegment(
                        value: ChartGranularity.daily,
                        label: Text('Diario', style: TextStyle(fontSize: 12))),
                    ButtonSegment(
                        value: ChartGranularity.weekly,
                        label: Text('Semanal', style: TextStyle(fontSize: 12))),
                    ButtonSegment(
                        value: ChartGranularity.monthly,
                        label: Text('Mensual', style: TextStyle(fontSize: 12))),
                    ButtonSegment(
                        value: ChartGranularity.yearly,
                        label: Text('Anual', style: TextStyle(fontSize: 12))),
                  ],
                  selected: _selection,
                  onSelectionChanged: (newSelection) {
                    if (newSelection.isNotEmpty) {
                      final newGranularity = newSelection.first;
                      int updatedPeriods = _forecastedPeriods;

                      final int newMax =
                          (newGranularity == ChartGranularity.daily) ? 30 : 24;

                      if (updatedPeriods > newMax) {
                        updatedPeriods = newMax;
                      }

                      setState(() {
                        _selection = newSelection;
                        _forecastedPeriods = updatedPeriods;
                        _prepareAndRunForecast();
                      });
                    }
                  },
                  multiSelectionEnabled: false,
                  showSelectedIcon: false,
                ),
              ),
              if (selectedGranularity != ChartGranularity.yearly) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('$forecastLabel:', style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: Slider(
                        value: _forecastedPeriods.toDouble(),
                        min: 1,
                        max: selectedGranularity == ChartGranularity.daily
                            ? 30
                            : 24,
                        divisions: selectedGranularity == ChartGranularity.daily
                            ? 29
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
                    const Text('Sensibilidad:', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Slider(
                        value: _alpha,
                        min: 0.1,
                        max: 0.9,
                        divisions: 8,
                        label: _alpha.toStringAsPrecision(1),
                        onChanged: (value) => setState(() => _alpha = value),
                        onChangeEnd: (value) => _prepareAndRunForecast(),
                      ),
                    ),
                    Text(_alpha.toStringAsPrecision(1))
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    if (value == meta.min) {
      return Container();
    }
    final style = const TextStyle(fontSize: 10, color: Colors.black54);
    final text = NumberFormat.compact().format(value);

    return SideTitleWidget(
      space: 8.0,
      meta: meta,
      child: Text(text, style: style),
    );
  }

  LineChartData _buildChartData() {
    final historicalSpots = _displayHistoricalData
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();
    final forecastSpots = <FlSpot>[];

    double minY = 0;
    double maxY = 100;
    final allValues = [
      ..._displayHistoricalData.map((p) => p.value),
      ..._displayForecastedData.map((p) => p.value)
    ];

    if (allValues.isNotEmpty) {
      maxY = allValues.reduce((a, b) => a > b ? a : b);
    }
    maxY *= 1.2;
    if (maxY == 0) {
      maxY = 100;
    }

    if (_displayForecastedData.isNotEmpty) {
      if (historicalSpots.isNotEmpty) {
        forecastSpots.add(historicalSpots.last);
      }
      for (int i = 0; i < _displayForecastedData.length; i++) {
        forecastSpots.add(FlSpot(
            (historicalSpots.length - 1 + i + 1).toDouble(),
            _displayForecastedData[i].value));
      }
    }

    return LineChartData(
      minY: minY,
      maxY: maxY,
      clipData: FlClipData.all(),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: _getTooltipItems,
        ),
      ),
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: _leftTitleWidgets)),
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 35,
          getTitlesWidget: _bottomTitleWidgets,
          interval: 1,
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: historicalSpots,
          isCurved: true,
          color: AppColors.primaryBlue,
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
        if (forecastSpots.isNotEmpty)
          LineChartBarData(
            spots: forecastSpots,
            isCurved: true,
            color: AppColors.primaryOrange,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
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
              dateText = DateFormat('EEE, dd MMM yy', 'es_ES')
                  .format(timeSeriesPoint.time);
              break;
            case ChartGranularity.weekly:
              dateText =
                  "Semana del ${DateFormat('dd/MM/yy').format(timeSeriesPoint.time)}";
              break;
            case ChartGranularity.monthly:
              dateText =
                  DateFormat('MMMM yyyy', 'es_ES').format(timeSeriesPoint.time);
              break;
            case ChartGranularity.yearly:
              dateText = DateFormat('yyyy').format(timeSeriesPoint.time);
              break;
          }

          return LineTooltipItem(
            '${NumberFormat.decimalPattern('es_ES').format(timeSeriesPoint.value)}\n',
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
    final style = TextStyle(fontSize: 10, color: Colors.black54);
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
      int interval = 1;
      if (granularity == ChartGranularity.daily) interval = 2;
      if (granularity == ChartGranularity.weekly) interval = 1;
      if (granularity == ChartGranularity.monthly) interval = 1;

      if (index % interval == 0) {
        switch (granularity) {
          case ChartGranularity.daily:
            text = DateFormat('dd/MM').format(date);
            break;
          case ChartGranularity.weekly:
            text = DateFormat('dd/MM').format(date);
            break;
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
      space: 8.0,
      meta: meta,
      angle: -0.7,
      child: Text(text, style: style),
    );
  }
}

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

class CombinedForecastScreen extends StatefulWidget {
  const CombinedForecastScreen({super.key});

  @override
  State<CombinedForecastScreen> createState() => _CombinedForecastScreenState();
}

class _CombinedForecastScreenState extends State<CombinedForecastScreen> {
  final _forecastingService = ForecastingService();
  List<TimeSeriesPoint> _historicalSales = [];
  List<TimeSeriesPoint> _displayHistoricalData = [];

  List<TimeSeriesPoint> _sesForecast = [];
  List<TimeSeriesPoint> _olsTrendLine = [];
  List<TimeSeriesPoint> _olsForecast = [];

  bool _isLoading = true;
  int _forecastedPeriods = 12;
  double _alpha = 0.4;

  Set<ChartGranularity> _selection = {ChartGranularity.monthly};

  @override
  void initState() {
    super.initState();
    // CORRECCIÓN: Al iniciar, solicitamos el historial completo de datos.
    context.read<SummaryBloc>().add(
      const SummaryDataFetched(startDate: null, endDate: null),
    );
  }

  void _prepareAndRunForecast() {
    if (!mounted) return;

    final summaryState = context.read<SummaryBloc>().state;
    final allInvoices = summaryState.allInvoices;

    final Map<DateTime, double> dailyTotals = {};
    for (var invoice in allInvoices.where(
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

    final selectedGranularity = _selection.first;
    List<TimeSeriesPoint> aggregatedData = _aggregateData(
      _historicalSales,
      selectedGranularity,
    );
    _displayHistoricalData = aggregatedData;

    _sesForecast = _forecastingService.calculateSES(
      historicalData: aggregatedData,
      periodsToForecast: _forecastedPeriods,
      alpha: _alpha,
      granularity: selectedGranularity,
    );

    if (aggregatedData.length >= 3) {
      final result = _forecastingService.calculateOLSForecast(
        historicalData: aggregatedData,
        periodsToForecast: _forecastedPeriods,
        granularity: selectedGranularity,
      );
      _olsTrendLine = result.trendLine;
      _olsForecast = result.forecastedPoints;
    } else {
      _olsTrendLine = [];
      _olsForecast = [];
    }

    // Ya no es necesario el setState(() => _isLoading = false) aquí
    // porque el BlocBuilder manejará la reconstrucción de la UI.
  }

  List<TimeSeriesPoint> _aggregateData(
    List<TimeSeriesPoint> dailyData,
    ChartGranularity granularity,
  ) {
    if (dailyData.isEmpty) return [];

    final groups = groupBy(dailyData, (TimeSeriesPoint p) {
      switch (granularity) {
        case ChartGranularity.monthly:
          return '${p.time.year}-${p.time.month}';
        case ChartGranularity.yearly:
          return p.time.year;
        default:
          return '${p.time.year}-${p.time.month}';
      }
    });

    return groups.entries.map((entry) {
      final totalValue = entry.value
          .map((p) => p.value)
          .reduce((a, b) => a + b);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Proyección de Ventas')),
      // CORRECCIÓN: Se usa un BlocConsumer para escuchar cambios y reconstruir la UI
      body: BlocConsumer<SummaryBloc, SummaryState>(
        listener: (context, state) {
          if (state.status == SummaryStatus.success) {
            // Cuando los datos completos han llegado, preparamos el pronóstico.
            setState(() {
              _isLoading = false;
              _prepareAndRunForecast();
            });
          }
          if (state.status == SummaryStatus.loading) {
            setState(() {
              _isLoading = true;
            });
          }
        },
        builder: (context, state) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final bool hasEnoughData = _displayHistoricalData.length >= 3;
          final String errorMessage =
              'Se necesitan datos de al menos 3 períodos (meses o años) para generar una proyección lineal confiable. La proyección exponencial seguirá disponible.';

          return ListView(
            children: [
              _buildControls(),
              _buildLegend(context),
              if (!hasEnoughData)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: SizedBox(
                  width:
                      (_displayHistoricalData.length + _forecastedPeriods) *
                      80.0,
                  height: 450,
                  child: LineChart(_buildChartData()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leyenda del Gráfico',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildLegendItem(
                AppColors.primaryBlue,
                'Ventas Reales',
                'El historial de tus ventas.',
              ),
              const SizedBox(height: 4),
              _buildLegendItem(
                AppColors.primaryOrange,
                'Proyección Lineal',
                'Estimación basada en la tendencia general (historial completo).',
              ),
              const SizedBox(height: 4),
              _buildLegendItem(
                AppColors.positiveValue,
                'Proyección Flexible',
                'Estimación que da más importancia a las ventas recientes.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String title, String subtitle) {
    return Row(
      children: [
        Container(width: 18, height: 4, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
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
                selected: {_selection.first},
                onSelectionChanged: (newSelection) {
                  if (newSelection.isNotEmpty) {
                    setState(() {
                      _selection = newSelection;
                      _prepareAndRunForecast();
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
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
              Row(
                children: [
                  const Text(
                    'Sensibilidad (Flexible):',
                    style: TextStyle(fontSize: 13),
                  ),
                  Expanded(
                    child: Slider(
                      value: _alpha,
                      min: 0.1,
                      max: 0.9,
                      divisions: 8,
                      label: _alpha.toStringAsFixed(1),
                      onChanged: (value) => setState(() => _alpha = value),
                      onChangeEnd: (value) => _prepareAndRunForecast(),
                    ),
                  ),
                  Text(_alpha.toStringAsFixed(1)),
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

    List<FlSpot> sesForecastSpots = [];
    if (historicalSpots.isNotEmpty && _sesForecast.isNotEmpty) {
      sesForecastSpots.add(historicalSpots.last);
      sesForecastSpots.addAll(
        _sesForecast.mapIndexed(
          (i, e) => FlSpot((historicalSpots.length + i).toDouble(), e.value),
        ),
      );
    }

    final olsTrendSpots = _olsTrendLine
        .mapIndexed((i, e) => FlSpot(i.toDouble(), e.value))
        .toList();

    List<FlSpot> olsForecastSpots = [];
    if (olsTrendSpots.isNotEmpty && _olsForecast.isNotEmpty) {
      olsForecastSpots.add(olsTrendSpots.last);
      olsForecastSpots.addAll(
        _olsForecast.mapIndexed(
          (i, e) => FlSpot((historicalSpots.length + i).toDouble(), e.value),
        ),
      );
    }

    final allValues = [
      ..._displayHistoricalData.map((p) => p.value),
      ..._sesForecast.map((p) => p.value),
      ..._olsForecast.map((p) => p.value),
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
          spots: olsTrendSpots,
          isCurved: false,
          color: AppColors.primaryOrange,
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: olsForecastSpots,
          isCurved: false,
          color: AppColors.primaryOrange,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          dashArray: [5, 5],
        ),
        LineChartBarData(
          spots: sesForecastSpots,
          isCurved: true,
          color: AppColors.positiveValue,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          dashArray: [8, 4],
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
            reservedSize: 45,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              final allPoints = [..._displayHistoricalData, ..._olsForecast];
              if (index >= allPoints.length) return const SizedBox.shrink();

              if (meta.max < value || meta.min > value) {
                return const SizedBox.shrink();
              }

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
                angle: -0.9,
                child: Text(text, style: const TextStyle(fontSize: 10)),
              );
            },
          ),
        ),
      ),
    );
  }
}

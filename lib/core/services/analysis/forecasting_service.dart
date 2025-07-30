import 'dart:math';
import 'package:saint_bi/core/data/models/analysis/time_series_point.dart';

class OLSForecastResult {
  final List<TimeSeriesPoint> trendLine;
  final List<TimeSeriesPoint> forecastedPoints;

  OLSForecastResult({required this.trendLine, required this.forecastedPoints});
}

class ForecastingService {
  List<TimeSeriesPoint> calculateSES({
    required List<TimeSeriesPoint> historicalData,
    required int periodsToForecast,
    required ChartGranularity granularity,
    double alpha = 0.4,
  }) {
    if (historicalData.isEmpty) return [];

    final values = historicalData.map((point) => point.value).toList();
    List<double> smoothedData = [values[0]];

    for (int i = 1; i < values.length; i++) {
      double nextSmoothedValue =
          alpha * values[i] + (1 - alpha) * smoothedData[i - 1];
      smoothedData.add(nextSmoothedValue);
    }

    double forecastValue = smoothedData.last;
    if (forecastValue < 0) forecastValue = 0;

    final List<TimeSeriesPoint> forecastPoints = [];
    DateTime lastDate = historicalData.last.time;

    for (int i = 1; i <= periodsToForecast; i++) {
      switch (granularity) {
        case ChartGranularity.daily:
          lastDate = lastDate.add(const Duration(days: 1));
          break;
        case ChartGranularity.weekly:
          lastDate = lastDate.add(const Duration(days: 7));
          break;
        case ChartGranularity.monthly:
          lastDate = DateTime(lastDate.year, lastDate.month + 1, lastDate.day);
          break;
        case ChartGranularity.yearly:
          lastDate = DateTime(lastDate.year + 1, lastDate.month, lastDate.day);
          break;
      }
      forecastPoints.add(TimeSeriesPoint(time: lastDate, value: forecastValue));
    }
    return forecastPoints;
  }

  OLSForecastResult calculateOLSForecast({
    required List<TimeSeriesPoint> historicalData,
    required int periodsToForecast,
    required ChartGranularity granularity,
  }) {
    if (historicalData.length < 2) {
      return OLSForecastResult(trendLine: [], forecastedPoints: []);
    }

    final n = historicalData.length;
    final x = List<double>.generate(n, (i) => i.toDouble());
    final y = historicalData.map((p) => p.value).toList();

    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);

    final sumXY = List<double>.generate(
      n,
      (i) => x[i] * y[i],
    ).reduce((a, b) => a + b);

    final sumX2 = List<double>.generate(
      n,
      (i) => pow(x[i], 2).toDouble(),
    ).reduce((a, b) => a + b);

    final double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - pow(sumX, 2));
    final double intercept = (sumY - slope * sumX) / n;

    final List<TimeSeriesPoint> trendLine = [];
    for (int i = 0; i < n; i++) {
      final trendValue = intercept + slope * i;
      trendLine.add(
        TimeSeriesPoint(time: historicalData[i].time, value: trendValue),
      );
    }

    final List<TimeSeriesPoint> forecastPoint = [];
    DateTime lastDate = historicalData.last.time;
    for (int i = 0; i < periodsToForecast; i++) {
      final futureX = (n + i).toDouble();
      final forecastValue = intercept + slope * futureX;

      switch (granularity) {
        case ChartGranularity.daily:
          lastDate = lastDate.add(const Duration(days: 1));
          break;

        case ChartGranularity.weekly:
          lastDate = lastDate.add(const Duration(days: 7));
          break;

        case ChartGranularity.monthly:
          lastDate = DateTime(lastDate.year, lastDate.month + 1, lastDate.day);
          break;

        case ChartGranularity.yearly:
          lastDate = DateTime(lastDate.year + 1, lastDate.month, lastDate.day);
          break;
      }
      forecastPoint.add(
        TimeSeriesPoint(time: lastDate, value: max(0, forecastValue)),
      );
    }
    return OLSForecastResult(
      trendLine: trendLine,
      forecastedPoints: forecastPoint,
    );
  }
}

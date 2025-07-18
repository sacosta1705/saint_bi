import 'package:saint_bi/core/data/models/analysis/time_series_point.dart';

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
}

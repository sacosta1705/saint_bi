import 'package:stats/stats.dart';

import 'package:saint_intelligence/analysis/models/time_series_point.dart';

class ForecastingService {
  // Calcula una proyeccion de ventas usando el
  // Pronostico Suavizada Exponencial Simple
  List<TimeSeriesPoint> calculateSES({
    required List<TimeSeriesPoint> historicalData,
    required int periodsToForecast,
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

    final List<TimeSeriesPoint> forecastPoints = [];
    DateTime lastDate = historicalData.last.time;

    for (int i = 1; i <= periodsToForecast; i++) {
      lastDate = lastDate.add(const Duration(days: 1));
      forecastPoints.add(TimeSeriesPoint(
        time: lastDate,
        value: forecastValue < 0 ? 0 : forecastValue,
      ));
    }
    return forecastPoints;
  }
}

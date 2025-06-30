enum ChartGranularity { daily, weekly, monthly, yearly }

class TimeSeriesPoint {
  final DateTime time;
  final double value;

  TimeSeriesPoint({
    required this.time,
    required this.value,
  });
}

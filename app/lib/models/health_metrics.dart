class HealthMetrics {
  final int heartRate;
  final int spO2;
  final DateTime timestamp;

  HealthMetrics({
    required this.heartRate,
    required this.spO2,
    required this.timestamp,
  });

  bool get isValidHeartRate => heartRate > 0;
  bool get isValidSpO2 => spO2 > 0;

  @override
  String toString() =>
      'HR: $heartRate bpm | SpO2: $spO2% | ${timestamp.toIso8601String()}';
}

class HeartRateHistory {
  final List<int> values;
  final List<DateTime> timestamps;

  HeartRateHistory({
    required this.values,
    required this.timestamps,
  });

  void add(int value, DateTime timestamp) {
    values.add(value);
    timestamps.add(timestamp);
  }

  void clear() {
    values.clear();
    timestamps.clear();
  }

  int get length => values.length;
  bool get isEmpty => values.isEmpty;

  List<({int value, DateTime time})> get dataPoints =>
      List.generate(
        values.length,
        (i) => (value: values[i], time: timestamps[i]),
      );
}

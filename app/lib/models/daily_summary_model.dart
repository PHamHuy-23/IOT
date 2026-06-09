class DailySummaryModel {
  final String userId;
  final DateTime date;
  final int? avgHeartRate;
  final int? minHeartRate;
  final int? maxHeartRate;
  final int totalHeartRateRecords;
  final int? avgSpO2;
  final int? minSpO2;
  final int? maxSpO2;
  final int totalSpO2Records;

  const DailySummaryModel({
    required this.userId,
    required this.date,
    this.avgHeartRate,
    this.minHeartRate,
    this.maxHeartRate,
    this.totalHeartRateRecords = 0,
    this.avgSpO2,
    this.minSpO2,
    this.maxSpO2,
    this.totalSpO2Records = 0,
  });

  factory DailySummaryModel.fromMap(Map<String, dynamic> map) {
    return DailySummaryModel(
      userId: map['user_id'] as String,
      date: DateTime.parse(map['date'] as String),
      avgHeartRate: (map['avg_heart_rate'] as num?)?.toInt(),
      minHeartRate: (map['min_heart_rate'] as num?)?.toInt(),
      maxHeartRate: (map['max_heart_rate'] as num?)?.toInt(),
      totalHeartRateRecords:
          (map['total_heart_rate_records'] as num?)?.toInt() ?? 0,
      avgSpO2: (map['avg_spo2'] as num?)?.toInt(),
      minSpO2: (map['min_spo2'] as num?)?.toInt(),
      maxSpO2: (map['max_spo2'] as num?)?.toInt(),
      totalSpO2Records: (map['total_spo2_records'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasData =>
      totalHeartRateRecords > 0 || totalSpO2Records > 0;
}

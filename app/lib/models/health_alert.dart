class HealthAlert {
  final String id;
  final String ownerUserId;
  final String? ownerDisplayName;
  final String alertType;
  final String severity;
  final int? heartRate;
  final int? spO2;
  final String message;
  final bool isSimulated;
  final bool acknowledged;
  final DateTime createdAt;

  const HealthAlert({
    required this.id,
    required this.ownerUserId,
    this.ownerDisplayName,
    required this.alertType,
    required this.severity,
    this.heartRate,
    this.spO2,
    required this.message,
    this.isSimulated = false,
    this.acknowledged = false,
    required this.createdAt,
  });

  factory HealthAlert.fromOwnerMap(Map<String, dynamic> map) {
    return HealthAlert(
      id: map['id'] as String,
      ownerUserId: map['owner_user_id'] as String? ?? '',
      alertType: map['alert_type'] as String,
      severity: map['severity'] as String,
      heartRate: (map['heart_rate'] as num?)?.toInt(),
      spO2: (map['spo2'] as num?)?.toInt(),
      message: map['message'] as String,
      isSimulated: (map['is_simulated'] as bool?) ?? false,
      acknowledged: (map['acknowledged'] as bool?) ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory HealthAlert.fromFamilyMap(Map<String, dynamic> map) {
    return HealthAlert(
      id: map['id'] as String,
      ownerUserId: map['owner_id'] as String,
      ownerDisplayName: map['owner_display_name'] as String?,
      alertType: map['alert_type'] as String,
      severity: map['severity'] as String,
      heartRate: (map['heart_rate'] as num?)?.toInt(),
      spO2: (map['spo2'] as num?)?.toInt(),
      message: map['message'] as String,
      isSimulated: (map['is_simulated'] as bool?) ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get typeLabel {
    switch (alertType) {
      case 'hr_low':
        return 'Nhịp tim thấp';
      case 'hr_high':
        return 'Nhịp tim cao';
      case 'spo2_low':
        return 'SpO2 thấp';
      case 'fall_detected':
        return 'Phát hiện té ngã';
      default:
        return 'Cảnh báo';
    }
  }

  bool get isCritical => severity == 'critical';
}

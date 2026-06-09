/// Ngưỡng cảnh báo sức khỏe
class HealthAlertConstants {
  static const int hrLowWarning = 50;
  static const int hrHighWarning = 120;
  static const int hrHighCritical = 140;

  static const int spo2Warning = 92;
  static const int spo2Critical = 88;

  static const Duration alertCooldown = Duration(minutes: 3);

  static const String typeHrLow = 'hr_low';
  static const String typeHrHigh = 'hr_high';
  static const String typeSpo2Low = 'spo2_low';
  static const String typeFall = 'fall_detected';

  static const String severityWarning = 'warning';
  static const String severityCritical = 'critical';
}

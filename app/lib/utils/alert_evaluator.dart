import '../constants/health_alert_constants.dart';

class AlertEvaluation {
  final String alertType;
  final String severity;
  final String message;

  const AlertEvaluation({
    required this.alertType,
    required this.severity,
    required this.message,
  });
}

class AlertEvaluator {
  static AlertEvaluation? evaluateVitals({
    required int heartRate,
    required int spO2,
  }) {
    if (heartRate > 0 && heartRate < HealthAlertConstants.hrLowWarning) {
      return AlertEvaluation(
        alertType: HealthAlertConstants.typeHrLow,
        severity: HealthAlertConstants.severityWarning,
        message: 'Nhịp tim thấp bất thường: $heartRate BPM',
      );
    }
    if (heartRate >= HealthAlertConstants.hrHighCritical) {
      return AlertEvaluation(
        alertType: HealthAlertConstants.typeHrHigh,
        severity: HealthAlertConstants.severityCritical,
        message: 'Nhịp tim rất cao: $heartRate BPM',
      );
    }
    if (heartRate > HealthAlertConstants.hrHighWarning) {
      return AlertEvaluation(
        alertType: HealthAlertConstants.typeHrHigh,
        severity: HealthAlertConstants.severityWarning,
        message: 'Nhịp tim cao: $heartRate BPM',
      );
    }
    if (spO2 > 0 && spO2 < HealthAlertConstants.spo2Critical) {
      return AlertEvaluation(
        alertType: HealthAlertConstants.typeSpo2Low,
        severity: HealthAlertConstants.severityCritical,
        message: 'SpO2 nguy hiểm: $spO2%',
      );
    }
    if (spO2 > 0 && spO2 < HealthAlertConstants.spo2Warning) {
      return AlertEvaluation(
        alertType: HealthAlertConstants.typeSpo2Low,
        severity: HealthAlertConstants.severityWarning,
        message: 'SpO2 thấp: $spO2%',
      );
    }
    return null;
  }

  static AlertEvaluation fallDetected({int confidence = 100}) {
    return AlertEvaluation(
      alertType: HealthAlertConstants.typeFall,
      severity: HealthAlertConstants.severityCritical,
      message: 'Phát hiện té ngã! (độ tin cậy $confidence%)',
    );
  }
}

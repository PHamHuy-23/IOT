import 'dart:async';

import 'package:flutter/foundation.dart';
import '../constants/health_alert_constants.dart';
import '../models/health_alert.dart';
import '../services/health_alert_service.dart';
import '../services/local_notification_service.dart';
import '../utils/alert_evaluator.dart';

class AlertProvider extends ChangeNotifier {
  final HealthAlertService _service = HealthAlertService();
  final LocalNotificationService _notifications = LocalNotificationService();

  String? _userId;
  List<HealthAlert> _myAlerts = [];
  List<HealthAlert> _familyAlerts = [];
  final Map<String, DateTime> _lastFired = {};
  final Set<String> _seenFamilyAlertIds = {};
  Timer? _pollTimer;
  bool _healthAlertsEnabled = true;

  List<HealthAlert> get myAlerts => _myAlerts;
  List<HealthAlert> get familyAlerts => _familyAlerts;
  int get unreadFamilyCount =>
      _familyAlerts.where((a) => !_seenFamilyAlertIds.contains(a.id)).length;

  void bindUser(String? userId, {bool healthAlertsEnabled = true}) {
    _healthAlertsEnabled = healthAlertsEnabled;
    if (_userId == userId) return;
    _userId = userId;
    _pollTimer?.cancel();
    _myAlerts = [];
    _familyAlerts = [];
    _seenFamilyAlertIds.clear();
    if (userId == null) {
      notifyListeners();
      return;
    }
    _loadAll();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) => _pollFamily());
  }

  void updateHealthAlertsEnabled(bool enabled) {
    _healthAlertsEnabled = enabled;
  }

  Future<void> _loadAll() async {
    if (_userId == null) return;
    try {
      _myAlerts = await _service.getMyAlerts(_userId!);
      await _pollFamily();
    } catch (e) {
      debugPrint('[AlertProvider._loadAll] $e');
    }
    notifyListeners();
  }

  Future<void> _pollFamily() async {
    if (_userId == null || !_healthAlertsEnabled) return;
    try {
      final alerts = await _service.getFamilyAlerts(_userId!);
      for (final alert in alerts) {
        if (_seenFamilyAlertIds.contains(alert.id)) continue;
        _seenFamilyAlertIds.add(alert.id);
        final name = alert.ownerDisplayName ?? 'Người thân';
        await _notifications.showHealthAlert(
          id: alert.id.hashCode,
          title: '🚨 $name — ${alert.typeLabel}',
          body: alert.message,
          critical: alert.isCritical,
        );
      }
      _familyAlerts = alerts;
      notifyListeners();
    } catch (e) {
      debugPrint('[AlertProvider._pollFamily] $e');
    }
  }

  Future<void> handleVitalAlert({
    required String ownerUserId,
    required int heartRate,
    required int spO2,
    bool isSimulated = false,
  }) async {
    if (!_healthAlertsEnabled) return;
    final evaluation = AlertEvaluator.evaluateVitals(
      heartRate: heartRate,
      spO2: spO2,
    );
    if (evaluation == null) return;
    await _fireAlert(
      ownerUserId: ownerUserId,
      evaluation: evaluation,
      heartRate: heartRate,
      spO2: spO2,
      isSimulated: isSimulated,
    );
  }

  Future<void> handleFallAlert({
    required String ownerUserId,
    bool isSimulated = false,
    int confidence = 100,
  }) async {
    if (!_healthAlertsEnabled) return;
    await _fireAlert(
      ownerUserId: ownerUserId,
      evaluation: AlertEvaluator.fallDetected(confidence: confidence),
      isSimulated: isSimulated,
    );
  }

  Future<void> _fireAlert({
    required String ownerUserId,
    required AlertEvaluation evaluation,
    int? heartRate,
    int? spO2,
    bool isSimulated = false,
  }) async {
    final key = '${evaluation.alertType}_${evaluation.severity}';
    final last = _lastFired[key];
    if (last != null &&
        DateTime.now().difference(last) < HealthAlertConstants.alertCooldown) {
      return;
    }
    _lastFired[key] = DateTime.now();

    try {
      await _service.createAlert(
        ownerUserId: ownerUserId,
        evaluation: evaluation,
        heartRate: heartRate,
        spO2: spO2,
        isSimulated: isSimulated,
      );
      await _notifications.showHealthAlert(
        id: key.hashCode,
        title: '⚠️ ${evaluation.alertType == HealthAlertConstants.typeFall ? 'Té ngã!' : 'Cảnh báo sức khỏe'}',
        body: evaluation.message,
        critical: evaluation.severity == HealthAlertConstants.severityCritical,
      );
      if (_userId == ownerUserId) {
        _myAlerts = await _service.getMyAlerts(ownerUserId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[AlertProvider._fireAlert] $e');
    }
  }

  Future<void> refresh() => _loadAll();

  Future<void> acknowledge(String alertId) async {
    if (_userId == null) return;
    await _service.acknowledge(alertId, _userId!);
    await _loadAll();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

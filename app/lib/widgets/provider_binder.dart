import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/family_share_provider.dart';
import '../providers/health_provider.dart';
import '../providers/user_data_provider.dart';
import '../services/local_notification_service.dart';

/// Nối các provider với nhau
class ProviderBinder extends StatefulWidget {
  final Widget child;
  const ProviderBinder({super.key, required this.child});

  @override
  State<ProviderBinder> createState() => _ProviderBinderState();
}

class _ProviderBinderState extends State<ProviderBinder> {
  AuthProvider? _auth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await LocalNotificationService().initialize();
      _wire();
    });
  }

  void _wire() {
    final auth = context.read<AuthProvider>();
    final health = context.read<HealthProvider>();
    final userData = context.read<UserDataProvider>();
    final family = context.read<FamilyShareProvider>();
    final alert = context.read<AlertProvider>();
    _auth = auth;

    health.setUserIdProvider(() => auth.currentUser?.id);
    health.setSimulationModeProvider(
        () => auth.currentUser?.usesSimulation ?? false);
    health.setOnDataSaved(() {
      userData.refreshTodaySummary();
      auth.getStats();
    });
    health.setOnVitalsAlert((hr, spo2, isSimulated) {
      final userId = auth.currentUser?.id;
      if (userId == null) return;
      alert.handleVitalAlert(
        ownerUserId: userId,
        heartRate: hr,
        spO2: spo2,
        isSimulated: isSimulated,
      );
    });
    health.setOnFallAlert((isSimulated, confidence) {
      final userId = auth.currentUser?.id;
      if (userId == null) return;
      alert.handleFallAlert(
        ownerUserId: userId,
        isSimulated: isSimulated,
        confidence: confidence,
      );
    });

    _bindUser(auth, userData, family, alert);
    health.refreshSimulation();
    auth.addListener(_onAuthChanged);
  }

  void _bindUser(
    AuthProvider auth,
    UserDataProvider userData,
    FamilyShareProvider family,
    AlertProvider alert,
  ) {
    final userId = auth.currentUser?.id;
    userData.bindUser(userId);
    family.bindUser(userId);
    alert.bindUser(
      userId,
      healthAlertsEnabled: userData.settings?.healthAlerts ?? true,
    );
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final userData = context.read<UserDataProvider>();
    final family = context.read<FamilyShareProvider>();
    final alert = context.read<AlertProvider>();
    final health = context.read<HealthProvider>();

    _bindUser(auth, userData, family, alert);
    health.refreshSimulation();
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

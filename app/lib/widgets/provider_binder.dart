import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/family_share_provider.dart';
import '../providers/health_provider.dart';
import '../providers/user_data_provider.dart';

/// Nối AuthProvider ↔ HealthProvider ↔ UserDataProvider
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _wire());
  }

  void _wire() {
    final auth = context.read<AuthProvider>();
    final health = context.read<HealthProvider>();
    final userData = context.read<UserDataProvider>();
    final family = context.read<FamilyShareProvider>();
    _auth = auth;

    health.setUserIdProvider(() => auth.currentUser?.id);
    health.setOnDataSaved(() {
      userData.refreshTodaySummary();
      auth.getStats();
    });

    final userId = auth.currentUser?.id;
    userData.bindUser(userId);
    family.bindUser(userId);
    auth.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    context.read<UserDataProvider>().bindUser(userId);
    context.read<FamilyShareProvider>().bindUser(userId);
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

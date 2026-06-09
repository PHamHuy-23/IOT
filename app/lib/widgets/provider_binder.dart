import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
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
    _auth = auth;

    health.setUserIdProvider(() => auth.currentUser?.id);
    health.setOnDataSaved(() {
      userData.refreshTodaySummary();
      auth.getStats();
    });

    userData.bindUser(auth.currentUser?.id);
    auth.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    context.read<UserDataProvider>().bindUser(auth.currentUser?.id);
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

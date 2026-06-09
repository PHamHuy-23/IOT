import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_data_provider.dart';
import '../themes/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _saving = false;
  late bool _pushEnabled;
  late bool _healthAlerts;

  @override
  void initState() {
    super.initState();
    final s = context.read<UserDataProvider>().settings;
    _pushEnabled = s?.pushEnabled ?? true;
    _healthAlerts = s?.healthAlerts ?? true;
  }

  Future<void> _save() async {
    final userData = context.read<UserDataProvider>();
    final settings = userData.settings;
    if (settings == null) return;

    setState(() => _saving = true);
    await userData.saveSettings(settings.copyWith(
      pushEnabled: _pushEnabled,
      healthAlerts: _healthAlerts,
    ));
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cài đặt thông báo'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        title: const Text('Thông báo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _toggle(
            'Thông báo đẩy',
            'Nhận thông báo từ ứng dụng',
            _pushEnabled,
            (v) => setState(() => _pushEnabled = v),
          ),
          const SizedBox(height: 8),
          _toggle(
            'Cảnh báo sức khỏe',
            'Nhịp tim hoặc SpO2 bất thường',
            _healthAlerts,
            (v) => setState(() => _healthAlerts = v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 12)),
        value: value,
        activeThumbColor: AppTheme.accentRed,
        onChanged: onChanged,
      ),
    );
  }
}

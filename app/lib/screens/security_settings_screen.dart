import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_data_provider.dart';
import '../themes/app_theme.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _saving = false;
  late bool _dataSharing;
  late bool _biometricLock;

  @override
  void initState() {
    super.initState();
    final s = context.read<UserDataProvider>().settings;
    _dataSharing = s?.dataSharing ?? false;
    _biometricLock = s?.biometricLock ?? false;
  }

  Future<void> _save() async {
    final userData = context.read<UserDataProvider>();
    final settings = userData.settings;
    if (settings == null) return;

    setState(() => _saving = true);
    await userData.saveSettings(settings.copyWith(
      dataSharing: _dataSharing,
      biometricLock: _biometricLock,
    ));
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cài đặt bảo mật'),
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
        title: const Text('Bảo mật & Quyền riêng tư',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _toggle(
            'Chia sẻ với người thân',
            'Cho phép người thân quét QR để xem dữ liệu sức khỏe',
            _dataSharing,
            (v) => setState(() => _dataSharing = v),
          ),
          const SizedBox(height: 8),
          _toggle(
            'Khóa sinh trắc học',
            'Yêu cầu vân tay/Face ID khi mở app',
            _biometricLock,
            (v) => setState(() => _biometricLock = v),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Người thân cần tài khoản riêng và quét mã QR trong app. '
              'Bạn có thể thu hồi quyền xem bất kỳ lúc nào.',
              style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
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
        activeThumbColor: AppTheme.accentPurple,
        onChanged: onChanged,
      ),
    );
  }
}

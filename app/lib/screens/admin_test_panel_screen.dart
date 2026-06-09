import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';
import '../themes/app_theme.dart';

/// Chỉ hiển thị cho admin / testing — kích hoạt cảnh báo mô phỏng
class AdminTestPanelScreen extends StatefulWidget {
  const AdminTestPanelScreen({super.key});

  @override
  State<AdminTestPanelScreen> createState() => _AdminTestPanelScreenState();
}

class _AdminTestPanelScreenState extends State<AdminTestPanelScreen> {
  int _scenario = 0;

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Panel kiểm thử',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accentPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Tài khoản Admin/Testing: dữ liệu mô phỏng khi không kết nối BLE. '
              'Các nút bên dưới kích hoạt cảnh báo ngay lập tức và gửi tới người thân đã kết nối.',
              style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12, height: 1.5),
            ),
          ),
          if (health.usingSimulatedData)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('🔄 Đang mô phỏng dữ liệu live',
                  style: TextStyle(color: AppTheme.neonGreen, fontSize: 12)),
            ),
          if (health.fallDetected)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppTheme.accentRed),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Té ngã đang active!',
                        style: TextStyle(color: AppTheme.accentRed)),
                  ),
                  TextButton(
                    onPressed: () => health.clearFallState(),
                    child: const Text('Xóa'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          const Text('Kích hoạt cảnh báo ngay',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 12),
          _btn('Nhịp tim cao (135 BPM)', Icons.favorite, () {
            health.triggerTestVitals(hr: 135, spo2: 97);
          }),
          _btn('SpO2 thấp (86%)', Icons.bloodtype, () {
            health.triggerTestVitals(hr: 75, spo2: 86);
          }),
          _btn('Té ngã', Icons.accessibility_new, () {
            health.triggerTestFall();
          }),
          const SizedBox(height: 24),
          const Text('Chế độ mô phỏng liên tục',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 8),
          ...List.generate(4, (i) {
            final labels = ['Bình thường', 'HR cao', 'SpO2 thấp', 'Chu kỳ té'];
            return RadioListTile<int>(
              value: i,
              groupValue: _scenario,
              activeColor: AppTheme.accentRed,
              title: Text(labels[i],
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              onChanged: (v) {
                setState(() => _scenario = v!);
                health.setSimulationScenario(v!);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _btn(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.cardDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}

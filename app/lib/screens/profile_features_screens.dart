import 'package:flutter/material.dart';
import '../themes/app_theme.dart'; // Đảm bảo đúng đường dẫn import theme của bạn

// ──────────────────────────────────────────────────────────────
// 1. MÀN HÌNH THÔNG BÁO (Notifications)
// ──────────────────────────────────────────────────────────────
class NotificationSettingScreen extends StatefulWidget {
  const NotificationSettingScreen({super.key});

  @override
  State<NotificationSettingScreen> createState() => _NotificationSettingScreenState();
}

class _NotificationSettingScreenState extends State<NotificationSettingScreen> {
  bool _syncNotif = true;
  bool _heartNotif = true;
  bool _goalNotif = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        title: const Text('Thông báo', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSwitchGroup([
            _buildSwitchTile('Đồng bộ dữ liệu', 'Thông báo khi thiết bị hoàn thành đồng bộ dữ liệu sức khỏe.', _syncNotif, (v) => setState(() => _syncNotif = v)),
            _buildSwitchTile('Cảnh báo nhịp tim', 'Cảnh báo khi nhịp tim vượt quá ngưỡng an toàn hoặc quá thấp.', _heartNotif, (v) => setState(() => _heartNotif = v)),
            _buildSwitchTile('Nhắc nhở mục tiêu', 'Nhắc nhở khi bạn gần đạt hoặc đã đạt mục tiêu bước chân/calo trong ngày.', _goalNotif, (v) => setState(() => _goalNotif = v)),
          ]),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 2. MÀN HÌNH BẢO MẬT & QUYỀN RIÊNG TƯ (Security & Privacy)
// ──────────────────────────────────────────────────────────────
class SecurityPrivacyScreen extends StatelessWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        title: const Text('Bảo mật & Quyền riêng tư', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SubSectionTitle('TÀI KHOẢN'),
          const SizedBox(height: 8),
          _buildActionGroup([
            _buildActionTile(Icons.lock_outline_rounded, 'Thay đổi mật khẩu', () {}),
            _buildActionTile(Icons.fingerprint_rounded, 'Xác thực sinh trắc học (FaceID/Vân tay)', () {}),
          ]),
          const SizedBox(height: 24),
          const _SubSectionTitle('QUYỀN TRUY CẬP HỆ THỐNG'),
          const SizedBox(height: 8),
          _buildActionGroup([
            _buildActionTile(Icons.bluetooth_rounded, 'Quyền kết nối Bluetooth', () {}),
            _buildActionTile(Icons.location_on_outlined, 'Quyền vị trí (GPS)', () {}),
          ]),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 3. MÀN HÌNH LỊCH SỬ & BÁO CÁO (History & Reports)
// ──────────────────────────────────────────────────────────────
class HistoryReportsScreen extends StatelessWidget {
  const HistoryReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        title: const Text('Lịch sử & Báo cáo', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildActionGroup([
            _buildActionTile(Icons.picture_as_pdf_rounded, 'Báo cáo sức khỏe tuần này', () {}, trailingText: 'Tải PDF'),
            _buildActionTile(Icons.picture_as_pdf_rounded, 'Báo cáo tổng quan tháng trước', () {}, trailingText: 'Tải PDF'),
          ]),
          const SizedBox(height: 24),
          const _SubSectionTitle('LỊCH SỬ ĐỒNG BỘ'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
            child: const Column(
              children: [
                _ReportRow(title: 'Đồng bộ gần nhất', value: 'Hôm nay, 16:30'),
                Divider(color: AppTheme.subtleGrey, height: 24),
                _ReportRow(title: 'Thiết bị kết nối', value: 'Smart Watch Series 5'),
                Divider(color: AppTheme.subtleGrey, height: 24),
                _ReportRow(title: 'Trạng thái dữ liệu', value: 'Đã tối ưu hóa', isSuccess: true),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 4. MÀN HÌNH XUẤT DỮ LIỆU (Export Data)
// ──────────────────────────────────────────────────────────────
class ExportDataScreen extends StatelessWidget {
  const ExportDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        title: const Text('Xuất dữ liệu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.accentBlue, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dữ liệu sức khỏe của bạn sẽ được đóng gói dưới định dạng chuẩn (.csv hoặc .json) để bạn có thể import sang các ứng dụng y tế khác.',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SubSectionTitle('CHỌN ĐỊNH DẠNG XUẤT'),
            const SizedBox(height: 8),
            _buildActionGroup([
              _buildActionTile(Icons.grid_on_rounded, 'Xuất file bảng tính (.CSV)', () {}, iconColor: Colors.greenAccent),
              _buildActionTile(Icons.code_rounded, 'Xuất cấu trúc dữ liệu (.JSON)', () {}, iconColor: Colors.amberAccent),
            ]),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// THÀNH PHẦN UI PHỤ DÙNG CHUNG TRONG FILE (Private Widgets)
// ══════════════════════════════════════════════════════════════
class _SubSectionTitle extends StatelessWidget {
  final String text;
  const _SubSectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8));
  }
}

class _ReportRow extends StatelessWidget {
  final String title;
  final String value;
  final bool isSuccess;
  const _ReportRow({required this.title, required this.value, this.isSuccess = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 14)),
        Text(value, style: TextStyle(color: isSuccess ? AppTheme.accentGreen : Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

Widget _buildSwitchGroup(List<Widget> children) {
  return Container(
    decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
    child: Column(children: children),
  );
}

Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
  return SwitchListTile.adaptive(
    title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(subtitle, style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 12)),
    ),
    value: value,
    activeColor: AppTheme.accentRed,
    onChanged: onChanged,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  );
}

Widget _buildActionGroup(List<Widget> children) {
  return Container(
    decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
    child: Column(children: children),
  );
}

Widget _buildActionTile(IconData icon, String label, VoidCallback onTap, {String? trailingText, Color iconColor = AppTheme.mutedGrey}) {
  return ListTile(
    leading: Icon(icon, color: iconColor, size: 20),
    title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (trailingText != null) ...[
          Text(trailingText, style: const TextStyle(color: AppTheme.accentRed, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
        ],
        const Icon(Icons.chevron_right_rounded, color: AppTheme.mutedGrey, size: 20),
      ],
    ),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}
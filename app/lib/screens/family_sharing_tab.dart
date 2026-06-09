import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/family_member.dart';
import '../providers/auth_provider.dart';
import '../providers/family_share_provider.dart';
import '../providers/user_data_provider.dart';
import '../themes/app_theme.dart';
import 'auth_screen.dart';
import 'scan_family_qr_screen.dart';
import 'shared_health_screen.dart';

/// Tab Chia sẻ — mời người thân (QR) + quét mã + danh sách kết nối
class FamilySharingTab extends StatefulWidget {
  const FamilySharingTab({super.key});

  @override
  State<FamilySharingTab> createState() => _FamilySharingTabState();
}

class _FamilySharingTabState extends State<FamilySharingTab> {
  bool _loadingQr = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    final userData = context.read<UserDataProvider>();
    final family = context.read<FamilyShareProvider>();
    setState(() => _loadingQr = true);
    await userData.loadShareToken();
    await family.loadAll();
    if (mounted) setState(() => _loadingQr = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userData = context.watch<UserDataProvider>();
    final family = context.watch<FamilyShareProvider>();
    final settings = userData.settings;

    if (!auth.isLoggedIn) {
      return _loginPrompt(
        'Đăng nhập để chia sẻ dữ liệu với người thân',
        onAction: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        ),
      );
    }

    final qrPayload = context
        .read<FamilyShareProvider>()
        .buildInviteQrPayload(userData.shareToken?.token);
    final isOwnerSharing = settings?.dataSharing ?? false;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accentRed,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.black,
            pinned: true,
            elevation: 0,
            title: const Text(
              'Chia sẻ gia đình',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _loadingQr ? null : _load,
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Quét mã (người thân) ──
                _sectionLabel('Tôi là người thân'),
                const SizedBox(height: 8),
                _scanCard(),
                const SizedBox(height: 8),
                if (family.sharedWithMe.isNotEmpty) ...[
                  ...family.sharedWithMe.map(
                    (c) => _connectionTile(
                      connection: c,
                      subtitle: 'Đang chia sẻ dữ liệu cho bạn',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SharedHealthScreen(owner: c),
                        ),
                      ),
                      onRemove: () => _confirmLeave(c),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // ── Mời người thân (chủ thiết bị) ──
                _sectionLabel('Tôi đeo thiết bị'),
                const SizedBox(height: 8),
                if (!isOwnerSharing)
                  _infoBox(
                    'Bật "Chia sẻ với người thân" trong Bảo mật để hiển thị mã QR mời.',
                    icon: Icons.info_outline,
                  )
                else
                  _inviteQrCard(qrPayload, userData),
                const SizedBox(height: 16),
                if (isOwnerSharing && family.myMembers.isNotEmpty) ...[
                  Text(
                    'Người thân đã kết nối (${family.myMembers.length})',
                    style: const TextStyle(
                        color: AppTheme.mutedGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...family.myMembers.map(
                    (m) => _connectionTile(
                      connection: m,
                      subtitle:
                          'Kết nối ${_formatDate(m.joinedAt)}',
                      onRemove: () => _confirmRevoke(m),
                    ),
                  ),
                ] else if (isOwnerSharing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Chưa có người thân nào quét mã. '
                      'Hãy cho họ mở app → Chia sẻ → Quét mã.',
                      style: TextStyle(
                          color: AppTheme.mutedGrey, fontSize: 12, height: 1.4),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
          color: AppTheme.mutedGrey,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8),
    );
  }

  Widget _scanCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.qr_code_scanner_rounded,
              color: AppTheme.accentBlue),
        ),
        title: const Text('Quét mã QR người thân',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: const Text(
          'Kết nối để xem nhịp tim & SpO2 từ đồng hồ của họ',
          style: TextStyle(color: AppTheme.mutedGrey, fontSize: 11),
        ),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppTheme.mutedGrey),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScanFamilyQrScreen()),
        ),
      ),
    );
  }

  Widget _inviteQrCard(String? qrPayload, UserDataProvider userData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          if (_loadingQr || qrPayload == null)
            const SizedBox(
              height: 160,
              child: Center(
                  child: CircularProgressIndicator(color: AppTheme.accentRed)),
            )
          else
            QrImageView(
              data: qrPayload,
              version: QrVersions.auto,
              size: 160,
              backgroundColor: Colors.white,
            ),
          const SizedBox(height: 16),
          const Text(
            'Mã mời người thân',
            style: TextStyle(
                color: AppTheme.accentRed,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'Người thân đăng nhập tài khoản riêng, mở tab Chia sẻ '
            'và quét mã này để xem dữ liệu sức khỏe của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12, height: 1.5),
          ),
          if (userData.shareToken?.expiresAt != null) ...[
            const SizedBox(height: 10),
            Text(
              'Mã hết hạn: ${_formatExpiry(userData.shareToken!.expiresAt!)}',
              style: const TextStyle(color: AppTheme.neonGreen, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _connectionTile({
    required FamilyConnection connection,
    required String subtitle,
    VoidCallback? onTap,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.accentPurple.withOpacity(0.2),
          child: Text(connection.initials,
              style: const TextStyle(
                  color: AppTheme.accentPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        title: Text(connection.displayName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 11)),
        trailing: IconButton(
          icon: const Icon(Icons.link_off_rounded,
              color: Colors.redAccent, size: 20),
          onPressed: onRemove,
        ),
      ),
    );
  }

  Widget _infoBox(String text, {required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accentOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentOrange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentOrange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppTheme.accentOrange, fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _loginPrompt(String message, {required VoidCallback onAction}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.family_restroom_rounded,
                color: AppTheme.mutedGrey, size: 48),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentRed),
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRevoke(FamilyConnection member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Ngắt kết nối?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '${member.displayName} sẽ không còn xem được dữ liệu của bạn.',
          style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy',
                style: TextStyle(color: AppTheme.mutedGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ngắt',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<FamilyShareProvider>().revokeMember(member.userId);
    }
  }

  Future<void> _confirmLeave(FamilyConnection owner) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Ngừng theo dõi?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Bạn sẽ không còn xem dữ liệu của ${owner.displayName}.',
          style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy',
                style: TextStyle(color: AppTheme.mutedGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ngừng',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<FamilyShareProvider>().leaveShare(owner.userId);
    }
  }

  String _formatExpiry(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

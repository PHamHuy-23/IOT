import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
<<<<<<< HEAD
import 'profile_features_screens.dart';
=======
import '../providers/user_data_provider.dart';
>>>>>>> 404cd7ca7584e72972e0c09c92c419b6b83c753e
import '../themes/app_theme.dart';
import 'family_sharing_tab.dart';
import 'health_history_screen.dart';
import 'notification_settings_screen.dart';
import 'scan_family_qr_screen.dart';
import 'security_settings_screen.dart';
import 'shared_health_screen.dart';
import '../providers/family_share_provider.dart';

// ══════════════════════════════════════════════════════════════
// PROFILE SCREEN
// ══════════════════════════════════════════════════════════════
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Sliver App Bar ──
          SliverAppBar(
            backgroundColor: AppTheme.black,
            expandedHeight: 140,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _avatarGradient(user.avatarColor).$1.withOpacity(0.3),
                      _avatarGradient(user.avatarColor).$2.withOpacity(0.3),
                      AppTheme.black,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar + nút sửa ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AvatarCircle(
                        initials: user.initials,
                        avatarColor: user.avatarColor,
                        size: 72,
                        fontSize: 26,
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => _openEditProfile(context, user),
                        icon: const Icon(Icons.edit_rounded, size: 14),
                        label: const Text('Sửa hồ sơ',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                              color: AppTheme.subtleGrey, width: 0.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Tên + email ──
                  Text(
                    user.displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}  •  ${user.email}',
                    style: const TextStyle(
                        color: AppTheme.mutedGrey, fontSize: 13),
                  ),
                  const SizedBox(height: 10),

                  // ── Role badge ──
                  if (user.isAdmin)
                    _RoleBadge(color: user.avatarColor)
                  else
                    _UserBadge(color: user.avatarColor),

                  const SizedBox(height: 24),

                  // ── Stats (Đã cập nhật dùng Consumer) ──
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final stats = auth.stats;
                      return Row(
                        children: [
                          _StatBox(
                            label: 'Ngày theo dõi',
                            value: stats.daysTracked.toString(),
                            icon: Icons.calendar_today_rounded,
                          ),
                          const SizedBox(width: 10),
                          _StatBox(
                            label: 'Đồng bộ',
                            value: stats.totalSyncs.toString(),
                            icon: Icons.sync_rounded,
                          ),
                          const SizedBox(width: 10),
                          _StatBox(
                            label: 'Huy hiệu',
                            value: stats.badgeCount.toString(),
                            icon: Icons.emoji_events_rounded,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Menu cài đặt ──
                  const _SectionLabel('Cài đặt tài khoản'),
                  const SizedBox(height: 8),
                  _MenuGroup(items: [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      iconBg: const Color(0xFF1A0A10),
                      iconColor: AppTheme.accentRed,
                      label: 'Thông tin cá nhân',
                      onTap: () => _openEditProfile(context, user),
                    ),
                    _MenuItem(
                      icon: Icons.notifications_none_rounded,
                      iconBg: const Color(0xFF0A1020),
                      iconColor: AppTheme.accentBlue,
                      label: 'Thông báo',
<<<<<<< HEAD
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationSettingScreen()),
                        );
                      },
=======
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsScreen(),
                        ),
                      ),
>>>>>>> 404cd7ca7584e72972e0c09c92c419b6b83c753e
                    ),
                    _MenuItem(
                      icon: Icons.lock_outline_rounded,
                      iconBg: const Color(0xFF1A1020),
                      iconColor: AppTheme.accentPurple,
                      label: 'Bảo mật & Quyền riêng tư',
<<<<<<< HEAD
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SecurityPrivacyScreen()),
                        );
                      },
=======
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SecuritySettingsScreen(),
                        ),
                      ),
>>>>>>> 404cd7ca7584e72972e0c09c92c419b6b83c753e
                    ),
                  ]),

                  const SizedBox(height: 16),
                  const _SectionLabel('Gia đình'),
                  const SizedBox(height: 8),
                  Consumer<FamilyShareProvider>(
                    builder: (context, family, _) {
                      return _MenuGroup(items: [
                        _MenuItem(
                          icon: Icons.qr_code_scanner_rounded,
                          iconBg: const Color(0xFF0A1020),
                          iconColor: AppTheme.accentBlue,
                          label: 'Quét mã người thân',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ScanFamilyQrScreen(),
                            ),
                          ),
                        ),
                        if (family.sharedWithMe.isNotEmpty)
                          _MenuItem(
                            icon: Icons.family_restroom_rounded,
                            iconBg: const Color(0xFF1A1020),
                            iconColor: AppTheme.accentPurple,
                            label:
                                'Đang theo dõi (${family.sharedWithMe.length})',
                            onTap: () => _openFamilyList(context, family),
                          ),
                        _MenuItem(
                          icon: Icons.share_rounded,
                          iconBg: const Color(0xFF1A0A10),
                          iconColor: AppTheme.accentRed,
                          label: 'Mời người thân (QR)',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Scaffold(
                                backgroundColor: AppTheme.black,
                                body: FamilySharingTab(),
                              ),
                            ),
                          ),
                        ),
                      ]);
                    },
                  ),

                  const SizedBox(height: 16),
                  const _SectionLabel('Dữ liệu sức khỏe'),
                  const SizedBox(height: 8),
                  _MenuGroup(items: [
                    _MenuItem(
                      icon: Icons.bar_chart_rounded,
                      iconBg: const Color(0xFF0A1A10),
                      iconColor: AppTheme.accentGreen,
                      label: 'Lịch sử & Báo cáo',
<<<<<<< HEAD
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HistoryReportsScreen()),
                        );
                      },
=======
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HealthHistoryScreen(),
                        ),
                      ),
>>>>>>> 404cd7ca7584e72972e0c09c92c419b6b83c753e
                    ),
                    _MenuItem(
                      icon: Icons.cloud_upload_outlined,
                      iconBg: const Color(0xFF0A1020),
                      iconColor: AppTheme.accentBlue,
                      label: 'Xuất dữ liệu',
<<<<<<< HEAD
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ExportDataScreen()),
                        );
                      },
=======
                      onTap: () => _exportData(context),
>>>>>>> 404cd7ca7584e72972e0c09c92c419b6b83c753e
                    ),
                    _MenuItem(
                      icon: Icons.delete_outline_rounded,
                      iconBg: const Color(0xFF1A0800),
                      iconColor: AppTheme.accentOrange,
                      label: 'Xóa dữ liệu',
                      onTap: () => _confirmDeleteData(context),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ── Đăng xuất ──
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmSignOut(context),
                      icon: const Icon(Icons.logout_rounded,
                          color: Colors.redAccent, size: 18),
                      label: const Text(
                        'Đăng xuất',
                        style:
                            TextStyle(color: Colors.redAccent, fontSize: 15),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.redAccent.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mở sheet chỉnh sửa hồ sơ ────────────────────────────
  void _openEditProfile(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(user: user),
    );
  }

  // ── Xác nhận đăng xuất ──────────────────────────────────
  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Đăng xuất?',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: const Text(
          'Dữ liệu của bạn đã được lưu. Bạn có thể đăng nhập lại bất kỳ lúc nào.',
          style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy',
                style: TextStyle(color: AppTheme.mutedGrey)),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().signOut();
              Navigator.of(context)
                ..pop()
                ..pop();
            },
            child: const Text('Đăng xuất',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _openFamilyList(BuildContext context, FamilyShareProvider family) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Người thân đang theo dõi',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            ...family.sharedWithMe.map(
              (c) => ListTile(
                title: Text(c.displayName,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text('@${c.username}',
                    style: const TextStyle(color: AppTheme.mutedGrey)),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.mutedGrey),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SharedHealthScreen(owner: c),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final json = await context.read<UserDataProvider>().exportData();
    if (json == null || !context.mounted) return;
    await Clipboard.setData(ClipboardData(text: json));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép dữ liệu JSON vào clipboard'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
    }
  }

  // ── Xác nhận xoá dữ liệu ────────────────────────────────
  void _confirmDeleteData(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xóa toàn bộ dữ liệu?',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: const Text(
          'Hành động này không thể hoàn tác. Tất cả lịch sử sức khỏe sẽ bị xóa vĩnh viễn.',
          style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy',
                style: TextStyle(color: AppTheme.mutedGrey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok =
                  await context.read<UserDataProvider>().deleteHealthData();
              if (context.mounted) {
                await context.read<AuthProvider>().getStats();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Đã xóa toàn bộ dữ liệu sức khỏe'
                        : 'Xóa dữ liệu thất bại'),
                    backgroundColor:
                        ok ? AppTheme.neonGreen : Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Xóa',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// EDIT PROFILE BOTTOM SHEET
// ══════════════════════════════════════════════════════════════
class _EditProfileSheet extends StatefulWidget {
  final AppUser user;
  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late String _selectedColor;
  bool _saving = false;

  static const _colors = ['red', 'purple', 'teal', 'blue', 'amber'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.displayName);
    _selectedColor = widget.user.avatarColor;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final success = await context.read<AuthProvider>().updateProfile(
          displayName: _nameCtrl.text.trim(),
          avatarColor: _selectedColor,
        );

    if (mounted) {
      setState(() => _saving = false);
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.subtleGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Chỉnh sửa hồ sơ',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Preview avatar
          Center(
            child: AvatarCircle(
              initials: widget.user.initials,
              avatarColor: _selectedColor,
              size: 64,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 16),

          // Chọn màu avatar
          const Text('Màu avatar',
              style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: _colors.map((color) {
              final selected = color == _selectedColor;
              final grad = _avatarGradient(color);
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [grad.$1, grad.$2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: selected ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Tên hiển thị
          const Text('Tên hiển thị',
              style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Nhập tên của bạn',
              hintStyle:
                  const TextStyle(color: AppTheme.subtleGrey, fontSize: 14),
              filled: true,
              fillColor: AppTheme.black,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.accentRed, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Nút lưu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
                disabledBackgroundColor:
                    AppTheme.accentRed.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Lưu thay đổi',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// AVATAR CIRCLE — dùng chung trong app
// ══════════════════════════════════════════════════════════════
class AvatarCircle extends StatelessWidget {
  final String initials;
  final String avatarColor;
  final double size;
  final double fontSize;

  const AvatarCircle({
    super.key,
    required this.initials,
    required this.avatarColor,
    this.size = 34,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final grad = _avatarGradient(avatarColor);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [grad.$1, grad.$2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.subtleGrey, width: 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ROLE BADGES
// ══════════════════════════════════════════════════════════════
class _RoleBadge extends StatelessWidget {
  final String color;
  const _RoleBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    final grad = _avatarGradient(color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: grad.$2.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: grad.$2.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: grad.$2, size: 14),
          const SizedBox(width: 5),
          Text(
            'Tài khoản Admin',
            style: TextStyle(
                color: grad.$2,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _UserBadge extends StatelessWidget {
  final String color;
  const _UserBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    final grad = _avatarGradient(color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: grad.$1.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: grad.$1.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_rounded, color: grad.$1, size: 14),
          const SizedBox(width: 5),
          Text(
            'Thành viên',
            style: TextStyle(
                color: grad.$1,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SHARED SMALL WIDGETS
// ══════════════════════════════════════════════════════════════
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatBox(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.accentRed, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.mutedGrey, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
          color: AppTheme.mutedGrey,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                const Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: AppTheme.subtleGrey,
                    indent: 56,
                    endIndent: 0),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.mutedGrey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HELPER — map avatarColor string → gradient colors
// ══════════════════════════════════════════════════════════════
(Color, Color) _avatarGradient(String color) {
  switch (color) {
    case 'purple':
      return (AppTheme.accentPurple, const Color(0xFF7F77DD));
    case 'teal':
      return (const Color(0xFF1D9E75), const Color(0xFF0F6E56));
    case 'blue':
      return (AppTheme.accentBlue, const Color(0xFF185FA5));
    case 'amber':
      return (AppTheme.accentOrange, const Color(0xFFBA7517));
    case 'red':
    default:
      return (AppTheme.accentRed, AppTheme.accentPurple);
  }
}
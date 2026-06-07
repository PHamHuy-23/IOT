import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../themes/app_theme.dart';

// ══════════════════════════════════════════════════════════════
// PROFILE SCREEN — hiện ra khi tap avatar (đã đăng nhập)
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
          // ── Sliver App Bar với banner ──
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
                      AppTheme.accentRed.withOpacity(0.3),
                      AppTheme.accentPurple.withOpacity(0.3),
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
                  // ── Avatar lớn + nút sửa ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _AvatarCircle(
                        initials: user.initials,
                        size: 72,
                        fontSize: 26,
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: mở màn hình chỉnh sửa hồ sơ
                        },
                        icon: const Icon(Icons.edit_rounded, size: 14),
                        label: const Text('Sửa hồ sơ', style: TextStyle(fontSize: 12)),
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
                  Text(
                    user.displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: const TextStyle(
                        color: AppTheme.mutedGrey, fontSize: 13),
                  ),
                  const SizedBox(height: 10),

                  // ── Role badge ──
                  if (user.isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.accentPurple.withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              color: AppTheme.accentPurple, size: 14),
                          SizedBox(width: 5),
                          Text(
                            'Tài khoản Admin',
                            style: TextStyle(
                                color: AppTheme.accentPurple,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── Stats giả lập ──
                  Row(
                    children: [
                      _StatBox(
                          label: 'Ngày theo dõi', value: '128', icon: Icons.calendar_today_rounded),
                      const SizedBox(width: 10),
                      _StatBox(
                          label: 'Đồng bộ', value: '47', icon: Icons.sync_rounded),
                      const SizedBox(width: 10),
                      _StatBox(
                          label: 'Huy hiệu', value: '9', icon: Icons.emoji_events_rounded),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Menu cài đặt ──
                  _SectionLabel('Cài đặt tài khoản'),
                  const SizedBox(height: 8),
                  _MenuGroup(items: [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      iconBg: const Color(0xFF1A0A10),
                      iconColor: AppTheme.accentRed,
                      label: 'Thông tin cá nhân',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.notifications_none_rounded,
                      iconBg: const Color(0xFF0A1020),
                      iconColor: AppTheme.accentBlue,
                      label: 'Thông báo',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.lock_outline_rounded,
                      iconBg: const Color(0xFF1A1020),
                      iconColor: AppTheme.accentPurple,
                      label: 'Bảo mật & Quyền riêng tư',
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 16),
                  _SectionLabel('Dữ liệu sức khỏe'),
                  const SizedBox(height: 8),
                  _MenuGroup(items: [
                    _MenuItem(
                      icon: Icons.bar_chart_rounded,
                      iconBg: const Color(0xFF0A1A10),
                      iconColor: AppTheme.accentGreen,
                      label: 'Lịch sử & Báo cáo',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.cloud_upload_outlined,
                      iconBg: const Color(0xFF0A1020),
                      iconColor: AppTheme.accentBlue,
                      label: 'Xuất dữ liệu',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.delete_outline_rounded,
                      iconBg: const Color(0xFF1A0800),
                      iconColor: AppTheme.accentOrange,
                      label: 'Xóa dữ liệu',
                      onTap: () {},
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
                        style: TextStyle(color: Colors.redAccent, fontSize: 15),
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
                ..pop() // dialog
                ..pop(); // profile screen
            },
            child: const Text('Đăng xuất',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ── Avatar Widget dùng chung ──────────────────────────────────
class _AvatarCircle extends StatelessWidget {
  final String initials;
  final double size;
  final double fontSize;

  const _AvatarCircle({
    required this.initials,
    this.size = 34,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppTheme.accentRed, AppTheme.accentPurple],
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

// ── Stat box nhỏ ──────────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
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

// ── Section label ─────────────────────────────────────────────
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

// ── Menu group ────────────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(9)),
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

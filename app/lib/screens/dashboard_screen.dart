import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/health_provider.dart';
import '../themes/app_theme.dart';
import 'activity_rings.dart';
import 'auth_screen.dart';
import 'metric_detail_screen.dart';
import 'profile_screen.dart';

// ─── Tab index ───────────────────────────────────────────────
enum DashTab { summary, browse, sharing, medicalId }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashTab _tab = DashTab.summary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthProvider>().autoConnectToWatch();
    });
  }

  // Hàm điều hướng đến trang chi tiết dùng chung
  void _openDetail(MetricData metric) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MetricDetailScreen(metric: metric),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: Consumer<HealthProvider>(
          builder: (context, provider, _) {
            return _buildBody(provider);
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── BOTTOM NAV ────────────────────────────────────────────
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _tab.index,
      onTap: (i) => setState(() => _tab = DashTab.values[i]),
      backgroundColor: AppTheme.cardDark,
      selectedItemColor: AppTheme.accentRed,
      unselectedItemColor: AppTheme.mutedGrey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_rounded),
          label: 'Tóm tắt',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_rounded),
          label: 'Duyệt',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.share_rounded),
          label: 'Chia sẻ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medical_information_rounded),
          label: 'ID Y tế',
        ),
      ],
    );
  }

  // ─── BODY router ──────────────────────────────────────────
  Widget _buildBody(HealthProvider provider) {
    switch (_tab) {
      case DashTab.summary:
        return _buildSummaryTab(provider);
      case DashTab.browse:
        return _buildBrowseTab(provider);
      case DashTab.sharing:
        return _buildSharingTab();
      case DashTab.medicalId:
        return _buildMedicalIdTab();
    }
  }

  // ══════════════════════════════════════════════════════════
  // TAB 1: TÓM TẮT
  // ══════════════════════════════════════════════════════════
  Widget _buildSummaryTab(HealthProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.autoConnectToWatch(),
      color: AppTheme.accentRed,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header lớn kiểu Apple
          SliverAppBar(
            backgroundColor: AppTheme.black,
            expandedHeight: 80,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              centerTitle: false,
              title: const Text(
                'Tóm tắt Sức khỏe',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            actions: [
              _buildConnectionChip(provider),
              _buildAvatarButton(),
            ],
          ),

          // Banner lỗi (nếu có)
          if (provider.errorMessage.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _buildErrorBanner(provider.errorMessage),
              ),
            ),

          // Cảnh báo Android
          if (!provider.isConnected &&
              !provider.isConnecting &&
              Platform.isAndroid)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _buildAndroidWarning(),
              ),
            ),

          // ── Activity Rings ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: ActivityRingsWidget(
                steps: provider.isConnected ? 4320 : 0,
                stepsTarget: 10000,
                mindfulMinutes: provider.isConnected ? 10 : 0,
                mindfulTarget: 15,
                waterMl: provider.isConnected ? 1200 : 0,
                waterTarget: 2000,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Bento Grid 2 cột ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildListDelegate([
                // Nhịp tim
                GestureDetector(
                  onTap: () => _openDetail(mockHeartRate(provider.heartRate)),
                  child: _BentoCard(
                    title: 'Nhịp tim',
                    value: provider.isConnected ? '${provider.heartRate}' : '--',
                    unit: 'BPM',
                    icon: Icons.favorite_rounded,
                    color: AppTheme.getHeartRateColor(provider.heartRate),
                    subtitle: _hrStatus(provider.heartRate),
                  ),
                ),
                // SpO2
                GestureDetector(
                  onTap: () => _openDetail(mockSpO2(provider.spO2)),
                  child: _BentoCard(
                    title: 'Oxy trong máu',
                    value: provider.isConnected ? '${provider.spO2}' : '--',
                    unit: '%',
                    icon: Icons.bloodtype_rounded,
                    color: AppTheme.getSpO2Color(provider.spO2),
                    subtitle: _spo2Status(provider.spO2),
                  ),
                ),
                // Bước chân
                GestureDetector(
                  onTap: () => _openDetail(mockSteps(provider.isConnected)),
                  child: _BentoCard(
                    title: 'Bước chân',
                    value: provider.isConnected ? '4,320' : '--',
                    unit: 'bước',
                    icon: Icons.directions_walk_rounded,
                    color: AppTheme.accentGreen,
                    subtitle: 'Mục tiêu: 8,000',
                  ),
                ),
                // Năng lượng (Chưa có mock riêng nên tạm thời dẫn tới trang Bước chân hoặc Calories tùy thiết kế)
                GestureDetector(
                  onTap: () => _openDetail(mockSteps(provider.isConnected)), 
                  child: _BentoCard(
                    title: 'Năng lượng',
                    value: provider.isConnected ? '185' : '--',
                    unit: 'kcal',
                    icon: Icons.local_fire_department_rounded,
                    color: AppTheme.accentOrange,
                    subtitle: 'Hoạt động hôm nay',
                  ),
                ),
              ]),
            ),
          ),

          // ── Ô giấc ngủ rộng (ĐÃ KẾT NỐI ON TAP) ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => _openDetail(mockSleep(provider.isConnected)),
                child: _WideBentoCard(
                  title: 'Giấc ngủ',
                  value: provider.isConnected ? '6h 45m' : '--',
                  icon: Icons.bedtime_rounded,
                  color: AppTheme.accentPurple,
                  subtitle: 'Ngủ sâu: 2h 15m  •  Đang phân tích',
                ),
              ),
            ),
          ),

          // ── Nút điều khiển ──
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildSyncButton(provider),
                  const SizedBox(height: 10),
                  if (provider.isConnected)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => provider.disconnectDevice(),
                        icon: const Icon(Icons.power_settings_new,
                            color: Colors.redAccent),
                        label: const Text(
                          'Ngắt kết nối thiết bị',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    )
                  else if (!provider.isConnecting)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => provider.autoConnectToWatch(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentRed,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Quét & Kết nối'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 2: DUYỆT (ĐÃ KẾT NỐI CLICK CHO TỪNG MỤC)
  // ══════════════════════════════════════════════════════════
  Widget _buildBrowseTab(HealthProvider provider) {
    // Định nghĩa các danh mục kèm theo hành động tương ứng khi ấn vào
    final categories = [
      _BrowseCategory(
        icon: Icons.directions_run_rounded,
        label: 'Hoạt động',
        sub: 'Bước chân, Khoảng cách, Tập thể dục',
        onTap: () => _openDetail(mockSteps(provider.isConnected)),
      ),
      _BrowseCategory(
        icon: Icons.favorite_rounded,
        label: 'Tim mạch',
        sub: 'Nhịp tim, Điện tâm đồ',
        onTap: () => _openDetail(mockHeartRate(provider.heartRate)),
      ),
      _BrowseCategory(
        icon: Icons.bloodtype_rounded,
        label: 'Oxy trong máu',
        sub: 'Chỉ số SpO2 thời gian thực',
        onTap: () => _openDetail(mockSpO2(provider.spO2)),
      ),
      _BrowseCategory(
        icon: Icons.bedtime_rounded,
        label: 'Giấc ngủ',
        sub: 'Phân tích sâu REM, Ngủ sâu',
        onTap: () => _openDetail(mockSleep(provider.isConnected)),
      ),
      _BrowseCategory(
        icon: Icons.water_drop_rounded,
        label: 'Dinh dưỡng & Nước',
        sub: 'Hydrat hóa, Lượng calo',
        onTap: () => _openDetail(mockSteps(provider.isConnected)), // Thay thế bằng hàm mock dinh dưỡng nếu có
      ),
      _BrowseCategory(
        icon: Icons.self_improvement_rounded,
        label: 'Chánh niệm',
        sub: 'Thiền định, Hơi thở',
        onTap: () => _openDetail(mockSteps(provider.isConnected)), // Thay thế bằng hàm mock chánh niệm nếu có
      ),
    ];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          backgroundColor: AppTheme.black,
          pinned: true,
          elevation: 0,
          title: const Text(
            'Duyệt',
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildBrowseRow(categories[i]),
              childCount: categories.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrowseRow(_BrowseCategory cat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: cat.onTap, // Thêm sự kiện nhấn vào ListTile tại đây
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.cardDarker,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(cat.icon, color: AppTheme.accentRed, size: 22),
        ),
        title: Text(cat.label,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(cat.sub,
            style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppTheme.mutedGrey, size: 20),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 3: CHIA SẺ
  // ══════════════════════════════════════════════════════════
  Widget _buildSharingTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          backgroundColor: AppTheme.black,
          pinned: true,
          elevation: 0,
          title: const Text(
            'Chia sẻ',
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        SliverFillRemaining(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.qr_code_2_rounded,
                          size: 120, color: Colors.white),
                      const SizedBox(height: 16),
                      const Text(
                        'Mã QR Khám Chữa Bệnh',
                        style: TextStyle(
                            color: AppTheme.accentRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cho bác sĩ quét để xem hồ sơ sức khỏe được mã hoá an toàn.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 12, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.neonGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'LIVE SYNC',
                          style: TextStyle(
                              color: AppTheme.neonGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 4: ID Y TẾ
  // ══════════════════════════════════════════════════════════
  Widget _buildMedicalIdTab() {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final name = user?.displayName ?? 'Khách vãng lai';
    final email = user?.email ?? 'Không có email';
    final uid = user?.id ?? 'Không có UID';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          backgroundColor: AppTheme.black,
          pinned: true,
          elevation: 0,
          title: const Text(
            'ID Y tế',
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                // Banner khẩn cấp
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.accentRed.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.local_hospital_rounded,
                          color: AppTheme.accentRed, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hiển thị trên màn hình khóa để hỗ trợ cứu thương khẩn cấp',
                          style: TextStyle(
                              color: AppTheme.accentRed,
                              fontSize: 12,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Thông tin y tế
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _medRow('Họ và Tên', name, isFirst: true),
                      _medRow('Email', email),
                      _medRow('UID', uid),
                      _medRow('Nhóm máu', 'O+  (Rh dương)',
                          valueColor: AppTheme.accentRed),
                      _medRow('Chiều cao / Cân nặng', '168 cm  /  54 kg'),
                      _medRow('Dị ứng', 'Penicillin, Đậu phộng',
                          valueColor: AppTheme.accentOrange, isLast: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _medRow(
    String label,
    String value, {
    Color? valueColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppTheme.subtleGrey, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.mutedGrey, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ══════════════════════════════════════════════════════════
  Widget _buildConnectionChip(HealthProvider provider) {
    final connected = provider.isConnected;
    final connecting = provider.isConnecting;
    final color = connected
        ? AppTheme.neonGreen
        : (connecting ? AppTheme.accentOrange : AppTheme.mutedGrey);
    final label = connected
        ? 'Connected'
        : (connecting ? 'Connecting...' : 'Disconnected');

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return GestureDetector(
            onTap: () => _openProfileOrAuth(auth),
            child: auth.isLoggedIn
                ? Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.accentRed, AppTheme.accentPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: AppTheme.subtleGrey, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        auth.currentUser!.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.cardDark,
                      border: Border.all(color: AppTheme.subtleGrey, width: 1),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppTheme.mutedGrey,
                      size: 18,
                    ),
                  ),
          );
        },
      ),
    );
  }

  void _openProfileOrAuth(AuthProvider auth) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            auth.isLoggedIn ? const ProfileScreen() : const AuthScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSyncButton(HealthProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: provider.isConnected
            ? () async {
                await provider.syncTimeToWatch();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã đồng bộ thời gian!'),
                      duration: Duration(seconds: 1),
                      backgroundColor: AppTheme.neonGreen,
                    ),
                  );
                }
              }
            : null,
        icon: const Icon(Icons.schedule_rounded, size: 18),
        label: const Text('Đồng bộ giờ lên đồng hồ'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: provider.isConnected
              ? AppTheme.accentPurple
              : AppTheme.cardDarker,
          foregroundColor:
              provider.isConnected ? Colors.white : AppTheme.mutedGrey,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: const Text(
        'Android: Tránh ghép đôi ESP32 trong Cài đặt Bluetooth. Chỉ kết nối qua app. Bật Định vị nếu quét lỗi.',
        style: TextStyle(color: Colors.orange, fontSize: 11, height: 1.4),
      ),
    );
  }

  // ─── Status helpers ────────────────────────────────────────
  String _hrStatus(int hr) {
    if (hr == 0) return 'Chờ dữ liệu...';
    if (hr < 60) return 'Nhịp chậm';
    if (hr <= 100) return 'Bình thường';
    return 'Nhịp nhanh';
  }

  String _spo2Status(int spo2) {
    if (spo2 == 0) return 'Chờ dữ liệu...';
    if (spo2 >= 95) return 'Excellent';
    if (spo2 >= 90) return 'Good';
    return 'Thấp';
  }
}

// ══════════════════════════════════════════════════════════════
// BENTO CARD WIDGET (2 cột)
// ══════════════════════════════════════════════════════════════
class _BentoCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _BentoCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppTheme.mutedGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1)),
              const SizedBox(width: 3),
              Text(unit,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          Text(subtitle,
              style: const TextStyle(
                  color: AppTheme.mutedGrey, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDE BENTO CARD (full width — giấc ngủ)
// ══════════════════════════════════════════════════════════════
class _WideBentoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _WideBentoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppTheme.mutedGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppTheme.mutedGrey, fontSize: 11)),
            ],
          ),
          Icon(icon, color: color, size: 38),
        ],
      ),
    );
  }
}

// ── Data class định nghĩa danh mục kèm hành động ─────────────────
class _BrowseCategory {
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap; // Bổ sung thuộc tính onTap nhận sự kiện click

  const _BrowseCategory({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });
}
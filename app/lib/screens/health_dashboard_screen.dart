import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';

class HealthColors {
  static const Color background = Color(0xFF000000);
  static const Color cardBg = Color(0xFF1C1C1E);
  static const Color heartRate = Color(0xFFFF3B30);
  static const Color spo2 = Color(0xFF00F5D4);
  static const Color steps = Color(0xFF34C759);
  static const Color energy = Color(0xFFFF9500);
  static const Color sleep = Color(0xFFAF52DE);
}

class HealthDashboardScreen extends StatelessWidget {
  const HealthDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealthColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: HealthColors.background,
              expandedHeight: 100.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildListDelegate([
                  Consumer<HealthProvider>(
                    builder: (context, provider, _) => _buildBentoCard(
                      title: 'Nhịp tim',
                      value: provider.isConnected ? '${provider.heartRate}' : '--',
                      unit: 'BPM',
                      icon: Icons.favorite_rounded,
                      color: HealthColors.heartRate,
                      subtitle: provider.isConnected ? 'Đang đo thực tế' : 'Chưa kết nối',
                    ),
                  ),
                  Consumer<HealthProvider>(
                    builder: (context, provider, _) => _buildBentoCard(
                      title: 'Oxy trong máu',
                      value: provider.isConnected ? '${provider.spO2}' : '--',
                      unit: '%',
                      icon: Icons.bloodtype_rounded,
                      color: HealthColors.spo2,
                      subtitle: 'Chỉ số SpO2',
                    ),
                  ),
                  _buildBentoCard(
                    title: 'Bước chân',
                    value: '4,230',
                    unit: 'bước',
                    icon: Icons.directions_walk_rounded,
                    color: HealthColors.steps,
                    subtitle: 'Mục tiêu: 8,000',
                  ),
                  _buildBentoCard(
                    title: 'Năng lượng',
                    value: '185',
                    unit: 'kcal',
                    icon: Icons.local_fire_department_rounded,
                    color: HealthColors.energy,
                    subtitle: 'Hoạt động trong ngày',
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverToBoxAdapter(
                child: _buildWideBentoCard(
                  title: 'Giấc ngủ',
                  value: '6h 45m',
                  icon: Icons.bedtime_rounded,
                  color: HealthColors.sleep,
                  subtitle: 'Ngủ sâu: 2h 15m • Đủ chỉ tiêu',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HealthColors.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
              Icon(icon, color: color, size: 22),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Text(unit, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white30, fontSize: 11, overflow: TextOverflow.ellipsis)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWideBentoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HealthColors.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white30, fontSize: 12)),
            ],
          ),
          Icon(icon, color: color, size: 40),
        ],
      ),
    );
  }
}

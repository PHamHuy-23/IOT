import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedPeriod = 'today'; // today, week, month, year
  Map<String, dynamic>? _todaySummary;
  List<Map<String, dynamic>> _periodSummary = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<SupabaseProvider>();

    if (_selectedPeriod == 'today') {
      final summary = await provider.getDailySummary(DateTime.now());
      setState(() => _todaySummary = summary);
    } else if (_selectedPeriod == 'week') {
      final monday = DateTime.now().subtract(
        Duration(days: DateTime.now().weekday - 1),
      );
      final summary = await provider.getWeeklySummary(monday);
      setState(() => _periodSummary = summary);
    } else if (_selectedPeriod == 'month') {
      final now = DateTime.now();
      final summary = await provider.getMonthlySummary(now.year, now.month);
      setState(() => _periodSummary = summary);
    } else if (_selectedPeriod == 'year') {
      final summary = await provider.getYearlySummary(DateTime.now().year);
      setState(() => _periodSummary = summary);
    }
  }

  @override
void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title: const Text(
          'Thống kê Sức khỏe',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPeriodButton('Hôm nay', 'today'),
                  _buildPeriodButton('Tuần', 'week'),
                  _buildPeriodButton('Tháng', 'month'),
                  _buildPeriodButton('Năm', 'year'),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _selectedPeriod == 'today'
                    ? _buildTodayStats()
                    : _buildPeriodStats(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = period);
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF3B30)
              : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTodayStats() {
    if (_todaySummary == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        _buildStatCard(
          title: 'Nhịp tim',
          average: _todaySummary?['avg_heart_rate']?.toString() ?? '--',
          min: _todaySummary?['min_heart_rate']?.toString() ?? '--',
          max: _todaySummary?['max_heart_rate']?.toString() ?? '--',
          unit: 'BPM',
          color: const Color(0xFFFF3B30),
          icon: Icons.favorite_rounded,
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          title: 'Oxy trong máu',
          average: _todaySummary?['avg_spo2']?.toString() ?? '--',
          min: _todaySummary?['min_spo2']?.toString() ?? '--',
          max: _todaySummary?['max_spo2']?.toString() ?? '--',
          unit: '%',
          color: const Color(0xFF00F5D4),
          icon: Icons.bloodtype_rounded,
        ),
      ],
    );
  }

  Widget _buildPeriodStats() {
    if (_periodSummary.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có dữ liệu',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: _periodSummary.map((summary) {
        return Column(
          children: [
            _buildStatCard(
              title: 'Nhịp tim (${summary['date']})',
              average: summary['avg_heart_rate']?.toString() ?? '--',
              min: summary['min_heart_rate']?.toString() ?? '--',
              max: summary['max_heart_rate']?.toString() ?? '--',
              unit: 'BPM',
              color: const Color(0xFFFF3B30),
              icon: Icons.favorite_rounded,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Oxy (${summary['date']})',
              average: summary['avg_spo2']?.toString() ?? '--',
              min: summary['min_spo2']?.toString() ?? '--',
              max: summary['max_spo2']?.toString() ?? '--',
              unit: '%',
              color: const Color(0xFF00F5D4),
              icon: Icons.bloodtype_rounded,
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String average,
    required String min,
    required String max,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildValueColumn('Trung bình', average, unit, color),
              _buildValueColumn('Thấp nhất', min, unit, Colors.grey),
              _buildValueColumn('Cao nhất', max, unit, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueColumn(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

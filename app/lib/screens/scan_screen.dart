import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/ble_constants.dart';
import '../models/ble_device_model.dart';
import '../services/permission_service.dart';
import '../services/ble_service.dart';
import '../themes/app_theme.dart';
import 'connect_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  final BleService _bleService = BleService();
  List<BleDeviceModel> discoveredDevices = [];
  bool isScanning = false;
  String statusMessage = 'Nhấn nút để bắt đầu quét';
  String? permissionError;

  // Animation cho nút scan (pulse khi đang quét)
  late AnimationController _scanPulseCtrl;
  late Animation<double> _scanPulseAnim;

  @override
  void initState() {
    super.initState();
    _scanPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scanPulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _scanPulseCtrl, curve: Curves.easeInOut),
    );
    _checkPermissions();
  }

  @override
  void dispose() {
    _scanPulseCtrl.dispose();
    unawaited(_bleService.stopScan());
    super.dispose();
  }

  // ── Permissions ──────────────────────────────────────────
  Future<void> _checkPermissions() async {
    bool has = await PermissionService.hasBluetoothPermissions();
    if (has) {
      setState(() => permissionError = null);
      return;
    }
    final issue = await PermissionService.androidBleReadinessIssue();
    if (issue != null) {
      setState(() => permissionError = issue);
      return;
    }
    bool granted = await PermissionService.requestBluetoothPermissions();
    if (!granted) {
      final err = await PermissionService.androidBleReadinessIssue();
      setState(() => permissionError = err ?? 'Cần quyền Bluetooth và Vị trí.');
    }
  }

  // ── Scan ─────────────────────────────────────────────────
  void _startScan() async {
    final issue = await PermissionService.androidBleReadinessIssue();
    if (issue != null) {
      setState(() => permissionError = issue);
      return;
    }

    setState(() {
      discoveredDevices.clear();
      isScanning = true;
      statusMessage = 'Đang quét...';
    });
    _scanPulseCtrl.repeat(reverse: true);

    try {
      await _bleService.startScan();
      _bleService.scanResults.listen((results) {
        final newDevices = <BleDeviceModel>[];
        for (final r in results) {
          final name = r.advertisementData.advName.isNotEmpty
              ? r.advertisementData.advName
              : (r.device.platformName.isNotEmpty
                  ? r.device.platformName
                  : r.device.remoteId.str);
          final d = BleDeviceModel(
            device: r.device,
            deviceName: name,
            deviceId: r.device.remoteId.str,
            rssi: r.rssi,
          );
          if (!newDevices.any((x) => x.deviceId == d.deviceId)) {
            newDevices.add(d);
          }
        }
        setState(() {
          for (final d in newDevices) {
            if (!discoveredDevices.any((x) => x.deviceId == d.deviceId)) {
              discoveredDevices.add(d);
            }
          }
          statusMessage = 'Tìm thấy ${discoveredDevices.length} thiết bị';
        });
      });

      await Future.delayed(Duration(seconds: SCAN_TIMEOUT_SECONDS));
      await _stopScan();
    } catch (e) {
      setState(() {
        statusMessage = 'Lỗi khi quét: $e';
        isScanning = false;
      });
      _scanPulseCtrl.stop();
    }
  }

  Future<void> _stopScan() async {
    try {
      await _bleService.stopScan();
    } catch (_) {}
    _scanPulseCtrl.stop();
    _scanPulseCtrl.reset();
    setState(() {
      isScanning = false;
      statusMessage = discoveredDevices.isEmpty
          ? 'Không tìm thấy thiết bị nào.'
          : 'Tìm thấy ${discoveredDevices.length} thiết bị.';
    });
  }

  // ── Connect ───────────────────────────────────────────────
  void _connectToDevice(BleDeviceModel device) async {
    setState(() => device.isConnecting = true);
    try {
      await _bleService.connectToDevice(device.device);
      setState(() => device.updateConnectionStatus(true));
      await _stopScan();
      if (mounted) {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ConnectScreen(
              device: device,
              bleService: _bleService,
            ),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => device.isConnecting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể kết nối: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (permissionError != null) return _buildPermissionError();

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildScanButton(),
            Expanded(child: _buildDeviceList()),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Quét thiết bị',
            style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold),
          ),
          // Status chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isScanning
                        ? AppTheme.accentOrange
                        : discoveredDevices.isNotEmpty
                            ? AppTheme.neonGreen
                            : AppTheme.mutedGrey,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isScanning
                      ? 'Đang quét'
                      : discoveredDevices.isNotEmpty
                          ? '${discoveredDevices.length} thiết bị'
                          : 'Chờ quét',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Scan button ──────────────────────────────────────────
  Widget _buildScanButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: ScaleTransition(
        scale: isScanning ? _scanPulseAnim : const AlwaysStoppedAnimation(1.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isScanning ? _stopScan : _startScan,
            icon: Icon(
              isScanning
                  ? Icons.stop_rounded
                  : Icons.bluetooth_searching_rounded,
              size: 20,
            ),
            label: Text(
              isScanning ? 'Dừng quét' : 'Bắt đầu quét',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isScanning ? Colors.redAccent : AppTheme.accentRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }

  // ── Device list ──────────────────────────────────────────
  Widget _buildDeviceList() {
    if (discoveredDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isScanning
                  ? Icons.radar_rounded
                  : Icons.bluetooth_disabled_rounded,
              size: 56,
              color: AppTheme.mutedGrey.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              isScanning
                  ? 'Đang tìm kiếm thiết bị...'
                  : 'Nhấn "Bắt đầu quét"\nđể tìm thiết bị BLE',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.mutedGrey,
                  fontSize: 14,
                  height: 1.5),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: discoveredDevices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _buildDeviceCard(discoveredDevices[i]),
    );
  }

  // ── Device card ──────────────────────────────────────────
  Widget _buildDeviceCard(BleDeviceModel device) {
    final bars = device.rssi >= -60
        ? 4
        : device.rssi >= -75
            ? 3
            : device.rssi >= -85
                ? 2
                : 1;
    final signalColor = bars >= 3
        ? AppTheme.neonGreen
        : bars == 2
            ? AppTheme.accentOrange
            : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
        border: device.isConnected
            ? Border.all(color: AppTheme.neonGreen.withOpacity(0.4), width: 1)
            : null,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: device.isConnected
                  ? AppTheme.neonGreen.withOpacity(0.12)
                  : AppTheme.accentRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              device.isConnected
                  ? Icons.bluetooth_connected_rounded
                  : Icons.bluetooth_rounded,
              color: device.isConnected
                  ? AppTheme.neonGreen
                  : AppTheme.accentRed,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.getDisplayName(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  device.deviceId,
                  style: const TextStyle(
                      color: AppTheme.mutedGrey, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                // Signal bars mini
                Row(
                  children: [
                    ...List.generate(4, (i) => Container(
                          width: 3.5,
                          height: 5.0 + i * 2.5,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            color: i < bars
                                ? signalColor
                                : AppTheme.subtleGrey,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        )),
                    const SizedBox(width: 6),
                    Text(
                      '${device.rssi} dBm',
                      style: TextStyle(
                          color: signalColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Connect button
          device.isConnecting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.accentRed,
                  ),
                )
              : GestureDetector(
                  onTap: device.isConnected
                      ? null
                      : () => _connectToDevice(device),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: device.isConnected
                          ? AppTheme.neonGreen.withOpacity(0.12)
                          : AppTheme.accentRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      device.isConnected ? 'Đã kết nối' : 'Kết nối',
                      style: TextStyle(
                        color: device.isConnected
                            ? AppTheme.neonGreen
                            : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // ── Permission error screen ───────────────────────────────
  Widget _buildPermissionError() {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bluetooth_disabled_rounded,
                    size: 40, color: Colors.redAccent),
              ),
              const SizedBox(height: 24),
              const Text(
                'Cần quyền truy cập',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                permissionError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.mutedGrey,
                    fontSize: 14,
                    height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await PermissionService.openAppSettingsPage();
                    await Future.delayed(const Duration(milliseconds: 500));
                    if (mounted) _checkPermissions();
                  },
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: const Text('Mở Cài đặt',
                      style: TextStyle(fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _checkPermissions,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Kiểm tra lại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.mutedGrey,
                    side: const BorderSide(color: AppTheme.subtleGrey),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
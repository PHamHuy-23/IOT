import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/family_share_provider.dart';
import '../themes/app_theme.dart';
import 'shared_health_screen.dart';

class ScanFamilyQrScreen extends StatefulWidget {
  const ScanFamilyQrScreen({super.key});

  @override
  State<ScanFamilyQrScreen> createState() => _ScanFamilyQrScreenState();
}

class _ScanFamilyQrScreenState extends State<ScanFamilyQrScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _processing = false;
  bool _cameraDenied = false;

  @override
  void initState() {
    super.initState();
    _ensureCamera();
  }

  Future<void> _ensureCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() => _cameraDenied = !status.isGranted);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;

    setState(() => _processing = true);
    await _controller.stop();

    final owner = await context.read<FamilyShareProvider>().joinByQr(raw);

    if (!mounted) return;

    if (owner != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã kết nối với ${owner.displayName}'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SharedHealthScreen(owner: owner),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<FamilyShareProvider>().error.isNotEmpty
                ? context.read<FamilyShareProvider>().error
                : 'Không thể kết nối',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _processing = false);
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Quét mã người thân',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _cameraDenied
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Cần quyền camera để quét mã QR',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.mutedGrey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: openAppSettings,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentRed),
                      child: const Text('Mở Cài đặt'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppTheme.black, AppTheme.black.withOpacity(0)],
                ),
              ),
              child: Column(
                children: [
                  if (_processing)
                    const CircularProgressIndicator(color: AppTheme.accentRed)
                  else
                    const Text(
                      'Hướng camera vào mã QR trên điện thoại\n'
                      'của người đang đeo thiết bị',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


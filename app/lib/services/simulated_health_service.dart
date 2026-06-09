import 'dart:async';
import 'dart:math';

/// Mô phỏng dữ liệu cho tài khoản admin / testing khi không có BLE.
class SimulatedHealthService {
  final _random = Random();
  Timer? _timer;
  int _tick = 0;

  /// Scenario: 0=normal, 1=high HR, 2=low SpO2, 3=fall cycle
  int scenario = 0;
  void Function()? onPeriodicFall;

  void start({
    required void Function(int hr, int spo2) onVitals,
    Duration interval = const Duration(seconds: 2),
  }) {
    stop();
    _tick = 0;
    _timer = Timer.periodic(interval, (_) {
      _tick++;
      final (hr, spo2) = _generateVitals();
      onVitals(hr, spo2);
      if (scenario == 3 && _tick % 20 == 0) {
        onPeriodicFall?.call();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  (int, int) _generateVitals() {
    switch (scenario) {
      case 1:
        return (125 + _random.nextInt(15), 96 + _random.nextInt(3));
      case 2:
        return (72 + _random.nextInt(8), 85 + _random.nextInt(4));
      case 3:
        return (95 + _random.nextInt(20), 97);
      default:
        return (68 + _random.nextInt(12), 96 + _random.nextInt(4));
    }
  }

  /// Một lần đo bất thường cố định cho nút test
  (int, int) vitalsForScenario(int s) {
    switch (s) {
      case 1:
        return (135, 97);
      case 2:
        return (75, 86);
      default:
        return (72, 98);
    }
  }
}

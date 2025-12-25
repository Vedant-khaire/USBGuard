import 'dart:async';
import 'dart:math';

class MockUsbService {
  static final _controller = StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get stream => _controller.stream;

  static Timer? _timer;
  static final _rand = Random();

  static void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final inserted = _rand.nextBool();
      final drive = "${String.fromCharCode(68 + _rand.nextInt(4))}:\\";
      _controller.add({
        "event": inserted ? "arrival" : "remove",
        "drive": drive,
      });
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static void fakeScan(String drive) {
    // deliver a scan result in 1–2 seconds
    Future.delayed(Duration(milliseconds: 800 + _rand.nextInt(900)), () {
      final threat = _rand.nextInt(5) == 0; // ~20% chance
      _controller.add({
        "event": "scan",
        "drive": drive,
        "threat": threat,
      });
    });
  }
}

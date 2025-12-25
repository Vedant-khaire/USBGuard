import 'dart:async';
import 'dart:io';

class USBService {
  final _controller = StreamController<USBEvent>.broadcast();
  List<String> _lastDrives = [];

  Stream<USBEvent> get events => _controller.stream;

  void startMonitoring() {
    Timer.periodic(const Duration(seconds: 2), (timer) {
      final drives = _listUsbDrives();

      // detect insert
      for (final d in drives) {
        if (!_lastDrives.contains(d)) {
          _controller.add(USBEvent('arrival', d));
        }
      }

      // detect removal
      for (final d in _lastDrives) {
        if (!drives.contains(d)) {
          _controller.add(USBEvent('remove', d));
        }
      }

      _lastDrives = drives;
    });
  }

  List<String> _listUsbDrives() {
    final drives = <String>[];
    if (Platform.isWindows) {
      for (var i = 67; i <= 90; i++) { // C: to Z:
        final drive = String.fromCharCode(i) + r':\';
        final dir = Directory(drive);
        if (dir.existsSync()) {
          if (drive != r'C:\') drives.add(drive); // skip system C: drive
        }
      }
    }
    return drives;
  }
}

class USBEvent {
  final String event; // 'arrival' or 'remove'
  final String drive;

  USBEvent(this.event, this.drive);
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/log_entry.dart';
import '../services/usb_service.dart';
import '../services/db_service.dart';
import 'dart:io';
import '../services/usb_blocker.dart'
    if (dart.library.html) '../services/usb_blocker_stub.dart'
    if (dart.library.io) '../services/usb_blocker.dart';

class AppState extends ChangeNotifier {
  bool isMonitoring = false;
  bool isDarkMode = false;

  bool autoBlockEnabled = false;       // Block all USBs on arrival
  bool autoBlockOnThreat = true;       // Block only if a real threat is detected
  bool lastBlockSucceeded = false;

  bool autoScanEnabled = true;         //  Auto scan toggle (default ON)
  String defaultScanMode = "quick";    //  "quick" or "full"

  final List<String> connectedDrives = [];
  final List<LogEntry> logs = [];

  USBService? _usbService;
  StreamSubscription<USBEvent>? _usbSub;

  // Progress + Threats tracking
  Map<String, double> scanProgress = {}; // 0.0 → 1.0
  Map<String, List<String>> threatDetails = {}; // drive → list of suspicious/threat files

  AppState() {
    _init(); // load prefs + logs + listener
  }

  Future<void> _init() async {
    await _loadPrefs();
    await loadLogsFromDB();
    startUsbListener();
  }

  //  Load settings from SharedPreferences
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool('isDarkMode') ?? false;
    autoScanEnabled = prefs.getBool('autoScanEnabled') ?? true;
    autoBlockEnabled = prefs.getBool('autoBlockEnabled') ?? false;
    autoBlockOnThreat = prefs.getBool('autoBlockOnThreat') ?? true;
    defaultScanMode = prefs.getString('defaultScanMode') ?? "quick";
    notifyListeners();
  }

  // Save settings
  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', isDarkMode);
    prefs.setBool('autoScanEnabled', autoScanEnabled);
    prefs.setBool('autoBlockEnabled', autoBlockEnabled);
    prefs.setBool('autoBlockOnThreat', autoBlockOnThreat);
    prefs.setString('defaultScanMode', defaultScanMode);
  }

  Future<void> setDefaultScanMode(String mode) async {
    defaultScanMode = mode;
    await _savePrefs();
    notifyListeners();
  }

  Future<void> loadLogsFromDB() async {
    logs.clear();
    logs.addAll(await DBService.fetchLogs());
    notifyListeners();
  }

  Future<void> addLog(LogEntry log) async {
    logs.add(log);
    await DBService.insertLog(log);
    notifyListeners();
  }

  Future<void> setAutoBlockEnabled(bool value) async {
    autoBlockEnabled = value;
    await _savePrefs();
    notifyListeners();
  }

  Future<void> setAutoBlockOnThreat(bool value) async {
    autoBlockOnThreat = value;
    await _savePrefs();
    notifyListeners();
  }

  void toggleAutoScan() {
    autoScanEnabled = !autoScanEnabled;
    _savePrefs();
    notifyListeners();
  }

  Future<bool> blockAllNow() async {
    final ok = await UsbBlocker.blockAllUsbStorage();
    lastBlockSucceeded = ok;
    await addLog(LogEntry(
      timestamp: DateTime.now(),
      event: 'manual_block',
      message: ok
          ? 'Manually blocked all USB storage (USBSTOR=4)'
          : 'Manual block FAILED (need Admin)',
    ));
    return ok;
  }

  Future<bool> unblockAllNow() async {
    final ok = await UsbBlocker.unblockAllUsbStorage();
    await addLog(LogEntry(
      timestamp: DateTime.now(),
      event: 'manual_unblock',
      message: ok
          ? 'Manually unblocked all USB storage (USBSTOR=3)'
          : 'Manual unblock FAILED (need Admin)',
    ));
    return ok;
  }

  Future<int?> queryUsbStor() => UsbBlocker.getUsbStorStartValue();

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    _savePrefs();
    notifyListeners();
  }

void startUsbListener() {
  stopUsbListener(); // ensure clean restart
  _usbService = USBService();
  _usbService!.startMonitoring();
  _usbSub = _usbService!.events.listen(_onUsbEvent);
}

  void stopUsbListener() {
    _usbSub?.cancel();
    _usbSub = null;
    _usbService = null;
  }

  void startMonitoring() {
    if (isMonitoring) return;
    isMonitoring = true;
    addLog(LogEntry(
      timestamp: DateTime.now(),
      event: 'info',
      message: 'Monitoring started',
    ));
    startUsbListener();
    notifyListeners();
  }

  void stopMonitoring() {
    if (!isMonitoring) return;
    isMonitoring = false;
    stopUsbListener();
    addLog(LogEntry(
      timestamp: DateTime.now(),
      event: 'info',
      message: 'Monitoring stopped',
    ));
    notifyListeners();
  }

  void _onUsbEvent(USBEvent e) async {
    if (e.event == 'arrival') {
      if (!connectedDrives.contains(e.drive)) {
        connectedDrives.add(e.drive);
      }

      if (autoBlockEnabled) {
        final ok = await UsbBlocker.blockAllUsbStorage();
        lastBlockSucceeded = ok;
        await addLog(LogEntry(
          timestamp: DateTime.now(),
          event: 'autoblock',
          drive: e.drive,
          message: ok
              ? 'Auto-blocked USB storage (USBSTOR=4) on ${e.drive}'
              : 'Auto-block FAILED (need Admin) for ${e.drive}',
        ));
      }

      await addLog(LogEntry(
        timestamp: DateTime.now(),
        event: 'arrival',
        drive: e.drive,
        message: 'USB Inserted: ${e.drive}',
      ));

      if (autoScanEnabled) {
        if (defaultScanMode == "quick") {
          scanDrive(e.drive);
        } else {
          fullScanDrive(e.drive);
        }
      }
    } else if (e.event == 'remove') {
      connectedDrives.remove(e.drive);
      await addLog(LogEntry(
        timestamp: DateTime.now(),
        event: 'remove',
        drive: e.drive,
        message: 'USB Removed: ${e.drive}',
      ));
    }
  }

  // ---------------- SCANNING LOGIC ----------------

  /// Quick Scan (fast, shallow, root + limited depth)
  Future<List<String>> _quickScan(String drive) async {
    final suspiciousExtensions = ['.bat', '.cmd', '.ps1', '.vbs', '.exe'];
    final suspiciousFiles = ['autorun.inf'];
    final foundThreats = <String>[];

    try {
      final dir = Directory(drive);
      if (!dir.existsSync()) return foundThreats;

      final entities = dir.listSync(recursive: false, followLinks: false);
      final total = entities.length;

      for (var i = 0; i < total; i++) {
        final entity = entities[i];
        if (entity is File) {
          final name = entity.path.toLowerCase();
          if (suspiciousExtensions.any((ext) => name.endsWith(ext)) ||
              suspiciousFiles.any((bad) => name.endsWith(bad))) {
            foundThreats.add(entity.path);
          }
        }
        // update progress
        scanProgress[drive] = (i + 1) / total;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 80));
      }
    } catch (e) {
      debugPrint(" Quick scan error on $drive: $e");
    }
    return foundThreats;
  }

 /// Full Deep Scan (slow, checks all files safely)
Future<List<String>> _fullScan(String drive) async {
  final suspiciousExtensions = ['.bat', '.cmd', '.ps1', '.vbs', '.exe'];
  final suspiciousFiles = ['autorun.inf'];
  final foundThreats = <String>[];

  try {
    final dir = Directory(drive);
    if (!dir.existsSync()) return foundThreats;

    final entities = dir.listSync(recursive: true, followLinks: false);
    final total = entities.length;

    for (var i = 0; i < total; i++) {
      final entity = entities[i];
      try {
        if (entity is File) {
          final name = entity.path.toLowerCase();
          if (suspiciousExtensions.any((ext) => name.endsWith(ext)) ||
              suspiciousFiles.any((bad) => name.endsWith(bad))) {
            foundThreats.add(entity.path);
          }
        }
      } on FileSystemException catch (e) {
        // Skip files/folders we don’t have permission for
        debugPrint("Skipped (no access): ${entity.path} -> $e");
      }

      // Update progress
      scanProgress[drive] = (i + 1) / total;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 40));
    }
  } catch (e) {
    debugPrint("Full scan failed on $drive: $e");
  }
  return foundThreats;
}


  /// Default Quick Scan
  void scanDrive(String drive) async {
    scanProgress[drive] = 0;
    threatDetails[drive] = [];
    notifyListeners();

    final threats = await _quickScan(drive);
    threatDetails[drive] = threats;
    await _finalizeScan(drive, threats, quick: true);

    scanProgress[drive] = 1.0;
    notifyListeners();
  }

  /// Manual Full Scan
  void fullScanDrive(String drive) async {
    scanProgress[drive] = 0;
    threatDetails[drive] = [];
    notifyListeners();

    final threats = await _fullScan(drive);
    threatDetails[drive] = threats;
    await _finalizeScan(drive, threats, quick: false);

    scanProgress[drive] = 1.0;
    notifyListeners();
  }

  /// Shared logging + autoblock
  Future<void> _finalizeScan(
    String drive,
    List<String> threats, {
    required bool quick,
  }) async {
    final threatFound = threats.isNotEmpty;

    await addLog(LogEntry(
      timestamp: DateTime.now(),
      event: quick ? 'scan_quick' : 'scan_full',
      drive: drive,
      isThreat: threatFound,
      message: threatFound
          ? ' ${threats.length} suspicious file(s) found on $drive during ${quick ? "Quick Scan" : "Full Scan"}'
          : ' ${quick ? "Quick Scan" : "Full Scan"} completed on $drive (no threats)',
    ));

    // auto-block only if real threat like autorun.inf
    final hasCritical = threats.any((f) => f.toLowerCase().endsWith("autorun.inf"));

    if (hasCritical && autoBlockOnThreat) {
      final ok = await UsbBlocker.blockAllUsbStorage();
      lastBlockSucceeded = ok;
      await addLog(LogEntry(
        timestamp: DateTime.now(),
        event: 'threat_block',
        drive: drive,
        isThreat: true,
        message: ok
            ? 'Critical threat detected! Auto-blocked USB storage'
            : 'Critical threat detected, but auto-block FAILED (need Admin)',
      ));
    }
  }

  // ----------------------------------------------------

  Future<void> clearLogs() async {
    logs.clear();
    await DBService.clearLogs();
    notifyListeners();
  }
}

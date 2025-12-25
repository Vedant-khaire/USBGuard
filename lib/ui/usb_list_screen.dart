import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/log_entry.dart';
import 'components/app_drawer.dart';
import 'home_screen.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';

class USBListScreen extends StatelessWidget {
  const USBListScreen({super.key});

  void _navigateToPage(BuildContext context, int index) {
    Widget target;
    switch (index) {
      case 0:
        target = const HomeScreen();
        break;
      case 2:
        target = const LogsScreen();
        break;
      case 3:
        target = const SettingsScreen();
        break;
      default:
        target = const USBListScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => target),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final drives = app.connectedDrives;

    return Scaffold(
      drawer: AppDrawer(
        currentIndex: 1,
        onSelectPage: (i) => _navigateToPage(context, i),
      ),
      appBar: AppBar(title: const Text("Connected USBs")),
      body: drives.isEmpty
          ? const Center(child: Text("No USB devices detected yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: drives.length,
              itemBuilder: (context, i) {
                final drive = drives[i];
                final stats = _driveStats(app.logs, drive);
                final progress = app.scanProgress[drive] ?? 0.0;

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.usb),
                          title: Text("Drive: $drive"),
                          subtitle: Text(
                            "Last seen: ${stats.lastSeen ?? '-'}\n"
                            "Last scan: ${stats.lastScanMsg ?? '-'}\n"
                            "Threats: ${stats.threats}",
                          ),
                          isThreeLine: true,
                        ),
                        const SizedBox(height: 8),

                        // Show Matrix rain + progress bar if scanning
                        if (progress > 0 && progress < 1) ...[
                          const SizedBox(
                            height: 40,
                            child: MatrixRainStrip(),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Stack(
                              children: [
                                FractionallySizedBox(
                                  widthFactor: progress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.greenAccent.shade700,
                                          Colors.greenAccent.shade400,
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.greenAccent,
                                          blurRadius: 12,
                                          spreadRadius: -2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            " Scanning $drive... ${(progress * 100).toInt()}%",
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontFamily: "monospace",
                            ),
                          ),
                        ] else
                          // Normal buttons
                          Wrap(
                            spacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.read<AppState>().scanDrive(drive);
                                },
                                icon: const Icon(Icons.bolt),
                                label: const Text("Quick Scan"),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.read<AppState>().fullScanDrive(drive);
                                },
                                icon: const Icon(Icons.shield),
                                label: const Text("Full Scan"),
                              ),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _showDetails(context, drive, stats, app),
                                icon: const Icon(Icons.info_outline),
                                label: const Text("Details"),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showDetails(
      BuildContext context, String drive, _DriveStats stats, AppState app) {
    final threats = app.threatDetails[drive] ?? [];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.black,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "USB Details — $drive",
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: "monospace",
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.green, blurRadius: 10),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _row("Last seen", stats.lastSeen ?? "-"),
              _row("Last scan", stats.lastScanMsg ?? "-"),
              _row("Total scans", "${stats.scans}"),
              _row("Threats detected", "${stats.threats}"),
              _row("Files scanned", "${app.scanProgress[drive] == 1 ? (app.threatDetails[drive]?.length ?? 0) : '-'}"),
              const Divider(color: Colors.greenAccent),
              if (threats.isNotEmpty) ...[
                const Text(
                  " Threat Files:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                    fontFamily: "monospace",
                    shadows: [Shadow(color: Colors.green, blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 8),
                for (final file in threats)
                  Text(
                    "→ $file",
                    style: TextStyle(
                      fontFamily: "monospace",
                      color: file.toLowerCase().contains("autorun.inf")
                          ? Colors.redAccent
                          : Colors.amberAccent,
                      fontSize: 14,
                      shadows: const [Shadow(color: Colors.green, blurRadius: 6)],
                    ),
                  ),
              ] else
                const Text(
                  " No threats found",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: "monospace",
                    shadows: [Shadow(color: Colors.green, blurRadius: 10)],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: Text(
                k,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.greenAccent,
                  fontFamily: "monospace",
                ),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: "monospace",
                ),
              ),
            ),
          ],
        ),
      );

  _DriveStats _driveStats(List<LogEntry> logs, String drive) {
    DateTime? lastSeen;
    String? lastScanMsg;
    int scans = 0;
    int threats = 0;

    for (final l in logs) {
      if (l.drive != drive) continue;
      if (l.event == 'arrival') {
        lastSeen = l.timestamp;
      }
      if (l.event == 'scan_quick' || l.event == 'scan_full') {
        scans++;
        lastScanMsg = l.isThreat
            ? 'Threat found'
            : (l.event == 'scan_full' ? 'Full Scan OK' : 'Quick Scan OK');
        if (l.isThreat) threats++;
      }
    }
    return _DriveStats(
      lastSeen:
          lastSeen != null ? lastSeen.toLocal().toString().split('.')[0] : null,
      lastScanMsg: lastScanMsg,
      scans: scans,
      threats: threats,
    );
  }
}

class _DriveStats {
  final String? lastSeen;
  final String? lastScanMsg;
  final int scans;
  final int threats;
  _DriveStats({
    required this.lastSeen,
    required this.lastScanMsg,
    required this.scans,
    required this.threats,
  });
}

///  Small Matrix rain strip widget
class MatrixRainStrip extends StatefulWidget {
  const MatrixRainStrip({super.key});

  @override
  State<MatrixRainStrip> createState() => _MatrixRainStripState();
}

class _MatrixRainStripState extends State<MatrixRainStrip> {
  final Random _rand = Random();
  late Timer _timer;
  List<String> _chars = [];

  @override
  void initState() {
    super.initState();
    _generate();
    _timer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      setState(_generate);
    });
  }

  void _generate() {
    const symbols = "01█▓░";
    _chars = List.generate(30, (_) => symbols[_rand.nextInt(symbols.length)]);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: _chars
          .map(
            (c) => Text(
              c,
              style: TextStyle(
                color: Colors.greenAccent.shade400,
                fontFamily: "monospace",
                fontSize: 16,
                shadows: const [
                  Shadow(color: Colors.green, blurRadius: 8),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

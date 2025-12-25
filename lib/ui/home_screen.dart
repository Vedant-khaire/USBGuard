import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'components/app_drawer.dart';
import 'package:lottie/lottie.dart';
import '../services/report_service.dart';

// Import other screens for navigation
import 'usb_list_screen.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigateToPage(BuildContext context, int index) {
    Widget target;
    switch (index) {
      case 1:
        target = const USBListScreen();
        break;
      case 2:
        target = LogsScreen();
        break;
      case 3:
        target = const SettingsScreen();
        break;
      default:
        target = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => target),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: AppDrawer(
        currentIndex: 0,
        onSelectPage: (i) => _navigateToPage(context, i),
      ),
      appBar: AppBar(
        title: const Text("Welcome Master"),
        actions: [
          IconButton(
            tooltip: app.isDarkMode ? 'Light mode' : 'Dark mode',
            onPressed: () => context.read<AppState>().toggleTheme(),
            icon: Icon(app.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
  tooltip: "Export Global Report",
  icon: const Icon(Icons.picture_as_pdf),
  onPressed: () async {
    final file = await ReportService.generateGlobalReport(app);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Global report saved at: ${file.path}")),
    );
  },
),

        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "USBGuard",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Real-Time Detection & Logging of Malicious USB Devices",
                  style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                _LottieSection(isMonitoring: app.isMonitoring),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () => app.isMonitoring
                      ? context.read<AppState>().stopMonitoring()
                      : context.read<AppState>().startMonitoring(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 40),
                    decoration: BoxDecoration(
                      color: app.isMonitoring ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: (app.isMonitoring
                                  ? Colors.redAccent
                                  : Colors.greenAccent)
                              .withOpacity(0.4),
                          blurRadius: 18,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          app.isMonitoring
                              ? Icons.stop_circle_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          app.isMonitoring
                              ? "Stop Monitoring"
                              : "Start Monitoring",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    color: app.autoScanEnabled ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    app.autoScanEnabled ? "Auto-scan: ON" : "Auto-scan: OFF",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 30),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Recent Events",
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                  ),
                ),
                const SizedBox(height: 12),

                ...app.logs.take(5).map(
                      (e) => Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Icon(
                            e.event == 'arrival'
                                ? Icons.usb
                                : e.event == 'remove'
                                    ? Icons.usb_off
                                    : e.isThreat
                                        ? Icons.warning_amber
                                        : Icons.info_outline,
                            color: e.isThreat ? Colors.red : Colors.cyan,
                          ),
                          title: Text(e.message),
                          subtitle: Text(e.timestamp
                              .toLocal()
                              .toString()
                              .split('.')[0]),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LottieSection extends StatelessWidget {
  final bool isMonitoring;
  const _LottieSection({required this.isMonitoring});

  @override
  Widget build(BuildContext context) {
    try {
      return SizedBox(
        height: 180,
        child: Lottie.asset(
          'assets/animations/usb_scan.json',
          repeat: true,
          animate: isMonitoring,
        ),
      );
    } catch (_) {
      return Container(
        height: 120,
        width: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: const Text("Animation\nplaceholder",
            textAlign: TextAlign.center),
      );
    }
  }
}

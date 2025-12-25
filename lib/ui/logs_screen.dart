import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/db_service.dart';
import '../models/log_entry.dart';
import 'components/app_drawer.dart';
import 'home_screen.dart';
import 'usb_list_screen.dart';
import 'settings_screen.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  late Future<List<LogEntry>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = DBService.fetchLogs();
  }

  Future<void> _refreshLogs() async {
    setState(() {
      _logsFuture = DBService.fetchLogs();
    });
  }

  void _navigateToPage(BuildContext context, int index) {
    Widget target;
    switch (index) {
      case 0:
        target = const HomeScreen();
        break;
      case 1:
        target = const USBListScreen();
        break;
      case 3:
        target = const SettingsScreen();
        break;
      default:
        target = const LogsScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => target),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      drawer: AppDrawer(
        currentIndex: 2,
        onSelectPage: (i) => _navigateToPage(context, i),
      ),
      appBar: AppBar(
        title: const Text("USB Logs"),
        actions: [
          IconButton(
            tooltip: "Export to TXT",
            icon: const Icon(Icons.download),
            onPressed: () async {
              final file = await DBService.exportLogsToTxt();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Logs exported to: ${file.path}")),
              );
            },
          ),
          IconButton(
            tooltip: "Clear Logs",
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              await DBService.clearLogs();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logs cleared")),
              );
              await app.clearLogs();
              _refreshLogs();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<LogEntry>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return const Center(child: Text("No logs yet"));
          }

          return RefreshIndicator(
            onRefresh: _refreshLogs,
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final message = log.message.toLowerCase();

                // Priority coloring
                Color iconColor;
                IconData icon;
                if (message.contains("autorun.inf") || message.contains("critical")) {
                  iconColor = Colors.redAccent;
                  icon = Icons.warning_amber_rounded;
                } else if (log.isThreat) {
                  iconColor = Colors.amber;
                  icon = Icons.report_problem;
                } else {
                  iconColor = Theme.of(context).colorScheme.primary;
                  icon = Icons.usb;
                }

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: Icon(icon, color: iconColor),
                    title: Text(
                      log.message,
                      style: TextStyle(
                        color: iconColor,
                        fontWeight: log.isThreat ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      "${log.event} • ${log.timestamp.toLocal().toString().split('.')[0]}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

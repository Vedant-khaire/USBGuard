import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'components/app_drawer.dart';
import 'home_screen.dart';
import 'usb_list_screen.dart';
import 'logs_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _navigateToPage(BuildContext context, int index) {
    Widget target;
    switch (index) {
      case 0:
        target = const HomeScreen();
        break;
      case 1:
        target = const USBListScreen();
        break;
      case 2:
        target = const LogsScreen();
        break;
      default:
        target = const SettingsScreen();
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
        currentIndex: 3,
        onSelectPage: (i) => _navigateToPage(context, i),
      ),
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          //  Theme Control
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: app.isDarkMode,
            onChanged: (_) => context.read<AppState>().toggleTheme(),
          ),
          const Divider(),

          //  Monitoring Features
          SwitchListTile(
            title: const Text("Auto Scan on USB Insert"),
            value: app.autoScanEnabled,
            onChanged: (_) => context.read<AppState>().toggleAutoScan(),
          ),
          //  Default scan mode selector
          if (app.autoScanEnabled)
            ListTile(
              title: const Text("Default Auto Scan Mode"),
              subtitle: const Text("Quick = faster, Full = deeper check"),
              trailing: DropdownButton<String>(
                value: app.defaultScanMode,
                items: const [
                  DropdownMenuItem(value: "quick", child: Text("Quick")),
                  DropdownMenuItem(value: "full", child: Text("Full")),
                ],
                onChanged: (v) {
                  if (v != null) {
                    context.read<AppState>().setDefaultScanMode(v);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Auto Scan Mode set to ${v.toUpperCase()}")),
                    );
                  }
                },
              ),
            ),
          SwitchListTile(
            title: const Text("Auto-block new USBs (Windows)"),
            value: app.autoBlockEnabled,
            onChanged: (v) async {
              await context.read<AppState>().setAutoBlockEnabled(v);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(v ? 'Auto-block enabled' : 'Auto-block disabled')),
                );
              }
            },
          ),
          SwitchListTile(
            title: const Text("Auto-block on Threat Detection"),
            subtitle: const Text("If malware is found, block all USB storage immediately"),
            value: app.autoBlockOnThreat,
            onChanged: (v) async {
              await context.read<AppState>().setAutoBlockOnThreat(v);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(v ? 'Auto-block on threat enabled' : 'Auto-block on threat disabled')),
                );
              }
            },
          ),

          const SizedBox(height: 12),

          //  USB Storage Control Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("USB Storage Control",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          final ok = await context.read<AppState>().blockAllNow();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ok
                                  ? 'Blocked: USBSTOR set to 4'
                                  : 'Block failed — run app as Administrator')),
                            );
                          }
                        },
                        icon: const Icon(Icons.block),
                        label: const Text("Block All USB Storage"),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final ok = await context.read<AppState>().unblockAllNow();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ok
                                  ? 'Unblocked: USBSTOR set to 3'
                                  : 'Unblock failed — run app as Administrator')),
                            );
                          }
                        },
                        icon: const Icon(Icons.lock_open),
                        label: const Text("Unblock (Restore)"),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final val = await context.read<AppState>().queryUsbStor();
                          final msg = (val == null)
                              ? 'Could not read USBSTOR (need Admin?)'
                              : 'USBSTOR Start = $val (${val == 4 ? "BLOCKED" : "UNBLOCKED/DEFAULT"})';
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                          }
                        },
                        icon: const Icon(Icons.info_outline),
                        label: const Text("Check Status"),
                      ),
                    ],
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

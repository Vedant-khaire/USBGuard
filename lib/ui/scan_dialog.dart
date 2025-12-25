import 'dart:async';
import 'package:flutter/material.dart';

class ScanDialog extends StatefulWidget {
  final String drive;
  const ScanDialog({super.key, required this.drive});

  @override
  State<ScanDialog> createState() => _ScanDialogState();
}

class _ScanDialogState extends State<ScanDialog> {
  double _progress = 0;
  String _status = "Initializing scan...";
  late Timer _timer;
  bool _done = false;
  bool _threatDetected = false;

  final List<String> _steps = [
    "Checking autorun.inf",
    "Scanning for hidden .exe files",
    "Analyzing PowerShell scripts",
    "Looking for suspicious batch files",
    "Checking metadata...",
    "Finalizing..."
  ];

  @override
  void initState() {
    super.initState();
    _startFakeScan();
  }

  void _startFakeScan() {
    int stepIndex = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_progress < 1.0) {
          _progress += 1.0 / _steps.length;
          _status = _steps[stepIndex];
          stepIndex++;
        } else {
          _done = true;
          _threatDetected = DateTime.now().second % 2 == 0; // 🔹 Random demo threat
          _status = _threatDetected ? " Threat detected!" : " No threats found";
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Scanning ${widget.drive}..."),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_done) ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 16),
            Text(_status),
          ] else ...[
            Icon(
              _threatDetected ? Icons.warning : Icons.check_circle,
              color: _threatDetected ? Colors.red : Colors.green,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(_status, style: const TextStyle(fontWeight: FontWeight.bold)),
          ]
        ],
      ),
      actions: [
        if (_done)
          TextButton(
            onPressed: () => Navigator.pop(context, _threatDetected),
            child: const Text("Close"),
          )
      ],
    );
  }
}

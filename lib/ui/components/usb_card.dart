import 'package:flutter/material.dart';

class UsbCard extends StatelessWidget {
  final String drive;
  final VoidCallback onScan;

  const UsbCard({
    super.key,
    required this.drive,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: const Icon(Icons.usb),
        ),
        title: Text("Drive $drive"),
        subtitle: const Text("Removable USB device"),
        trailing: FilledButton.icon(
          onPressed: onScan,
          icon: const Icon(Icons.search),
          label: const Text("Scan"),
        ),
      ),
    );
  }
}

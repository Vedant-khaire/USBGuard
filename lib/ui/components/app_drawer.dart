import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final void Function(int) onSelectPage;
  final int currentIndex;

  const AppDrawer({
    super.key,
    required this.onSelectPage,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: scheme.primary,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                "USBGuard",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),

          // ✅ Home
          _buildTile(
            context,
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: "Home",
            index: 0,
          ),

          // ✅ USB List
          _buildTile(
            context,
            icon: Icons.usb_outlined,
            activeIcon: Icons.usb,
            label: "USB Devices",
            index: 1,
          ),

          // ✅ Logs
          _buildTile(
            context,
            icon: Icons.list_alt_outlined,
            activeIcon: Icons.list_alt,
            label: "Logs",
            index: 2,
          ),

          // ✅ Settings
          _buildTile(
            context,
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: "Settings",
            index: 3,
          ),

          const Spacer(),

          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "© 2025 USBGuard",
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = currentIndex == index;
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        isActive ? activeIcon : icon,
        color: isActive ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? scheme.primary : scheme.onSurface,
        ),
      ),
      selected: isActive,
      onTap: () => onSelectPage(index),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'providers/app_state.dart';
import 'ui/home_screen.dart';
import 'ui/logs_screen.dart';
import 'ui/usb_list_screen.dart';
import 'ui/settings_screen.dart';
import 'utils/app_theme.dart';

void main() {
  //  Initialize SQLite for Windows/Linux
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const USBGuardApp(),
    ),
  );
}

class USBGuardApp extends StatelessWidget {
  const USBGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return MaterialApp(
      title: 'USBGuard',
      debugShowCheckedModeBanner: false,
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const _Shell(),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell({super.key});

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const USBListScreen(),
    LogsScreen(), // stateful
    const SettingsScreen(),
  ];

  //  Helper for drawer navigation
  void setPage(int i) {
    setState(() {
      _index = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(0.2, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
          return SlideTransition(position: offset, child: child);
        },
        child: _pages[_index],
      ),
    );
  }
}

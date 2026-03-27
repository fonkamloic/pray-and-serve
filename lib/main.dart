import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final storage = StorageService();
  await storage.init();
  final notifications = NotificationService();
  await notifications.init();
  runApp(PrayAndServeApp(storage: storage, notifications: notifications));
}

class PrayAndServeApp extends StatelessWidget {
  final StorageService storage;
  final NotificationService notifications;
  const PrayAndServeApp({
    super.key,
    required this.storage,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pray & Serve',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _AppShell(storage: storage, notifications: notifications),
    );
  }
}

class _AppShell extends StatefulWidget {
  final StorageService storage;
  final NotificationService notifications;
  const _AppShell({required this.storage, required this.notifications});

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> with WidgetsBindingObserver {
  bool _locked = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locked = widget.storage.getBiometricEnabled();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.storage.getBiometricEnabled()) return;
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed &&
        _backgroundedAt != null &&
        !_locked) {
      final elapsed = DateTime.now().difference(_backgroundedAt!);
      if (elapsed.inSeconds >= 60) {
        setState(() => _locked = true);
      }
      _backgroundedAt = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_locked) {
      return LockScreen(onUnlock: () => setState(() => _locked = false));
    }
    return HomeScreen(
      storage: widget.storage,
      notifications: widget.notifications,
    );
  }
}

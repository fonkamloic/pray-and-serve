import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/code_push_client.dart';

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
  Timer? _codePushTimer;
  bool _updateReady = false;
  DateTime? _lastUpdateCheck;

  static const _minCheckInterval = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locked = widget.storage.getBiometricEnabled();
    _startCodePushTimer();
    _checkForUpdate();
  }

  void _startCodePushTimer() {
    _codePushTimer = Timer.periodic(
      const Duration(hours: 4),
      (_) => _checkForUpdate(),
    );
  }

  Future<void> _checkForUpdate() async {
    if (_lastUpdateCheck != null &&
        DateTime.now().difference(_lastUpdateCheck!) < _minCheckInterval) {
      return;
    }
    _lastUpdateCheck = DateTime.now();

    final (:isUpdateAvailable, patchVersion: _) =
        await CodePush.checkForUpdate();
    if (isUpdateAvailable) {
      await CodePush.downloadAndApply();
      if (mounted) setState(() => _updateReady = true);
    }
  }

  @override
  void dispose() {
    _codePushTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdate();
    }

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
    return Stack(
      children: [
        HomeScreen(
          storage: widget.storage,
          notifications: widget.notifications,
        ),
        if (_updateReady)
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Material(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.darkTheme.colorScheme.surface,
              elevation: 4,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.system_update, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Update ready. Restart to apply.'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _updateReady = false),
                      child: const Text('LATER'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

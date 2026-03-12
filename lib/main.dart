import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
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
      home: HomeScreen(storage: storage, notifications: notifications),
    );
  }
}

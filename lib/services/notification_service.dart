import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  static const prayChannelId = 'pray_reminders';
  static const journalChannelId = 'journal_reminders';
  static const serveChannelId = 'serve_reminders';

  static const prayNotificationId = 1000;
  static const journalNotificationId = 2000;
  static const serveNotificationId = 3000;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  // --- Prayer Reminders ---

  Future<void> scheduleDailyPrayerReminder(TimeOfDay time) async {
    await _plugin.zonedSchedule(
      prayNotificationId,
      'Time to Pray',
      'Take a moment to bring your prayers before God.',
      nextInstanceOfTime(time),
      NotificationDetails(
        android: AndroidNotificationDetails(
          prayChannelId,
          'Prayer Reminders',
          channelDescription: 'Daily reminders to pray',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelPrayerReminder() async {
    await _plugin.cancel(prayNotificationId);
  }

  // --- Journal Reminders ---

  Future<void> scheduleJournalReminder(TimeOfDay time) async {
    await _plugin.zonedSchedule(
      journalNotificationId,
      'Time to Reflect',
      'Write in your prayer journal today.',
      nextInstanceOfTime(time),
      NotificationDetails(
        android: AndroidNotificationDetails(
          journalChannelId,
          'Journal Reminders',
          channelDescription: 'Daily reminders to journal',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelJournalReminder() async {
    await _plugin.cancel(journalNotificationId);
  }

  // --- Serve Reminders ---

  Future<void> scheduleServeCheckReminder(TimeOfDay time) async {
    await _plugin.zonedSchedule(
      serveNotificationId,
      'Check on Your Flock',
      'You may have people who need your care today.',
      nextInstanceOfTime(time),
      NotificationDetails(
        android: AndroidNotificationDetails(
          serveChannelId,
          'Serve Reminders',
          channelDescription: 'Daily reminders to check on your flock',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelServeReminder() async {
    await _plugin.cancel(serveNotificationId);
  }

  // --- Utility ---

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  @visibleForTesting
  tz.TZDateTime nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

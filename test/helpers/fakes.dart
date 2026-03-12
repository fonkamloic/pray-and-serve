import 'package:flutter/material.dart';
import 'package:pray_and_serve/services/notification_service.dart';

/// A fake notification service that records all method calls for verification
/// in tests, without depending on any real plugin or platform channel.
class FakeNotificationService extends NotificationService {
  bool initCalled = false;
  bool requestPermissionCalled = false;
  bool cancelAllCalled = false;

  final List<TimeOfDay> scheduledPrayerTimes = [];
  final List<TimeOfDay> scheduledJournalTimes = [];
  final List<TimeOfDay> scheduledServeTimes = [];

  int cancelPrayerReminderCount = 0;
  int cancelJournalReminderCount = 0;
  int cancelServeReminderCount = 0;

  final List<int> scheduledIds = [];
  final List<int> cancelledIds = [];

  static const prayNotificationId = 1000;
  static const journalNotificationId = 2000;
  static const serveNotificationId = 3000;

  @override
  Future<void> init() async {
    initCalled = true;
  }

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalled = true;
    return true;
  }

  @override
  Future<void> scheduleDailyPrayerReminder(TimeOfDay time) async {
    scheduledPrayerTimes.add(time);
    scheduledIds.add(prayNotificationId);
  }

  @override
  Future<void> cancelPrayerReminder() async {
    cancelPrayerReminderCount++;
    cancelledIds.add(prayNotificationId);
  }

  @override
  Future<void> scheduleJournalReminder(TimeOfDay time) async {
    scheduledJournalTimes.add(time);
    scheduledIds.add(journalNotificationId);
  }

  @override
  Future<void> cancelJournalReminder() async {
    cancelJournalReminderCount++;
    cancelledIds.add(journalNotificationId);
  }

  @override
  Future<void> scheduleServeCheckReminder(TimeOfDay time) async {
    scheduledServeTimes.add(time);
    scheduledIds.add(serveNotificationId);
  }

  @override
  Future<void> cancelServeReminder() async {
    cancelServeReminderCount++;
    cancelledIds.add(serveNotificationId);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalled = true;
    cancelledIds.addAll([
      prayNotificationId,
      journalNotificationId,
      serveNotificationId,
    ]);
  }

  void reset() {
    initCalled = false;
    requestPermissionCalled = false;
    cancelAllCalled = false;
    scheduledPrayerTimes.clear();
    scheduledJournalTimes.clear();
    scheduledServeTimes.clear();
    cancelPrayerReminderCount = 0;
    cancelJournalReminderCount = 0;
    cancelServeReminderCount = 0;
    scheduledIds.clear();
    cancelledIds.clear();
  }
}

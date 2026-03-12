import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:pray_and_serve/services/notification_service.dart';
import '../helpers/fakes.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Construction
  // ---------------------------------------------------------------------------
  group('Construction', () {
    test('creates with default plugin (no arguments)', () {
      final service = NotificationService();
      expect(service, isNotNull);
    });

    test('creates with a custom plugin instance', () {
      final plugin = FlutterLocalNotificationsPlugin();
      final service = NotificationService(plugin: plugin);
      expect(service, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------
  group('Constants', () {
    test('channel IDs are distinct', () {
      expect(NotificationService.prayChannelId, 'pray_reminders');
      expect(NotificationService.journalChannelId, 'journal_reminders');
      expect(NotificationService.serveChannelId, 'serve_reminders');

      // Ensure they are all different from each other.
      final ids = {
        NotificationService.prayChannelId,
        NotificationService.journalChannelId,
        NotificationService.serveChannelId,
      };
      expect(ids, hasLength(3));
    });

    test('notification IDs are distinct', () {
      expect(NotificationService.prayNotificationId, 1000);
      expect(NotificationService.journalNotificationId, 2000);
      expect(NotificationService.serveNotificationId, 3000);

      final ids = {
        NotificationService.prayNotificationId,
        NotificationService.journalNotificationId,
        NotificationService.serveNotificationId,
      };
      expect(ids, hasLength(3));
    });
  });

  // ---------------------------------------------------------------------------
  // Public API contract (exercised via FakeNotificationService)
  // ---------------------------------------------------------------------------
  group('FakeNotificationService behaviour', () {
    late FakeNotificationService fake;

    setUp(() {
      fake = FakeNotificationService();
    });

    test('init sets flag', () async {
      await fake.init();
      expect(fake.initCalled, true);
    });

    test('requestPermission returns true', () async {
      final result = await fake.requestPermission();
      expect(result, true);
      expect(fake.requestPermissionCalled, true);
    });

    test('scheduleDailyPrayerReminder records the time and ID', () async {
      const time = TimeOfDay(hour: 7, minute: 0);
      await fake.scheduleDailyPrayerReminder(time);
      expect(fake.scheduledPrayerTimes, [time]);
      expect(fake.scheduledIds, [FakeNotificationService.prayNotificationId]);
    });

    test('cancelPrayerReminder increments counter and records ID', () async {
      await fake.cancelPrayerReminder();
      expect(fake.cancelPrayerReminderCount, 1);
      expect(
          fake.cancelledIds, [FakeNotificationService.prayNotificationId]);
    });

    test('scheduleJournalReminder records the time and ID', () async {
      const time = TimeOfDay(hour: 20, minute: 0);
      await fake.scheduleJournalReminder(time);
      expect(fake.scheduledJournalTimes, [time]);
      expect(fake.scheduledIds,
          [FakeNotificationService.journalNotificationId]);
    });

    test('cancelJournalReminder increments counter and records ID', () async {
      await fake.cancelJournalReminder();
      expect(fake.cancelJournalReminderCount, 1);
      expect(fake.cancelledIds,
          [FakeNotificationService.journalNotificationId]);
    });

    test('scheduleServeCheckReminder records the time and ID', () async {
      const time = TimeOfDay(hour: 9, minute: 0);
      await fake.scheduleServeCheckReminder(time);
      expect(fake.scheduledServeTimes, [time]);
      expect(
          fake.scheduledIds, [FakeNotificationService.serveNotificationId]);
    });

    test('cancelServeReminder increments counter and records ID', () async {
      await fake.cancelServeReminder();
      expect(fake.cancelServeReminderCount, 1);
      expect(
          fake.cancelledIds, [FakeNotificationService.serveNotificationId]);
    });

    test('cancelAll records all three IDs', () async {
      await fake.cancelAll();
      expect(fake.cancelAllCalled, true);
      expect(fake.cancelledIds, [
        FakeNotificationService.prayNotificationId,
        FakeNotificationService.journalNotificationId,
        FakeNotificationService.serveNotificationId,
      ]);
    });

    test('reset clears all tracking state', () async {
      await fake.init();
      await fake.requestPermission();
      await fake.scheduleDailyPrayerReminder(
          const TimeOfDay(hour: 7, minute: 0));
      await fake.cancelPrayerReminder();
      await fake.cancelAll();

      fake.reset();

      expect(fake.initCalled, false);
      expect(fake.requestPermissionCalled, false);
      expect(fake.cancelAllCalled, false);
      expect(fake.scheduledPrayerTimes, isEmpty);
      expect(fake.scheduledJournalTimes, isEmpty);
      expect(fake.scheduledServeTimes, isEmpty);
      expect(fake.cancelPrayerReminderCount, 0);
      expect(fake.cancelJournalReminderCount, 0);
      expect(fake.cancelServeReminderCount, 0);
      expect(fake.scheduledIds, isEmpty);
      expect(fake.cancelledIds, isEmpty);
    });

    test('multiple schedule calls accumulate', () async {
      const morningPrayer = TimeOfDay(hour: 6, minute: 0);
      const eveningPrayer = TimeOfDay(hour: 21, minute: 0);

      await fake.scheduleDailyPrayerReminder(morningPrayer);
      await fake.scheduleDailyPrayerReminder(eveningPrayer);

      expect(fake.scheduledPrayerTimes, [morningPrayer, eveningPrayer]);
      expect(fake.scheduledIds, [
        FakeNotificationService.prayNotificationId,
        FakeNotificationService.prayNotificationId,
      ]);
    });
  });

  // ---------------------------------------------------------------------------
  // nextInstanceOfTime (real logic)
  // ---------------------------------------------------------------------------
  group('nextInstanceOfTime', () {
    late NotificationService service;

    setUpAll(() {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/New_York'));
    });

    setUp(() {
      service = NotificationService(
          plugin: FlutterLocalNotificationsPlugin());
    });

    test('returns today if the time has not yet passed', () {
      final now = tz.TZDateTime.now(tz.local);
      // Schedule 23:59 — almost certainly in the future
      const time = TimeOfDay(hour: 23, minute: 59);
      final result = service.nextInstanceOfTime(time);

      expect(result.hour, 23);
      expect(result.minute, 59);
      // Should be today or tomorrow (if test runs at 23:59)
      expect(
        result.isAfter(now) || result.isAtSameMomentAs(now),
        isTrue,
      );
    });

    test('returns tomorrow if the time has already passed', () {
      // Schedule 00:00 — almost certainly in the past (unless test runs at midnight)
      const time = TimeOfDay(hour: 0, minute: 0);
      final now = tz.TZDateTime.now(tz.local);
      final result = service.nextInstanceOfTime(time);

      if (now.hour > 0 || now.minute > 0) {
        // Should be tomorrow
        expect(result.day, now.day + 1);
      }
      expect(result.hour, 0);
      expect(result.minute, 0);
    });

    test('returns a TZDateTime in the local timezone', () {
      const time = TimeOfDay(hour: 12, minute: 30);
      final result = service.nextInstanceOfTime(time);

      expect(result.location, tz.local);
      expect(result.hour, 12);
      expect(result.minute, 30);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pray_and_serve/services/storage_service.dart';
import 'package:pray_and_serve/models/prayer.dart';
import 'package:pray_and_serve/models/journal_entry.dart';
import 'package:pray_and_serve/models/person.dart';
import 'package:pray_and_serve/models/care_log.dart';

void main() {
  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.init();
  });

  // ---------------------------------------------------------------------------
  // Role
  // ---------------------------------------------------------------------------
  group('Role', () {
    test('default is Member', () {
      expect(storage.getRole(), 'Member');
    });

    test('setRole persists value', () async {
      await storage.setRole('Pastor');
      expect(storage.getRole(), 'Pastor');
    });

    test('setRole overwrites previous value', () async {
      await storage.setRole('Elder');
      await storage.setRole('Deacon');
      expect(storage.getRole(), 'Deacon');
    });
  });

  // ---------------------------------------------------------------------------
  // Reminder Days
  // ---------------------------------------------------------------------------
  group('Reminder Days', () {
    test('default is 14', () {
      expect(storage.getReminderDays(), 14);
    });

    test('setReminderDays persists value', () async {
      await storage.setReminderDays(7);
      expect(storage.getReminderDays(), 7);
    });

    test('setReminderDays overwrites previous value', () async {
      await storage.setReminderDays(7);
      await storage.setReminderDays(30);
      expect(storage.getReminderDays(), 30);
    });
  });

  // ---------------------------------------------------------------------------
  // Prayers
  // ---------------------------------------------------------------------------
  group('Prayers', () {
    final prayer1 = Prayer(id: '1', title: 'Test', createdAt: '2024-01-01');
    final prayer2 = Prayer(id: '2', title: 'Healing', createdAt: '2024-02-01');

    test('default is empty list', () {
      expect(storage.getPrayers(), isEmpty);
    });

    test('save then get round-trips a single prayer', () async {
      await storage.savePrayers([prayer1]);
      final result = storage.getPrayers();
      expect(result, hasLength(1));
      expect(result.first.id, '1');
      expect(result.first.title, 'Test');
      expect(result.first.createdAt, '2024-01-01');
    });

    test('save then get round-trips multiple prayers', () async {
      await storage.savePrayers([prayer1, prayer2]);
      final result = storage.getPrayers();
      expect(result, hasLength(2));
      expect(result[0].id, '1');
      expect(result[1].id, '2');
    });

    test('saving overwrites previous list', () async {
      await storage.savePrayers([prayer1, prayer2]);
      await storage.savePrayers([prayer2]);
      final result = storage.getPrayers();
      expect(result, hasLength(1));
      expect(result.first.id, '2');
    });
  });

  // ---------------------------------------------------------------------------
  // Journal
  // ---------------------------------------------------------------------------
  group('Journal', () {
    final entry1 =
        JournalEntry(id: '1', date: '2024-01-01', body: 'Test');
    final entry2 =
        JournalEntry(id: '2', date: '2024-02-01', body: 'Reflection');

    test('default is empty list', () {
      expect(storage.getJournal(), isEmpty);
    });

    test('save then get round-trips a single entry', () async {
      await storage.saveJournal([entry1]);
      final result = storage.getJournal();
      expect(result, hasLength(1));
      expect(result.first.id, '1');
      expect(result.first.body, 'Test');
    });

    test('save then get round-trips multiple entries', () async {
      await storage.saveJournal([entry1, entry2]);
      final result = storage.getJournal();
      expect(result, hasLength(2));
      expect(result[1].body, 'Reflection');
    });

    test('saving overwrites previous list', () async {
      await storage.saveJournal([entry1, entry2]);
      await storage.saveJournal([entry2]);
      final result = storage.getJournal();
      expect(result, hasLength(1));
      expect(result.first.id, '2');
    });
  });

  // ---------------------------------------------------------------------------
  // Flock (Person)
  // ---------------------------------------------------------------------------
  group('Flock', () {
    final person1 = Person(id: '1', name: 'John');
    final person2 = Person(id: '2', name: 'Jane');

    test('default is empty list', () {
      expect(storage.getFlock(), isEmpty);
    });

    test('save then get round-trips a single person', () async {
      await storage.saveFlock([person1]);
      final result = storage.getFlock();
      expect(result, hasLength(1));
      expect(result.first.id, '1');
      expect(result.first.name, 'John');
    });

    test('save then get round-trips multiple people', () async {
      await storage.saveFlock([person1, person2]);
      final result = storage.getFlock();
      expect(result, hasLength(2));
      expect(result[1].name, 'Jane');
    });

    test('saving overwrites previous list', () async {
      await storage.saveFlock([person1, person2]);
      await storage.saveFlock([person1]);
      final result = storage.getFlock();
      expect(result, hasLength(1));
      expect(result.first.name, 'John');
    });
  });

  // ---------------------------------------------------------------------------
  // Care Logs
  // ---------------------------------------------------------------------------
  group('Care Logs', () {
    final log1 = CareLog(id: '1', personId: '1', date: '2024-01-01');
    final log2 = CareLog(id: '2', personId: '1', date: '2024-02-01');

    test('default is empty list', () {
      expect(storage.getCareLogs(), isEmpty);
    });

    test('save then get round-trips a single log', () async {
      await storage.saveCareLogs([log1]);
      final result = storage.getCareLogs();
      expect(result, hasLength(1));
      expect(result.first.id, '1');
      expect(result.first.personId, '1');
      expect(result.first.date, '2024-01-01');
    });

    test('save then get round-trips multiple logs', () async {
      await storage.saveCareLogs([log1, log2]);
      final result = storage.getCareLogs();
      expect(result, hasLength(2));
      expect(result[1].date, '2024-02-01');
    });

    test('saving overwrites previous list', () async {
      await storage.saveCareLogs([log1, log2]);
      await storage.saveCareLogs([log2]);
      final result = storage.getCareLogs();
      expect(result, hasLength(1));
      expect(result.first.id, '2');
    });
  });

  // ---------------------------------------------------------------------------
  // Prayer Reminder Preferences
  // ---------------------------------------------------------------------------
  group('Prayer Reminder Preferences', () {
    test('enabled defaults to false', () {
      expect(storage.getPrayReminderEnabled(), false);
    });

    test('hour defaults to 7', () {
      expect(storage.getPrayReminderHour(), 7);
    });

    test('minute defaults to 0', () {
      expect(storage.getPrayReminderMinute(), 0);
    });

    test('setPrayReminderEnabled persists true', () async {
      await storage.setPrayReminderEnabled(true);
      expect(storage.getPrayReminderEnabled(), true);
    });

    test('setPrayReminderTime persists hour and minute', () async {
      await storage.setPrayReminderTime(8, 30);
      expect(storage.getPrayReminderHour(), 8);
      expect(storage.getPrayReminderMinute(), 30);
    });

    test('setPrayReminderTime overwrites previous value', () async {
      await storage.setPrayReminderTime(6, 15);
      await storage.setPrayReminderTime(12, 45);
      expect(storage.getPrayReminderHour(), 12);
      expect(storage.getPrayReminderMinute(), 45);
    });
  });

  // ---------------------------------------------------------------------------
  // Journal Reminder Preferences
  // ---------------------------------------------------------------------------
  group('Journal Reminder Preferences', () {
    test('enabled defaults to false', () {
      expect(storage.getJournalReminderEnabled(), false);
    });

    test('hour defaults to 20', () {
      expect(storage.getJournalReminderHour(), 20);
    });

    test('minute defaults to 0', () {
      expect(storage.getJournalReminderMinute(), 0);
    });

    test('setJournalReminderEnabled persists true', () async {
      await storage.setJournalReminderEnabled(true);
      expect(storage.getJournalReminderEnabled(), true);
    });

    test('setJournalReminderTime persists hour and minute', () async {
      await storage.setJournalReminderTime(21, 15);
      expect(storage.getJournalReminderHour(), 21);
      expect(storage.getJournalReminderMinute(), 15);
    });

    test('setJournalReminderTime overwrites previous value', () async {
      await storage.setJournalReminderTime(19, 0);
      await storage.setJournalReminderTime(22, 30);
      expect(storage.getJournalReminderHour(), 22);
      expect(storage.getJournalReminderMinute(), 30);
    });
  });

  // ---------------------------------------------------------------------------
  // Serve Reminder Preferences
  // ---------------------------------------------------------------------------
  group('Serve Reminder Preferences', () {
    test('enabled defaults to false', () {
      expect(storage.getServeReminderEnabled(), false);
    });

    test('hour defaults to 9', () {
      expect(storage.getServeReminderHour(), 9);
    });

    test('minute defaults to 0', () {
      expect(storage.getServeReminderMinute(), 0);
    });

    test('setServeReminderEnabled persists true', () async {
      await storage.setServeReminderEnabled(true);
      expect(storage.getServeReminderEnabled(), true);
    });

    test('setServeReminderTime persists hour and minute', () async {
      await storage.setServeReminderTime(10, 30);
      expect(storage.getServeReminderHour(), 10);
      expect(storage.getServeReminderMinute(), 30);
    });

    test('setServeReminderTime overwrites previous value', () async {
      await storage.setServeReminderTime(8, 0);
      await storage.setServeReminderTime(11, 45);
      expect(storage.getServeReminderHour(), 11);
      expect(storage.getServeReminderMinute(), 45);
    });
  });
}

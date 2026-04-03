import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/prayer.dart';
import '../models/journal_entry.dart';
import '../models/person.dart';
import '../models/care_log.dart';
import '../models/paired_device.dart';
import '../models/serve_group.dart';

class StorageService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Ensure a stable device ID exists from first launch onwards.
    if (_prefs.getString('ps-device-id') == null) {
      await _prefs.setString('ps-device-id', const Uuid().v4());
    }
  }

  // Device identity
  String getDeviceId() => _prefs.getString('ps-device-id')!;

  // Paired devices
  List<PairedDevice> getPairedDevices() {
    final raw = _prefs.getString('ps-paired-devices');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => PairedDevice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePairedDevices(List<PairedDevice> devices) =>
      _prefs.setString('ps-paired-devices',
          jsonEncode(devices.map((e) => e.toJson()).toList()));

  // Role
  String getRole() => _prefs.getString('ps-role') ?? 'Member';
  Future<void> setRole(String role) => _prefs.setString('ps-role', role);

  // Biometric lock
  bool getBiometricEnabled() => _prefs.getBool('ps-biometric-enabled') ?? false;
  Future<void> setBiometricEnabled(bool v) =>
      _prefs.setBool('ps-biometric-enabled', v);

  // Reminder days
  int getReminderDays() => _prefs.getInt('ps-reminderdays') ?? 14;
  Future<void> setReminderDays(int days) =>
      _prefs.setInt('ps-reminderdays', days);

  // Prayers
  List<Prayer> getPrayers() {
    final raw = _prefs.getString('ps-prayers');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Prayer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> savePrayers(List<Prayer> prayers) =>
      _prefs.setString('ps-prayers',
          jsonEncode(prayers.map((e) => e.toJson()).toList()));

  // Journal
  List<JournalEntry> getJournal() {
    final raw = _prefs.getString('ps-journal');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveJournal(List<JournalEntry> entries) =>
      _prefs.setString('ps-journal',
          jsonEncode(entries.map((e) => e.toJson()).toList()));

  // Flock (people)
  List<Person> getFlock() {
    final raw = _prefs.getString('ps-flock');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Person.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveFlock(List<Person> people) =>
      _prefs.setString(
          'ps-flock', jsonEncode(people.map((e) => e.toJson()).toList()));

  // Care logs
  List<CareLog> getCareLogs() {
    final raw = _prefs.getString('ps-carelogs');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => CareLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCareLogs(List<CareLog> logs) =>
      _prefs.setString(
          'ps-carelogs', jsonEncode(logs.map((e) => e.toJson()).toList()));

  // Serve groups
  List<ServeGroup> getServeGroups() {
    final raw = _prefs.getString('ps-serve-groups');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ServeGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveServeGroups(List<ServeGroup> groups) =>
      _prefs.setString(
          'ps-serve-groups', jsonEncode(groups.map((e) => e.toJson()).toList()));

  // Notification preferences — Prayer
  bool getPrayReminderEnabled() =>
      _prefs.getBool('ps-pray-reminder-enabled') ?? false;
  Future<void> setPrayReminderEnabled(bool v) =>
      _prefs.setBool('ps-pray-reminder-enabled', v);
  int getPrayReminderHour() => _prefs.getInt('ps-pray-reminder-hour') ?? 7;
  int getPrayReminderMinute() =>
      _prefs.getInt('ps-pray-reminder-minute') ?? 0;
  Future<void> setPrayReminderTime(int hour, int minute) async {
    await _prefs.setInt('ps-pray-reminder-hour', hour);
    await _prefs.setInt('ps-pray-reminder-minute', minute);
  }

  // Notification preferences — Journal
  bool getJournalReminderEnabled() =>
      _prefs.getBool('ps-journal-reminder-enabled') ?? false;
  Future<void> setJournalReminderEnabled(bool v) =>
      _prefs.setBool('ps-journal-reminder-enabled', v);
  int getJournalReminderHour() =>
      _prefs.getInt('ps-journal-reminder-hour') ?? 20;
  int getJournalReminderMinute() =>
      _prefs.getInt('ps-journal-reminder-minute') ?? 0;
  Future<void> setJournalReminderTime(int hour, int minute) async {
    await _prefs.setInt('ps-journal-reminder-hour', hour);
    await _prefs.setInt('ps-journal-reminder-minute', minute);
  }

  // Notification preferences — Serve
  bool getServeReminderEnabled() =>
      _prefs.getBool('ps-serve-reminder-enabled') ?? false;
  Future<void> setServeReminderEnabled(bool v) =>
      _prefs.setBool('ps-serve-reminder-enabled', v);
  int getServeReminderHour() => _prefs.getInt('ps-serve-reminder-hour') ?? 9;
  int getServeReminderMinute() =>
      _prefs.getInt('ps-serve-reminder-minute') ?? 0;
  Future<void> setServeReminderTime(int hour, int minute) async {
    await _prefs.setInt('ps-serve-reminder-hour', hour);
    await _prefs.setInt('ps-serve-reminder-minute', minute);
  }
}

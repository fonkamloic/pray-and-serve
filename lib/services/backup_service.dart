import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/prayer.dart';
import '../models/journal_entry.dart';
import '../models/person.dart';
import '../models/care_log.dart';
import 'storage_service.dart';

class BackupService {
  final StorageService storage;
  BackupService(this.storage);

  /// Returns a JSON-serialisable map of all user data (no credentials).
  Map<String, dynamic> buildBackupData() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return {
      'version': 1,
      'app': 'pray-and-serve',
      'exportedAt': today,
      'prayers': storage.getPrayers().map((e) => e.toJson()).toList(),
      'journal': storage.getJournal().map((e) => e.toJson()).toList(),
      'flock': storage.getFlock().map((e) => e.toJson()).toList(),
      'careLogs': storage.getCareLogs().map((e) => e.toJson()).toList(),
      'role': storage.getRole(),
      'reminderDays': storage.getReminderDays(),
    };
  }

  /// Additive-only merge: adds items whose IDs are not yet present locally.
  /// Never deletes or overwrites existing records.
  /// Returns the total count of newly added items across all collections.
  Future<int> mergeFromData(Map<String, dynamic> data) async {
    if (data['app'] != 'pray-and-serve') return 0;
    int added = 0;

    // Prayers
    final existingPrayers = storage.getPrayers();
    final existingPrayerIds = existingPrayers.map((p) => p.id).toSet();
    final newPrayers = (data['prayers'] as List? ?? [])
        .map((e) => Prayer.fromJson(e as Map<String, dynamic>))
        .where((p) => !existingPrayerIds.contains(p.id))
        .toList();
    if (newPrayers.isNotEmpty) {
      await storage.savePrayers([...existingPrayers, ...newPrayers]);
      added += newPrayers.length;
    }

    // Journal
    final existingJournal = storage.getJournal();
    final existingJournalIds = existingJournal.map((j) => j.id).toSet();
    final newJournal = (data['journal'] as List? ?? [])
        .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
        .where((j) => !existingJournalIds.contains(j.id))
        .toList();
    if (newJournal.isNotEmpty) {
      await storage.saveJournal([...existingJournal, ...newJournal]);
      added += newJournal.length;
    }

    // Flock
    final existingFlock = storage.getFlock();
    final existingFlockIds = existingFlock.map((p) => p.id).toSet();
    final newFlock = (data['flock'] as List? ?? [])
        .map((e) => Person.fromJson(e as Map<String, dynamic>))
        .where((p) => !existingFlockIds.contains(p.id))
        .toList();
    if (newFlock.isNotEmpty) {
      await storage.saveFlock([...existingFlock, ...newFlock]);
      added += newFlock.length;
    }

    // Care logs
    final existingCareLogs = storage.getCareLogs();
    final existingCareLogIds = existingCareLogs.map((c) => c.id).toSet();
    final newCareLogs = (data['careLogs'] as List? ?? [])
        .map((e) => CareLog.fromJson(e as Map<String, dynamic>))
        .where((c) => !existingCareLogIds.contains(c.id))
        .toList();
    if (newCareLogs.isNotEmpty) {
      await storage.saveCareLogs([...existingCareLogs, ...newCareLogs]);
      added += newCareLogs.length;
    }

    return added;
  }

  Future<void> exportBackup({Rect? shareOrigin}) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final json = const JsonEncoder.withIndent('  ').convert(buildBackupData());
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/pray_and_serve_backup_$today.json');
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Pray & Serve Backup – $today',
      sharePositionOrigin: shareOrigin,
    );
  }

  /// Returns null on success, or an error message string on failure.
  /// Full replace (not merge) — called from the manual import flow.
  Future<String?> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return null;

    try {
      final content = await File(result.files.single.path!).readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      if (data['app'] != 'pray-and-serve') {
        return 'This file is not a Pray & Serve backup.';
      }

      final prayers = (data['prayers'] as List)
          .map((e) => Prayer.fromJson(e as Map<String, dynamic>))
          .toList();
      final journal = (data['journal'] as List)
          .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      final flock = (data['flock'] as List)
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .toList();
      final careLogs = (data['careLogs'] as List)
          .map((e) => CareLog.fromJson(e as Map<String, dynamic>))
          .toList();

      await storage.savePrayers(prayers);
      await storage.saveJournal(journal);
      await storage.saveFlock(flock);
      await storage.saveCareLogs(careLogs);
      if (data['role'] != null) await storage.setRole(data['role'] as String);
      if (data['reminderDays'] != null) {
        await storage.setReminderDays(data['reminderDays'] as int);
      }

      return null;
    } catch (_) {
      return 'Could not read backup file. It may be corrupted.';
    }
  }
}

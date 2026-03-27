import 'dart:convert';
import 'dart:io';
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

  Future<void> exportBackup() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final data = {
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

    final json = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pray_and_serve_backup_$today.json');
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Pray & Serve Backup – $today',
    );
  }

  /// Returns null on success, or an error message string on failure.
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

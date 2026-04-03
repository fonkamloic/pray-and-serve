import 'dart:async';

import 'package:flutter/services.dart';

const _channel = MethodChannel('flutter/codepush');

class UpdateInfo {
  const UpdateInfo({required this.isUpdateAvailable, this.patchVersion});
  final bool isUpdateAvailable;
  final String? patchVersion;
}

class PatchInfo {
  const PatchInfo({required this.version, required this.installedAt});
  final String version;
  final DateTime installedAt;
}

class CodePushException implements Exception {
  CodePushException(this.message);
  final String message;
  @override
  String toString() => 'CodePushException: $message';
}

class CodePush {
  static Future<UpdateInfo> checkForUpdate() async {
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('CodePush.checkForUpdate');
      if (result == null) {
        throw CodePushException('No response from engine.');
      }
      return UpdateInfo(
        isUpdateAvailable: result['isUpdateAvailable'] == true,
        patchVersion: result['patchVersion']?.toString(),
      );
    } on CodePushException {
      rethrow;
    } on Exception catch (e) {
      throw CodePushException('Update check failed: $e');
    }
  }

  static Future<void> downloadAndApply() async {
    try {
      final success =
          await _channel.invokeMethod<bool>('CodePush.downloadAndApply');
      if (success != true) {
        throw CodePushException('Failed to download and apply patch.');
      }
    } on CodePushException {
      rethrow;
    } on Exception catch (e) {
      throw CodePushException('Download failed: $e');
    }
  }

  static Future<PatchInfo?> get currentPatch async {
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('CodePush.getCurrentPatch');
      if (result == null) return null;
      return PatchInfo(
        version: result['version'] as String,
        installedAt: DateTime.fromMillisecondsSinceEpoch(
          result['installedAt'] as int,
        ),
      );
    } on Exception {
      return null;
    }
  }

  static Future<bool> get isPatched async {
    try {
      return await _channel.invokeMethod<bool>('CodePush.isPatched') ?? false;
    } on Exception {
      return false;
    }
  }

  static Future<void> rollback() async {
    try {
      final success = await _channel.invokeMethod<bool>('CodePush.rollback');
      if (success != true) {
        throw CodePushException('Failed to roll back patch.');
      }
    } on CodePushException {
      rethrow;
    } on Exception catch (e) {
      throw CodePushException('Rollback failed: $e');
    }
  }
}

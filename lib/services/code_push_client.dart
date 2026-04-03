import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('flutter/codepush');

class CodePush {
  static Future<({bool isUpdateAvailable, String? patchVersion})>
      checkForUpdate() async {
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('CodePush.checkForUpdate');
      return (
        isUpdateAvailable: result?['isUpdateAvailable'] as bool? ?? false,
        patchVersion: result?['patchVersion'] as String?,
      );
    } on Exception catch (e) {
      debugPrint('CodePush.checkForUpdate failed: $e');
      return (isUpdateAvailable: false, patchVersion: null);
    }
  }

  static Future<void> downloadAndApply() async {
    try {
      await _channel.invokeMethod<bool>('CodePush.downloadAndApply');
    } on Exception catch (e) {
      debugPrint('CodePush.downloadAndApply failed: $e');
    }
  }

  static Future<String?> get currentPatchVersion async {
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('CodePush.getCurrentPatch');
      return result?['version'] as String?;
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
      await _channel.invokeMethod<bool>('CodePush.rollback');
    } on Exception catch (e) {
      debugPrint('CodePush.rollback failed: $e');
    }
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

const _channel = MethodChannel('flutter/codepush');

const _serverUrl = 'https://api.codepush.flutterplaza.com';
const _appId = '2ca7dd88-547b-4281-9484-91501e596aa6'; // iOS app
const _releaseVersion = '1.2.0+7';

class CodePush {
  /// Checks the server for a new patch and installs it if available.
  /// Returns true if a patch was downloaded and installed.
  static Future<bool> checkAndInstall() async {
    try {
      final uri = Uri.parse(
        '$_serverUrl/api/v1/updates'
        '?app_id=$_appId'
        '&version=${Uri.encodeComponent(_releaseVersion)}'
        '&platform=ios'
        '&channel=production',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 204) return false; // No update.
      if (resp.statusCode != 200) return false;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['patch_available'] != true) return false;

      final patchUrl = data['patch_url'] as String?;
      if (patchUrl == null || patchUrl.isEmpty) return false;

      // Download the patch.
      debugPrint('CodePush: downloading patch from $patchUrl');
      final patchResp =
          await http.get(Uri.parse(patchUrl)).timeout(const Duration(seconds: 60));
      if (patchResp.statusCode != 200) return false;

      // Install via engine.
      final base64Data = base64Encode(patchResp.bodyBytes);
      final success = await _channel.invokeMethod<bool>(
        'CodePush.installPatch',
        [base64Data],
      );
      debugPrint('CodePush: installPatch result=$success');
      return success == true;
    } catch (e) {
      debugPrint('CodePush: checkAndInstall failed: $e');
      return false;
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
    } catch (_) {
      return null;
    }
  }

  static Future<bool> get isPatched async {
    try {
      return await _channel.invokeMethod<bool>('CodePush.isPatched') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> rollback() async {
    try {
      await _channel.invokeMethod<bool>('CodePush.rollback');
    } catch (e) {
      debugPrint('CodePush: rollback failed: $e');
    }
  }
}

class PatchInfo {
  const PatchInfo({required this.version, required this.installedAt});
  final String version;
  final DateTime installedAt;
}

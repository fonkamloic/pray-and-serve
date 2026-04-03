import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

const _channel = MethodChannel('flutter/codepush');

const _serverUrl = 'https://api.codepush.flutterplaza.com';
const _appId = '2ca7dd88-547b-4281-9484-91501e596aa6'; // iOS app
const _releaseVersion = '1.2.0+10';

class CodePush {
  /// Checks the server for a new patch and installs it if available.
  /// Returns true if a patch was downloaded and installed.
  static Future<bool> checkAndInstall() async {
    final (result, _) = await checkAndInstallDebug();
    return result;
  }

  /// Same as checkAndInstall but returns a debug status string.
  static Future<(bool, String)> checkAndInstallDebug() async {
    try {
      final uri = Uri.parse(
        '$_serverUrl/api/v1/updates'
        '?app_id=$_appId'
        '&version=${Uri.encodeComponent(_releaseVersion)}'
        '&platform=ios'
        '&channel=production',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 204) return (false, 'No update (204)');
      if (resp.statusCode != 200) return (false, 'Server ${resp.statusCode}');

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['patch_available'] != true) return (false, 'No patch available');

      final patchUrl = data['patch_url'] as String?;
      if (patchUrl == null || patchUrl.isEmpty) return (false, 'No patch URL');

      // Download the patch.
      final patchResp =
          await http.get(Uri.parse(patchUrl)).timeout(const Duration(seconds: 60));
      if (patchResp.statusCode != 200) {
        return (false, 'Download failed: ${patchResp.statusCode}');
      }

      // Install via engine.
      final base64Data = base64Encode(patchResp.bodyBytes);
      final success = await _channel.invokeMethod<bool>(
        'CodePush.installPatch',
        [base64Data],
      );
      if (success == true) {
        return (true, 'Installed! Restart to apply. (${patchResp.bodyBytes.length} bytes)');
      }
      return (false, 'installPatch returned $success');
    } catch (e) {
      return (false, 'Error: $e');
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

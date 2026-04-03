import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _codePushChannel = MethodChannel('flutter/codepush');
const _nativeChannel = MethodChannel('com.flutterplaza.pray_and_serve/contacts');

const _serverUrl = 'https://api.codepush.flutterplaza.com';
const _appId = '2ca7dd88-547b-4281-9484-91501e596aa6';
const _releaseVersion = '1.2.0+13';

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
      final url =
        '$_serverUrl/api/v1/updates'
        '?app_id=$_appId'
        '&version=${Uri.encodeComponent(_releaseVersion)}'
        '&platform=ios'
        '&channel=production';

      // Check for update via native iOS URLSession.
      final checkResult = await _nativeChannel.invokeMethod<Map>('httpGet', {'url': url});
      if (checkResult == null) return (false, 'Native HTTP null');

      final statusCode = checkResult['statusCode'] as int;
      final body = checkResult['body'] as String? ?? '';

      if (statusCode == 204) return (false, 'No update (204)');
      if (statusCode != 200) return (false, 'Server $statusCode: $body');

      final data = jsonDecode(body) as Map<String, dynamic>;
      if (data['patch_available'] != true) return (false, 'No patch');

      final patchUrl = data['patch_url'] as String?;
      if (patchUrl == null || patchUrl.isEmpty) return (false, 'No patch URL');

      // Download patch bytes via native iOS URLSession.
      final dlResult = await _nativeChannel.invokeMethod<Map>('httpGetBytes', {'url': patchUrl});
      if (dlResult == null) return (false, 'Download null');

      final dlStatus = dlResult['statusCode'] as int;
      if (dlStatus != 200) return (false, 'Download $dlStatus');

      final patchBytes = dlResult['bytes'] as Uint8List;
      if (patchBytes.isEmpty) return (false, 'Empty patch');

      // Install via engine.
      final base64Data = base64Encode(patchBytes);
      final success = await _codePushChannel.invokeMethod<bool>(
        'CodePush.installPatch',
        [base64Data],
      );
      if (success == true) {
        return (true, 'Installed! Restart. (${patchBytes.length}B)');
      }
      return (false, 'installPatch=$success');
    } catch (e) {
      return (false, 'Err: $e');
    }
  }

  static Future<PatchInfo?> get currentPatch async {
    try {
      final result = await _codePushChannel
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
      return await _codePushChannel.invokeMethod<bool>('CodePush.isPatched') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> rollback() async {
    try {
      await _codePushChannel.invokeMethod<bool>('CodePush.rollback');
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

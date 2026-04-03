import 'package:flutter/services.dart' hide CodePush, UpdateInfo, PatchInfo, CodePushException;
import 'package:flutter_test/flutter_test.dart';
import 'package:pray_and_serve/services/code_push_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter/codepush');
  final log = <MethodCall>[];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('CodePush.checkForUpdate', () {
    test('returns update available when server has patch', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        log.add(call);
        if (call.method == 'CodePush.checkForUpdate') {
          return {'isUpdateAvailable': true, 'patchVersion': 'p3'};
        }
        return null;
      });

      final result = await CodePush.checkForUpdate();
      expect(result.isUpdateAvailable, isTrue);
      expect(result.patchVersion, 'p3');
      expect(log.single.method, 'CodePush.checkForUpdate');
    });

    test('returns no update when server has nothing', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return {'isUpdateAvailable': false};
      });

      final result = await CodePush.checkForUpdate();
      expect(result.isUpdateAvailable, isFalse);
      expect(result.patchVersion, isNull);
    });

    test('throws CodePushException when engine not available', () async {
      expect(
        () => CodePush.checkForUpdate(),
        throwsA(isA<CodePushException>()),
      );
    });
  });

  group('CodePush.downloadAndApply', () {
    test('calls the platform channel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        log.add(call);
        return true;
      });

      await CodePush.downloadAndApply();
      expect(log.single.method, 'CodePush.downloadAndApply');
    });
  });

  group('CodePush.currentPatch', () {
    test('returns PatchInfo when patched', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return {'version': 'p5', 'installedAt': 1234567890};
      });

      final patch = await CodePush.currentPatch;
      expect(patch, isNotNull);
      expect(patch!.version, 'p5');
    });

    test('returns null when not patched', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return null;
      });

      expect(await CodePush.currentPatch, isNull);
    });
  });

  group('CodePush.isPatched', () {
    test('returns true when patched', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return true;
      });

      expect(await CodePush.isPatched, isTrue);
    });

    test('returns false when not patched', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return false;
      });

      expect(await CodePush.isPatched, isFalse);
    });
  });

  group('CodePush.rollback', () {
    test('calls the platform channel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        log.add(call);
        return true;
      });

      await CodePush.rollback();
      expect(log.single.method, 'CodePush.rollback');
    });
  });
}

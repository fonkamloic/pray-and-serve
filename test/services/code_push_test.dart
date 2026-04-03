import 'package:flutter/services.dart';
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
    test('returns true when update is available', () async {
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

    test('returns false when no update', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return {'isUpdateAvailable': false};
      });

      final result = await CodePush.checkForUpdate();
      expect(result.isUpdateAvailable, isFalse);
      expect(result.patchVersion, isNull);
    });

    test('returns false when engine not available', () async {
      // No handler set — MissingPluginException
      final result = await CodePush.checkForUpdate();
      expect(result.isUpdateAvailable, isFalse);
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

    test('does not throw when engine not available', () async {
      await expectLater(CodePush.downloadAndApply(), completes);
    });
  });

  group('CodePush.currentPatchVersion', () {
    test('returns version when patched', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return {'version': 'p5', 'installedAt': 1234567890};
      });

      expect(await CodePush.currentPatchVersion, 'p5');
    });

    test('returns null when not patched', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return null;
      });

      expect(await CodePush.currentPatchVersion, isNull);
    });

    test('returns null when engine not available', () async {
      expect(await CodePush.currentPatchVersion, isNull);
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

    test('returns false when engine not available', () async {
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

    test('does not throw when engine not available', () async {
      await expectLater(CodePush.rollback(), completes);
    });
  });
}

import 'package:flutter/services.dart' hide CodePush, PatchInfo;
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
          .setMockMethodCallHandler(channel, (call) async => null);

      expect(await CodePush.currentPatch, isNull);
    });
  });

  group('CodePush.isPatched', () {
    test('returns true when patched', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => true);

      expect(await CodePush.isPatched, isTrue);
    });

    test('returns false when not patched', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => false);

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
  });
}

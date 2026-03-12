import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pray_and_serve/main.dart';
import 'package:pray_and_serve/services/storage_service.dart';

import 'helpers/fakes.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('PrayAndServeApp', () {
    testWidgets('renders MaterialApp with correct title', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();
      final notifications = FakeNotificationService();

      await tester.pumpWidget(PrayAndServeApp(
        storage: storage,
        notifications: notifications,
      ));

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, 'Pray & Serve');
      expect(app.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('renders home screen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();
      final notifications = FakeNotificationService();

      await tester.pumpWidget(PrayAndServeApp(
        storage: storage,
        notifications: notifications,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Pray & Serve'), findsOneWidget);
    });
  });
}

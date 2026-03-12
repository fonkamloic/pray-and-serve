import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pray_and_serve/main.dart';
import 'package:pray_and_serve/services/storage_service.dart';

import '../test/helpers/fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Full app flow', () {
    testWidgets('end-to-end user journey', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();
      final notifications = FakeNotificationService();

      await tester.pumpWidget(PrayAndServeApp(
        storage: storage,
        notifications: notifications,
      ));
      await tester.pumpAndSettle();

      // --- Verify initial state ---
      expect(find.text('Pray & Serve'), findsOneWidget);
      expect(find.text('0'), findsWidgets); // stats show zeros

      // --- PRAY FLOW ---
      // Tap "New Prayer" to add a prayer
      await tester.tap(find.text('New Prayer'));
      await tester.pumpAndSettle();

      // Fill in prayer title
      final titleFields = find.byType(TextField);
      await tester.enterText(titleFields.first, 'Guidance for work');
      await tester.pumpAndSettle();

      // Tap "Add Prayer" to save
      await tester.tap(find.text('Add Prayer'));
      await tester.pumpAndSettle();

      // Verify the prayer card appears
      expect(find.text('Guidance for work'), findsOneWidget);

      // --- JOURNAL FLOW ---
      // Navigate to Journal tab
      await tester.tap(find.text('Journal'));
      await tester.pumpAndSettle();

      // Tap "New Entry"
      await tester.tap(find.text('New Entry'));
      await tester.pumpAndSettle();

      // Fill in journal body - find the body field
      final journalFields = find.byType(TextField);
      // First visible text field should be the body
      if (journalFields.evaluate().isNotEmpty) {
        await tester.enterText(journalFields.first, 'God is faithful today');
        await tester.pumpAndSettle();
      }

      // Save the entry
      await tester.tap(find.text('Save Entry'));
      await tester.pumpAndSettle();

      // Verify entry appears
      expect(find.text('God is faithful today'), findsOneWidget);

      // --- SERVE FLOW ---
      // Navigate to Serve tab
      await tester.tap(find.text('Serve'));
      await tester.pumpAndSettle();

      // Tap "Add Person"
      final addPersonButton = find.text('Add Person');
      if (addPersonButton.evaluate().isNotEmpty) {
        await tester.tap(addPersonButton);
        await tester.pumpAndSettle();

        // Fill in name
        final nameFields = find.byType(TextField);
        if (nameFields.evaluate().isNotEmpty) {
          await tester.enterText(nameFields.first, 'John Smith');
          await tester.pumpAndSettle();
        }

        // Save person
        await tester.tap(find.text('Add Person'));
        await tester.pumpAndSettle();

        // Verify person card appears
        expect(find.text('John Smith'), findsOneWidget);
      }

      // --- SETTINGS FLOW ---
      // Open settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Verify settings panel shows
      expect(find.text('My Role'), findsOneWidget);
      expect(find.text('REMINDERS'), findsOneWidget);

      // Close settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // --- Navigate back through tabs to verify state persists ---
      await tester.tap(find.text('Pray'));
      await tester.pumpAndSettle();
      expect(find.text('Guidance for work'), findsOneWidget);

      await tester.tap(find.text('Journal'));
      await tester.pumpAndSettle();
      expect(find.text('God is faithful today'), findsOneWidget);
    });
  });
}

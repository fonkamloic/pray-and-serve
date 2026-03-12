import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pray_and_serve/widgets/bottom_sheet_modal.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('showAppBottomSheet', () {
    testWidgets('displays title and buttons', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showAppBottomSheet(
                  context: context,
                  title: 'Test Title',
                  saveLabel: 'Submit',
                  onSave: () {},
                  bodyBuilder: (_, __) => const Text('Body Content'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Body Content'), findsOneWidget);
    });

    testWidgets('save button disabled when canSave returns false',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showAppBottomSheet(
                  context: context,
                  title: 'Test',
                  onSave: () {},
                  canSave: () => false,
                  bodyBuilder: (_, __) => const SizedBox(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final saveButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Save'),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('save button calls onSave and closes sheet', (tester) async {
      bool saved = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showAppBottomSheet(
                  context: context,
                  title: 'Test',
                  onSave: () => saved = true,
                  bodyBuilder: (_, __) => const SizedBox(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(saved, isTrue);
      expect(find.text('Test'), findsNothing); // sheet closed
    });

    testWidgets('cancel button closes sheet', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showAppBottomSheet(
                  context: context,
                  title: 'Test',
                  onSave: () {},
                  bodyBuilder: (_, __) => const SizedBox(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsNothing);
    });

    testWidgets('close icon closes sheet', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showAppBottomSheet(
                  context: context,
                  title: 'Test',
                  onSave: () {},
                  bodyBuilder: (_, __) => const SizedBox(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsNothing);
    });
  });

  group('buildFieldLabel', () {
    testWidgets('renders uppercase label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: buildFieldLabel('test label')),
      ));

      expect(find.text('TEST LABEL'), findsOneWidget);
    });
  });
}

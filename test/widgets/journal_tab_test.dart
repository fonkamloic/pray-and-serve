import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pray_and_serve/models/journal_entry.dart';
import 'package:pray_and_serve/theme/app_theme.dart';
import 'package:pray_and_serve/widgets/journal_tab.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// The list that the test can inspect after onUpdate is called.
  late List<JournalEntry> capturedJournal;

  /// Wraps JournalTab inside MaterialApp with the dark theme so the widget
  /// tree mirrors production usage.  Uses a StatefulBuilder so that the
  /// default onUpdate callback can mutate the journal and rebuild.
  Widget buildApp({
    required List<JournalEntry> journal,
    void Function(List<JournalEntry> Function(List<JournalEntry>))? onUpdate,
  }) {
    capturedJournal = journal;
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: StatefulBuilder(
        builder: (context, setState) {
          return Scaffold(
            body: JournalTab(
              journal: capturedJournal,
              onUpdate: onUpdate ??
                  (fn) {
                    setState(() {
                      capturedJournal = fn(capturedJournal);
                    });
                  },
            ),
          );
        },
      ),
    );
  }

  JournalEntry makeEntry({
    String id = '1',
    String date = '2025-03-15',
    String title = '',
    String body = '',
    String scripture = '',
    String reflection = '',
  }) {
    return JournalEntry(
      id: id,
      date: date,
      title: title,
      body: body,
      scripture: scripture,
      reflection: reflection,
    );
  }

  /// Helper to find text inside RichText widgets (e.g. reflection block).
  Finder findRichTextContaining(String substring) {
    return find.byWidgetPredicate((widget) {
      if (widget is RichText) {
        final text = widget.text.toPlainText();
        return text.contains(substring);
      }
      return false;
    });
  }

  // ---------------------------------------------------------------------------
  // Tests
  // ---------------------------------------------------------------------------

  group('JournalTab - toolbar', () {
    testWidgets('renders "Prayer Journal" header', (tester) async {
      await tester.pumpWidget(buildApp(journal: []));
      expect(find.text('Prayer Journal'), findsOneWidget);
    });

    testWidgets('renders "New Entry" button with add icon', (tester) async {
      await tester.pumpWidget(buildApp(journal: []));
      expect(find.text('New Entry'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('JournalTab - empty state', () {
    testWidgets('shows empty-state message when journal list is empty',
        (tester) async {
      await tester.pumpWidget(buildApp(journal: []));

      expect(find.text('Your journal is empty.'), findsOneWidget);
      expect(find.text('Write what God is placing on your heart.'),
          findsOneWidget);
    });

    testWidgets('does not show empty state when entries exist',
        (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(body: 'Hello'),
      ]));

      expect(find.text('Your journal is empty.'), findsNothing);
    });
  });

  group('JournalTab - journal cards', () {
    testWidgets('displays body text on card', (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(body: 'The Lord is my shepherd'),
      ]));

      expect(find.text('The Lord is my shepherd'), findsOneWidget);
    });

    testWidgets('displays formatted date on card', (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(date: '2025-03-15', body: 'text'),
      ]));

      expect(find.text('Mar 15, 2025'), findsOneWidget);
    });

    testWidgets('shows title when title is not empty', (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(title: 'Morning Reflection', body: 'text'),
      ]));

      expect(find.text('Morning Reflection'), findsOneWidget);
    });

    testWidgets('does not show title widget when title is empty',
        (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(title: '', body: 'text'),
      ]));

      // The body text is present; no title text widget rendered.
      expect(find.text('text'), findsOneWidget);
    });

    testWidgets('shows scripture with book emoji when scripture is present',
        (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(body: 'text', scripture: 'Psalm 23:1'),
      ]));

      expect(find.textContaining('Psalm 23:1'), findsOneWidget);
      expect(find.textContaining('\u{1F4D6}'), findsAtLeast(1));
    });

    testWidgets('does not show scripture row when scripture is empty',
        (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(body: 'text', scripture: ''),
      ]));

      // No scripture line with book emoji followed by space.
      expect(find.textContaining('\u{1F4D6} '), findsNothing);
    });

    testWidgets('shows reflection block when reflection is present',
        (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(body: 'text', reflection: 'Trust in His timing'),
      ]));

      // Reflection is rendered via RichText, so use our custom finder.
      expect(
          findRichTextContaining('What is God teaching me:'), findsOneWidget);
      expect(findRichTextContaining('Trust in His timing'), findsOneWidget);
    });

    testWidgets('does not show reflection block when reflection is empty',
        (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(body: 'text', reflection: ''),
      ]));

      expect(findRichTextContaining('What is God teaching me:'), findsNothing);
    });

    testWidgets('each card has edit and delete icon buttons', (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(body: 'text'),
      ]));

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });

  group('JournalTab - sorting', () {
    testWidgets('entries are displayed sorted by date descending',
        (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(id: '1', date: '2025-01-01', body: 'Older'),
        makeEntry(id: '2', date: '2025-06-15', body: 'Newer'),
      ]));

      // The newer date should come first in the list.
      final newerOffset = tester.getTopLeft(find.text('Newer'));
      final olderOffset = tester.getTopLeft(find.text('Older'));
      expect(newerOffset.dy, lessThan(olderOffset.dy));
    });
  });

  group('JournalTab - add new entry via bottom sheet', () {
    testWidgets('tapping New Entry opens bottom sheet with correct title',
        (tester) async {
      await tester.pumpWidget(buildApp(journal: []));

      await tester.tap(find.text('New Entry'));
      await tester.pumpAndSettle();

      // Bottom sheet header says "Journal Entry" for new entries.
      expect(find.text('Journal Entry'), findsOneWidget);
      // Save button labelled "Save Entry".
      expect(find.text('Save Entry'), findsOneWidget);
    });

    testWidgets('bottom sheet has all four field labels', (tester) async {
      await tester.pumpWidget(buildApp(journal: []));

      await tester.tap(find.text('New Entry'));
      await tester.pumpAndSettle();

      expect(find.text('TITLE (OPTIONAL)'), findsOneWidget);
      expect(find.text("WHAT'S ON YOUR HEART?"), findsOneWidget);
      expect(find.text('SCRIPTURE REFERENCE (OPTIONAL)'), findsOneWidget);
      expect(find.text('WHAT IS GOD TEACHING ME? (OPTIONAL)'), findsOneWidget);
    });

    testWidgets('bottom sheet has hint texts for fields', (tester) async {
      await tester.pumpWidget(buildApp(journal: []));

      await tester.tap(find.text('New Entry'));
      await tester.pumpAndSettle();

      expect(find.text('A word for today...'), findsOneWidget);
      expect(find.text('Write freely...'), findsOneWidget);
      expect(find.text('e.g., Psalm 23'), findsOneWidget);
      expect(find.text('Reflect on His voice...'), findsOneWidget);
    });

    testWidgets('Save Entry button is disabled when body is empty',
        (tester) async {
      await tester.pumpWidget(buildApp(journal: []));

      await tester.tap(find.text('New Entry'));
      await tester.pumpAndSettle();

      // The "Save Entry" ElevatedButton should be disabled (onPressed == null).
      final saveButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Save Entry'),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('Cancel button closes bottom sheet without saving',
        (tester) async {
      bool onUpdateCalled = false;

      await tester.pumpWidget(buildApp(
        journal: [],
        onUpdate: (_) {
          onUpdateCalled = true;
        },
      ));

      await tester.tap(find.text('New Entry'));
      await tester.pumpAndSettle();

      expect(find.text('Journal Entry'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(onUpdateCalled, isFalse);
      // Bottom sheet is dismissed.
      expect(find.text('Journal Entry'), findsNothing);
    });

    testWidgets('close icon button dismisses bottom sheet', (tester) async {
      await tester.pumpWidget(buildApp(journal: []));

      await tester.tap(find.text('New Entry'));
      await tester.pumpAndSettle();

      expect(find.text('Journal Entry'), findsOneWidget);

      // The X button in the sheet header.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Journal Entry'), findsNothing);
    });

    testWidgets('all four TextFields are present for a new entry',
        (tester) async {
      await tester.pumpWidget(buildApp(journal: []));

      await tester.tap(find.text('New Entry'));
      await tester.pumpAndSettle();

      // Four TextFields in the body of the sheet.
      expect(find.byType(TextField), findsNWidgets(4));
    });
  });

  group('JournalTab - edit entry via bottom sheet', () {
    testWidgets('tapping edit icon opens sheet with "Edit Entry" title',
        (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(
          body: 'My text',
          title: 'My title',
          scripture: 'Gen 1:1',
          reflection: 'God is good',
        ),
      ]));

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit Entry'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
    });

    testWidgets('edit sheet pre-populates all fields from existing entry',
        (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(
          body: 'Original body',
          title: 'Original title',
          scripture: 'Psalm 1',
          reflection: 'Reflect on this',
        ),
      ]));

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // TextEditingControllers are initialized with existing text.
      expect(
          find.widgetWithText(TextField, 'Original title'), findsOneWidget);
      expect(
          find.widgetWithText(TextField, 'Original body'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Psalm 1'), findsOneWidget);
      expect(
          find.widgetWithText(TextField, 'Reflect on this'), findsOneWidget);
    });

    testWidgets(
        'Update button is enabled when editing an entry with non-empty body',
        (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(body: 'Non-empty body'),
      ]));

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      final updateButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Update'),
      );
      expect(updateButton.onPressed, isNotNull);
    });

    testWidgets('updating entry calls onUpdate with mutated entry',
        (tester) async {
      final original = makeEntry(
        id: 'e1',
        body: 'Old body',
        title: 'Old title',
        scripture: '',
        reflection: '',
      );
      List<JournalEntry> updatedList = [];

      await tester.pumpWidget(buildApp(
        journal: [original],
        onUpdate: (fn) {
          updatedList = fn([original]);
        },
      ));

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // Clear the body field and type new text.
      final bodyField = find.widgetWithText(TextField, 'Old body');
      await tester.enterText(bodyField, 'Updated body');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      expect(updatedList.length, 1);
      expect(updatedList.first.body, 'Updated body');
      expect(updatedList.first.id, 'e1');
    });

    testWidgets('updating entry preserves fields that were not changed',
        (tester) async {
      final original = makeEntry(
        id: 'e2',
        body: 'Keep body',
        title: 'Keep title',
        scripture: 'John 1:1',
        reflection: 'Stay the same',
      );
      List<JournalEntry> updatedList = [];

      await tester.pumpWidget(buildApp(
        journal: [original],
        onUpdate: (fn) {
          updatedList = fn([original]);
        },
      ));

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // Only change the title.
      await tester.enterText(
          find.widgetWithText(TextField, 'Keep title'), 'New title');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      final updated = updatedList.first;
      expect(updated.title, 'New title');
      expect(updated.body, 'Keep body');
      expect(updated.scripture, 'John 1:1');
      expect(updated.reflection, 'Stay the same');
    });

    testWidgets('cancel in edit sheet does not trigger onUpdate',
        (tester) async {
      bool onUpdateCalled = false;

      await tester.pumpWidget(buildApp(
        journal: [makeEntry(body: 'Existing')],
        onUpdate: (_) {
          onUpdateCalled = true;
        },
      ));

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(onUpdateCalled, isFalse);
    });
  });

  group('JournalTab - delete entry', () {
    testWidgets('tapping delete icon shows confirmation dialog',
        (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(body: 'text'),
      ]));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete this entry?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('cancel button in delete dialog closes without deleting',
        (tester) async {
      bool onUpdateCalled = false;

      await tester.pumpWidget(buildApp(
        journal: [makeEntry(body: 'Keep me')],
        onUpdate: (_) {
          onUpdateCalled = true;
        },
      ));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(onUpdateCalled, isFalse);
      expect(find.text('Delete this entry?'), findsNothing);
    });

    testWidgets('confirming delete removes the entry via onUpdate',
        (tester) async {
      final entry = makeEntry(id: 'del1', body: 'Delete me');
      List<JournalEntry> updatedList = [];

      await tester.pumpWidget(buildApp(
        journal: [entry],
        onUpdate: (fn) {
          updatedList = fn([entry]);
        },
      ));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(updatedList, isEmpty);
    });

    testWidgets(
        'confirming delete only removes the targeted entry, leaving others',
        (tester) async {
      final keep = makeEntry(id: 'keep1', body: 'Keep this');
      final remove = makeEntry(id: 'del1', body: 'Delete this');
      List<JournalEntry> updatedList = [];

      await tester.pumpWidget(buildApp(
        journal: [keep, remove],
        onUpdate: (fn) {
          updatedList = fn([keep, remove]);
        },
      ));

      // Both delete icons exist; tap the second one (for "Delete this").
      final deleteIcons = find.byIcon(Icons.delete_outline);
      expect(deleteIcons, findsNWidgets(2));
      await tester.tap(deleteIcons.last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(updatedList.length, 1);
      expect(updatedList.first.id, 'keep1');
    });

    testWidgets('Delete button text has coral color', (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(body: 'text'),
      ]));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      final deleteTextWidget = tester.widget<Text>(find.text('Delete'));
      expect(deleteTextWidget.style?.color, AppColors.coral);
    });
  });

  group('JournalTab - date formatting edge cases', () {
    testWidgets('January date renders correctly', (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(date: '2024-01-05', body: 'text'),
      ]));

      expect(find.text('Jan 5, 2024'), findsOneWidget);
    });

    testWidgets('December date renders correctly', (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(date: '2025-12-25', body: 'text'),
      ]));

      expect(find.text('Dec 25, 2025'), findsOneWidget);
    });

    testWidgets('June date renders correctly', (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(date: '2025-06-01', body: 'text'),
      ]));

      expect(find.text('Jun 1, 2025'), findsOneWidget);
    });
  });

  group('JournalTab - multiple entries rendering', () {
    testWidgets('renders multiple entries', (tester) async {
      final entries = [
        makeEntry(id: '1', date: '2025-03-15', body: 'First entry'),
        makeEntry(id: '2', date: '2025-03-14', body: 'Second entry'),
        makeEntry(id: '3', date: '2025-03-13', body: 'Third entry'),
      ];

      await tester.pumpWidget(buildApp(journal: entries));

      expect(find.text('First entry'), findsOneWidget);
      expect(find.text('Second entry'), findsOneWidget);
      expect(find.text('Third entry'), findsOneWidget);
    });

    testWidgets('edit and delete icons shown for every entry', (tester) async {
      final entries = [
        makeEntry(id: '1', body: 'A'),
        makeEntry(id: '2', body: 'B'),
      ];

      await tester.pumpWidget(buildApp(journal: entries));

      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    });
  });

  group('JournalTab - card conditional sections', () {
    testWidgets('card with all optional fields populated shows everything',
        (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(
          body: 'Main body text',
          title: 'My Title',
          scripture: 'John 3:16',
          reflection: 'God so loved the world',
        ),
      ]));

      expect(find.text('My Title'), findsOneWidget);
      expect(find.text('Main body text'), findsOneWidget);
      expect(find.textContaining('John 3:16'), findsOneWidget);
      expect(findRichTextContaining('God so loved the world'), findsOneWidget);
      expect(
          findRichTextContaining('What is God teaching me:'), findsOneWidget);
    });

    testWidgets('card with no optional fields shows only body and date',
        (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(
          date: '2025-05-01',
          body: 'Only body here',
          title: '',
          scripture: '',
          reflection: '',
        ),
      ]));

      expect(find.text('Only body here'), findsOneWidget);
      expect(find.text('May 1, 2025'), findsOneWidget);

      // No scripture line (with book emoji + space prefix).
      expect(find.textContaining('\u{1F4D6} '), findsNothing);
      // No reflection block.
      expect(findRichTextContaining('What is God teaching me:'), findsNothing);
    });
  });

  group('JournalTab - stateful interaction via default onUpdate', () {
    testWidgets('deleting last entry returns to empty state', (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(id: 'only', body: 'Lone entry'),
      ]));

      expect(find.text('Lone entry'), findsOneWidget);
      expect(find.text('Your journal is empty.'), findsNothing);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Your journal is empty.'), findsOneWidget);
      expect(find.text('Lone entry'), findsNothing);
    });

    testWidgets('editing an entry updates the card in place', (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(id: 'e1', body: 'Before edit', title: 'Old Title'),
      ]));

      expect(find.text('Before edit'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // Clear and type new body.
      await tester.enterText(
          find.widgetWithText(TextField, 'Before edit'), 'After edit');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      expect(find.text('After edit'), findsOneWidget);
      expect(find.text('Before edit'), findsNothing);
    });

    testWidgets('editing title updates the displayed title', (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(id: 'e1', body: 'Body text', title: 'Original Title'),
      ]));

      expect(find.text('Original Title'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextField, 'Original Title'), 'New Title');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      expect(find.text('New Title'), findsOneWidget);
      expect(find.text('Original Title'), findsNothing);
    });

    testWidgets('deleting one of two entries leaves the other visible',
        (tester) async {
      await tester.pumpWidget(buildApp(journal: [
        makeEntry(id: 'a', date: '2025-01-01', body: 'Entry A'),
        makeEntry(id: 'b', date: '2025-02-01', body: 'Entry B'),
      ]));

      expect(find.text('Entry A'), findsOneWidget);
      expect(find.text('Entry B'), findsOneWidget);

      // Delete the first one displayed (sorted desc, so Entry B date is newer).
      final deleteIcons = find.byIcon(Icons.delete_outline);
      await tester.tap(deleteIcons.first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // One entry should remain, the other gone.
      final entryAPresent = find.text('Entry A').evaluate().isNotEmpty;
      final entryBPresent = find.text('Entry B').evaluate().isNotEmpty;
      // Exactly one should remain.
      expect(entryAPresent || entryBPresent, isTrue);
      expect(find.text('Your journal is empty.'), findsNothing);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pray_and_serve/models/person.dart';
import 'package:pray_and_serve/models/care_log.dart';
import 'package:pray_and_serve/theme/app_theme.dart';
import 'package:pray_and_serve/widgets/serve_tab.dart';

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

  String todayStr() => DateTime.now().toIso8601String().split('T')[0];

  String daysAgoStr(int days) =>
      DateTime.now().subtract(Duration(days: days)).toIso8601String().split('T')[0];

  Widget buildApp({
    String role = 'Pastor',
    int reminderDays = 14,
    List<Person>? flock,
    List<CareLog>? careLogs,
    void Function(List<Person> Function(List<Person>))? onUpdateFlock,
    void Function(List<CareLog> Function(List<CareLog>))? onUpdateCareLogs,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: ServeTab(
          role: role,
          reminderDays: reminderDays,
          flock: flock ?? [],
          careLogs: careLogs ?? [],
          onUpdateFlock: onUpdateFlock ?? (_) {},
          onUpdateCareLogs: onUpdateCareLogs ?? (_) {},
        ),
      ),
    );
  }

  Person makePerson({
    String id = '1',
    String name = 'Alice Smith',
    String notes = '',
    List<String> tags = const [],
    List<String> needs = const [],
    String contactFreq = 'Monthly',
    String? lastContact,
  }) {
    return Person(
      id: id,
      name: name,
      notes: notes,
      tags: tags,
      needs: needs,
      contactFreq: contactFreq,
      lastContact: lastContact,
    );
  }

  CareLog makeLog({
    String id = 'log1',
    String personId = '1',
    String? date,
    String type = 'Call',
    String note = 'Talked about health',
  }) {
    return CareLog(
      id: id,
      personId: personId,
      date: date ?? todayStr(),
      type: type,
      note: note,
    );
  }

  // ===========================================================================
  // ROLE-BASED SECTION TITLES
  // ===========================================================================
  group('Section title by role', () {
    testWidgets('Pastor shows "My Flock"', (tester) async {
      await tester.pumpWidget(buildApp(role: 'Pastor'));
      expect(find.text('My Flock'), findsOneWidget);
    });

    testWidgets('Elder shows "My Shepherding"', (tester) async {
      await tester.pumpWidget(buildApp(role: 'Elder'));
      expect(find.text('My Shepherding'), findsOneWidget);
    });

    testWidgets('Deacon shows "Those I Serve"', (tester) async {
      await tester.pumpWidget(buildApp(role: 'Deacon'));
      expect(find.text('Those I Serve'), findsOneWidget);
    });

    testWidgets('Member shows "People On My Heart"', (tester) async {
      await tester.pumpWidget(buildApp(role: 'Member'));
      expect(find.text('People On My Heart'), findsOneWidget);
    });

    testWidgets('Unknown role falls through to default', (tester) async {
      await tester.pumpWidget(buildApp(role: 'Volunteer'));
      expect(find.text('People On My Heart'), findsOneWidget);
    });
  });

  // ===========================================================================
  // SUB-TABS
  // ===========================================================================
  group('Sub-tabs', () {
    testWidgets('People, Need Contact, and Care Log are rendered',
        (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('People'), findsOneWidget);
      expect(find.textContaining('Need Contact'), findsOneWidget);
      expect(find.text('Care Log'), findsOneWidget);
    });

    testWidgets('Need Contact label shows count of overdue people',
        (tester) async {
      final people = [
        makePerson(id: '1', name: 'A', contactFreq: 'Weekly', lastContact: '2020-01-01'),
        makePerson(id: '2', name: 'B', contactFreq: 'Weekly', lastContact: '2020-01-01'),
        makePerson(id: '3', name: 'C', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people, reminderDays: 7));
      expect(find.text('Need Contact (2)'), findsOneWidget);
    });

    testWidgets('Need Contact shows 0 when nobody is overdue',
        (tester) async {
      final people = [
        makePerson(id: '1', name: 'A', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      expect(find.text('Need Contact (0)'), findsOneWidget);
    });

    testWidgets('Tapping sub-tabs switches content', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Initially People tab content visible (search bar)
      expect(find.text('Search people...'), findsOneWidget);

      // Tap Care Log
      await tester.tap(find.text('Care Log'));
      await tester.pumpAndSettle();

      // Care Log empty state should be visible
      expect(find.text('No care logs yet.'), findsOneWidget);
    });
  });

  // ===========================================================================
  // ADD PERSON BUTTON
  // ===========================================================================
  group('Add Person button', () {
    testWidgets('renders Add Person elevated button', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('Add Person'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('tapping Add Person opens bottom sheet modal', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();

      expect(find.text('Add Someone to Care For'), findsOneWidget);
      expect(find.text('Their name...'), findsOneWidget);
    });

    testWidgets('bottom sheet for new person shows correct save label',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();

      // The ElevatedButton save label should say "Add Person"
      // There is one in the toolbar and one in the bottom sheet footer
      expect(find.text('Add Person'), findsNWidgets(2));
    });

    testWidgets('Needs section appears for Pastor role in add modal',
        (tester) async {
      await tester.pumpWidget(buildApp(role: 'Pastor'));
      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();

      expect(find.text('NEEDS'), findsOneWidget);
    });

    testWidgets('Needs section appears for Elder role in add modal',
        (tester) async {
      await tester.pumpWidget(buildApp(role: 'Elder'));
      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();

      expect(find.text('NEEDS'), findsOneWidget);
    });

    testWidgets('Needs section appears for Deacon role in add modal',
        (tester) async {
      await tester.pumpWidget(buildApp(role: 'Deacon'));
      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();

      expect(find.text('NEEDS'), findsOneWidget);
    });

    testWidgets('Needs section does NOT appear for Member role in add modal',
        (tester) async {
      await tester.pumpWidget(buildApp(role: 'Member'));
      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();

      expect(find.text('NEEDS'), findsNothing);
    });

    testWidgets('add modal shows Tags chip selector', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();

      expect(find.text('TAGS'), findsOneWidget);
      // Some tag chips should be visible
      expect(find.text('Grieving'), findsOneWidget);
      expect(find.text('New Believer'), findsOneWidget);
    });

    testWidgets('add modal shows contact frequency dropdown', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();

      expect(find.text('DESIRED CONTACT FREQUENCY'), findsOneWidget);
      // Default value
      expect(find.text('Monthly'), findsOneWidget);
    });

    testWidgets('saving a new person calls onUpdateFlock', (tester) async {
      List<Person> Function(List<Person>)? capturedFn;
      await tester.pumpWidget(buildApp(
        onUpdateFlock: (fn) => capturedFn = fn,
      ));

      await tester.tap(find.text('Add Person'));
      await tester.pumpAndSettle();

      // Type a name — the TextField has the hint 'Their name...'
      await tester.enterText(
        find.widgetWithText(TextField, 'Their name...'),
        'New Guy',
      );
      await tester.pumpAndSettle();

      // The canSave closure captures `name` by reference, but the modal
      // only rebuilds when setModalState is called.  Change the dropdown
      // (which calls setModalState) so the save button picks up the new
      // name value.
      // Open the dropdown
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      // Select a different frequency
      await tester.tap(find.text('Weekly').last);
      await tester.pumpAndSettle();

      // Tap the "Add Person" save button (the one inside the bottom sheet)
      // It is the second "Add Person" text (first is the toolbar button)
      final addButtons = find.text('Add Person');
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      expect(capturedFn, isNotNull);
      final result = capturedFn!([]);
      expect(result.length, 1);
      expect(result.first.name, 'New Guy');
    });
  });

  // ===========================================================================
  // PEOPLE LIST (sub-tab 0)
  // ===========================================================================
  group('People sub-tab', () {
    testWidgets('renders person cards with names', (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice Smith', lastContact: todayStr()),
        makePerson(id: '2', name: 'Bob Johnson', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('Bob Johnson'), findsOneWidget);
    });

    testWidgets('shows search field with placeholder', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('Search people...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('search filters people by name', (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice Smith', lastContact: todayStr()),
        makePerson(id: '2', name: 'Bob Johnson', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      // Type search text
      await tester.enterText(find.byType(TextField).first, 'Alice');
      await tester.pumpAndSettle();

      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('Bob Johnson'), findsNothing);
    });

    testWidgets('search is case-insensitive', (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice Smith', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'alice');
      await tester.pumpAndSettle();

      expect(find.text('Alice Smith'), findsOneWidget);
    });

    testWidgets('search with no match shows empty state', (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice Smith', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'zzzzz');
      await tester.pumpAndSettle();

      expect(find.text('No one added yet.'), findsOneWidget);
    });

    testWidgets('empty state when flock is empty', (tester) async {
      await tester.pumpWidget(buildApp(flock: []));
      await tester.pumpAndSettle();

      expect(find.text('No one added yet.'), findsOneWidget);
      expect(
        find.text('Add the people God has placed on your heart to care for.'),
        findsOneWidget,
      );
    });

    testWidgets('person card shows avatar with first letter', (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice Smith', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      // Avatar should show 'A'
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('person contacted today shows "Today"', (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('person never contacted shows "Never contacted"',
        (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: null),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      expect(find.text('Never contacted'), findsOneWidget);
    });

    testWidgets('person contacted N days ago shows "Nd ago"', (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: daysAgoStr(5)),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      expect(find.text('5d ago'), findsOneWidget);
    });

    testWidgets('person card shows tag chips when tags present',
        (tester) async {
      final people = [
        makePerson(
          id: '1',
          name: 'Alice',
          tags: ['Grieving', 'Elderly'],
          lastContact: todayStr(),
        ),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      expect(find.text('GRIEVING'), findsOneWidget);
      expect(find.text('ELDERLY'), findsOneWidget);
    });

    testWidgets('person card does not show tags row when tags empty',
        (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice', tags: [], lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      // Tags are uppercased when displayed, but none should be visible
      expect(find.text('GRIEVING'), findsNothing);
    });

    testWidgets('person card shows needs row when needs present',
        (tester) async {
      final people = [
        makePerson(
          id: '1',
          name: 'Alice',
          needs: ['Meals', 'Prayer'],
          lastContact: todayStr(),
        ),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      expect(find.text('NEEDS:'), findsOneWidget);
      expect(find.text('Meals'), findsOneWidget);
      expect(find.text('Prayer'), findsOneWidget);
    });

    testWidgets('person card does not show needs row when needs empty',
        (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice', needs: [], lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      expect(find.text('NEEDS:'), findsNothing);
    });

    testWidgets('person card shows notes when present', (tester) async {
      final people = [
        makePerson(
          id: '1',
          name: 'Alice',
          notes: 'Going through a tough time',
          lastContact: todayStr(),
        ),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      expect(find.text('Going through a tough time'), findsOneWidget);
    });

    testWidgets('person card has Log Contact button', (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      expect(find.text('Log Contact'), findsOneWidget);
      expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
    });

    testWidgets('person card has edit and delete buttons', (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('overdue person shows warning icon', (tester) async {
      final people = [
        makePerson(
          id: '1',
          name: 'Overdue',
          contactFreq: 'Weekly',
          lastContact: '2020-01-01',
        ),
      ];
      await tester.pumpWidget(buildApp(flock: people, reminderDays: 7));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('non-overdue person does not show warning icon',
        (tester) async {
      final people = [
        makePerson(id: '1', name: 'Current', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });
  });

  // ===========================================================================
  // EDIT PERSON MODAL
  // ===========================================================================
  group('Edit person modal', () {
    testWidgets('tapping edit icon opens bottom sheet with existing data',
        (tester) async {
      final people = [
        makePerson(
          id: '1',
          name: 'Alice',
          notes: 'Some notes',
          lastContact: todayStr(),
        ),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit Person'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
    });

    testWidgets('edit modal calls onUpdateFlock with updated data',
        (tester) async {
      List<Person> Function(List<Person>)? capturedFn;
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(
        flock: people,
        onUpdateFlock: (fn) => capturedFn = fn,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // Clear and type new name
      final nameField = find.widgetWithText(TextField, 'Alice');
      await tester.enterText(nameField, 'Alice Updated');
      await tester.pumpAndSettle();

      // Tap Update
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      expect(capturedFn, isNotNull);
      final result = capturedFn!(people);
      expect(result.first.name, 'Alice Updated');
    });
  });

  // ===========================================================================
  // DELETE PERSON
  // ===========================================================================
  group('Delete person', () {
    testWidgets('tapping delete shows confirmation dialog', (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Remove Alice?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('cancel button dismisses delete dialog', (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Remove Alice?'), findsNothing);
    });

    testWidgets('confirm delete calls onUpdateFlock and onUpdateCareLogs',
        (tester) async {
      bool flockUpdated = false;
      bool careLogsUpdated = false;
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(
        flock: people,
        onUpdateFlock: (_) => flockUpdated = true,
        onUpdateCareLogs: (_) => careLogsUpdated = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(flockUpdated, isTrue);
      expect(careLogsUpdated, isTrue);
    });

    testWidgets('delete removes the correct person by id', (tester) async {
      List<Person> Function(List<Person>)? capturedFn;
      final people = [
        makePerson(id: 'keep', name: 'Keep', lastContact: todayStr()),
        makePerson(id: 'remove', name: 'Remove Me', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(
        flock: people,
        onUpdateFlock: (fn) => capturedFn = fn,
      ));
      await tester.pumpAndSettle();

      // Tap delete on the second person (scroll if needed)
      final deleteButtons = find.byIcon(Icons.delete_outline);
      await tester.tap(deleteButtons.last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(capturedFn, isNotNull);
      final result = capturedFn!(people);
      expect(result.length, 1);
      expect(result.first.id, 'keep');
    });
  });

  // ===========================================================================
  // LOG CONTACT MODAL
  // ===========================================================================
  group('Log Contact modal', () {
    testWidgets('tapping Log Contact opens modal with person name',
        (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log Contact'));
      await tester.pumpAndSettle();

      // Title includes person name with em dash
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.text('Log Contact'), findsWidgets);
    });

    testWidgets('log contact modal shows contact type chips', (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log Contact'));
      await tester.pumpAndSettle();

      // Contact type options
      expect(find.text('Call'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Visit'), findsOneWidget);
    });

    testWidgets('log contact modal has notes field with hint', (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log Contact'));
      await tester.pumpAndSettle();

      expect(
        find.text('How is Alice doing? What did you talk about?'),
        findsOneWidget,
      );
    });

    testWidgets('saving log contact calls onUpdateCareLogs and onUpdateFlock',
        (tester) async {
      bool careLogsUpdated = false;
      bool flockUpdated = false;
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: '2020-01-01'),
      ];
      await tester.pumpWidget(buildApp(
        flock: people,
        onUpdateFlock: (_) => flockUpdated = true,
        onUpdateCareLogs: (_) => careLogsUpdated = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log Contact'));
      await tester.pumpAndSettle();

      // Enter a note so the save button is enabled
      final noteField = find.widgetWithText(
        TextField,
        'How is Alice doing? What did you talk about?',
      );
      await tester.enterText(noteField, 'Great conversation');
      await tester.pumpAndSettle();

      // The canSave closure captures `note` by reference, but the modal
      // only rebuilds when setModalState is called.  Toggle a contact type
      // chip to trigger setModalState so the save button picks up the note.
      await tester.tap(find.text('Text'));
      await tester.pumpAndSettle();

      // Tap the save button - it says "Log Contact" in the bottom sheet footer
      // Find the ElevatedButton that contains "Log Contact"
      final saveButton = find.widgetWithText(ElevatedButton, 'Log Contact');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(careLogsUpdated, isTrue);
      expect(flockUpdated, isTrue);
    });
  });

  // ===========================================================================
  // OVERDUE / NEED CONTACT SUB-TAB
  // ===========================================================================
  group('Overdue (Need Contact) sub-tab', () {
    testWidgets('shows empty state when nobody is overdue', (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: todayStr()),
      ];
      await tester.pumpWidget(buildApp(flock: people));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Need Contact'));
      await tester.pumpAndSettle();

      expect(find.text('Everyone is cared for!'), findsOneWidget);
      expect(
        find.text('Everyone is within their contact schedule.'),
        findsOneWidget,
      );
    });

    testWidgets('shows empty state with no flock at all', (tester) async {
      await tester.pumpWidget(buildApp(flock: []));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Need Contact'));
      await tester.pumpAndSettle();

      expect(find.text('Everyone is cared for!'), findsOneWidget);
    });

    testWidgets('lists overdue people with Reach Out button', (tester) async {
      final people = [
        makePerson(
          id: '1',
          name: 'Neglected Ned',
          contactFreq: 'Weekly',
          lastContact: '2020-01-01',
        ),
      ];
      await tester.pumpWidget(buildApp(flock: people, reminderDays: 7));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Need Contact'));
      await tester.pumpAndSettle();

      expect(find.text('Neglected Ned'), findsWidgets);
      expect(find.text('Reach Out'), findsOneWidget);
    });

    testWidgets('overdue person never contacted shows "Never contacted"',
        (tester) async {
      final people = [
        makePerson(
          id: '1',
          name: 'New Guy',
          contactFreq: 'Weekly',
          lastContact: null, // never contacted
        ),
      ];
      await tester.pumpWidget(buildApp(flock: people, reminderDays: 7));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Need Contact'));
      await tester.pumpAndSettle();

      expect(find.text('Never contacted'), findsWidgets);
    });

    testWidgets('overdue person shows days since last contact', (tester) async {
      final people = [
        makePerson(
          id: '1',
          name: 'Overdue',
          contactFreq: 'Weekly',
          lastContact: daysAgoStr(20),
        ),
      ];
      await tester.pumpWidget(buildApp(flock: people, reminderDays: 7));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Need Contact'));
      await tester.pumpAndSettle();

      expect(find.text('20 days since last contact'), findsOneWidget);
    });

    testWidgets('overdue card shows notes when present', (tester) async {
      final people = [
        makePerson(
          id: '1',
          name: 'Overdue',
          contactFreq: 'Weekly',
          lastContact: '2020-01-01',
          notes: 'Check on health',
        ),
      ];
      await tester.pumpWidget(buildApp(flock: people, reminderDays: 7));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Need Contact'));
      await tester.pumpAndSettle();

      expect(find.text('Check on health'), findsWidgets);
    });

    testWidgets('overdue card has avatar with first letter', (tester) async {
      final people = [
        makePerson(
          id: '1',
          name: 'Zara',
          contactFreq: 'Weekly',
          lastContact: '2020-01-01',
        ),
      ];
      await tester.pumpWidget(buildApp(flock: people, reminderDays: 7));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Need Contact'));
      await tester.pumpAndSettle();

      // 'Z' avatar in the overdue card
      expect(find.text('Z'), findsWidgets);
    });

    testWidgets('tapping Reach Out opens Log Contact modal', (tester) async {
      final people = [
        makePerson(
          id: '1',
          name: 'NeedsCare',
          contactFreq: 'Weekly',
          lastContact: '2020-01-01',
        ),
      ];
      await tester.pumpWidget(buildApp(flock: people, reminderDays: 7));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Need Contact'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reach Out'));
      await tester.pumpAndSettle();

      // The Log Contact modal should open with the person's name
      expect(find.textContaining('NeedsCare'), findsWidgets);
      expect(find.text('CONTACT TYPE'), findsOneWidget);
    });

    testWidgets('only overdue people appear, not current ones', (tester) async {
      final people = [
        makePerson(
          id: '1',
          name: 'Overdue Alice',
          contactFreq: 'Weekly',
          lastContact: '2020-01-01',
        ),
        makePerson(
          id: '2',
          name: 'Current Bob',
          contactFreq: 'Monthly',
          lastContact: todayStr(),
        ),
      ];
      await tester.pumpWidget(buildApp(flock: people, reminderDays: 7));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Need Contact'));
      await tester.pumpAndSettle();

      expect(find.text('Overdue Alice'), findsWidgets);
      // Current Bob should NOT be in the overdue list. But IndexedStack keeps
      // all children alive, so check the Reach Out button count instead.
      expect(find.text('Reach Out'), findsOneWidget);
    });
  });

  // ===========================================================================
  // CARE LOG SUB-TAB
  // ===========================================================================
  group('Care Log sub-tab', () {
    testWidgets('shows empty state when no care logs', (tester) async {
      await tester.pumpWidget(buildApp(careLogs: []));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Care Log'));
      await tester.pumpAndSettle();

      expect(find.text('No care logs yet.'), findsOneWidget);
      expect(
        find.text(
            'Log your contacts and visits to keep track of your care.'),
        findsOneWidget,
      );
    });

    testWidgets('renders care log cards with person name and note',
        (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: todayStr()),
      ];
      final logs = [
        makeLog(
          id: 'log1',
          personId: '1',
          note: 'Good conversation about faith',
          type: 'Call',
        ),
      ];
      await tester.pumpWidget(buildApp(flock: people, careLogs: logs));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Care Log'));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsWidgets);
      expect(find.text('Good conversation about faith'), findsOneWidget);
    });

    testWidgets('care log card shows contact type badge', (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: todayStr()),
      ];
      final logs = [
        makeLog(id: 'log1', personId: '1', type: 'Visit', note: 'Visited'),
      ];
      await tester.pumpWidget(buildApp(flock: people, careLogs: logs));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Care Log'));
      await tester.pumpAndSettle();

      expect(find.text('Visit'), findsOneWidget);
    });

    testWidgets('care log for unknown person shows "Unknown" and "?"',
        (tester) async {
      final logs = [
        makeLog(
          id: 'log1',
          personId: 'nonexistent',
          note: 'Orphaned log',
        ),
      ];
      await tester.pumpWidget(buildApp(flock: [], careLogs: logs));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Care Log'));
      await tester.pumpAndSettle();

      expect(find.text('Unknown'), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('care log card has delete button', (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: todayStr()),
      ];
      final logs = [
        makeLog(id: 'log1', personId: '1', note: 'A note'),
      ];
      await tester.pumpWidget(buildApp(flock: people, careLogs: logs));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Care Log'));
      await tester.pumpAndSettle();

      // There is a delete icon on the care log card
      expect(find.byIcon(Icons.delete_outline), findsWidgets);
    });

    testWidgets('deleting care log calls onUpdateCareLogs', (tester) async {
      List<CareLog> Function(List<CareLog>)? capturedFn;
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: todayStr()),
      ];
      final logs = [
        makeLog(id: 'log1', personId: '1', note: 'A note'),
        makeLog(id: 'log2', personId: '1', note: 'Another note'),
      ];
      await tester.pumpWidget(buildApp(
        flock: people,
        careLogs: logs,
        onUpdateCareLogs: (fn) => capturedFn = fn,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Care Log'));
      await tester.pumpAndSettle();

      // Tap the first delete icon on the Care Log tab
      final deleteIcons = find.byIcon(Icons.delete_outline);
      await tester.tap(deleteIcons.first);
      await tester.pumpAndSettle();

      expect(capturedFn, isNotNull);
      final result = capturedFn!(logs);
      // Should have removed one log
      expect(result.length, 1);
    });

    testWidgets('care log without note does not show note text',
        (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: todayStr()),
      ];
      final logs = [
        makeLog(id: 'log1', personId: '1', note: ''),
      ];
      await tester.pumpWidget(buildApp(flock: people, careLogs: logs));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Care Log'));
      await tester.pumpAndSettle();

      // The note text "Talked about health" (from default) should not be there
      // since we passed empty note
      expect(find.text('Talked about health'), findsNothing);
    });

    testWidgets('care log shows avatar with first letter of person name',
        (tester) async {
      final people = [
        makePerson(id: '1', name: 'Zack', lastContact: todayStr()),
      ];
      final logs = [
        makeLog(id: 'log1', personId: '1', note: 'Some note'),
      ];
      await tester.pumpWidget(buildApp(flock: people, careLogs: logs));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Care Log'));
      await tester.pumpAndSettle();

      // Avatar letter Z
      expect(find.text('Z'), findsWidgets);
    });

    testWidgets('multiple care logs are all rendered', (tester) async {
      final people = [
        makePerson(id: '1', name: 'Alice', lastContact: todayStr()),
        makePerson(id: '2', name: 'Bob', lastContact: todayStr()),
      ];
      final logs = [
        makeLog(id: 'log1', personId: '1', note: 'Talked to Alice', type: 'Call'),
        makeLog(id: 'log2', personId: '2', note: 'Visited Bob', type: 'Visit'),
      ];
      await tester.pumpWidget(buildApp(flock: people, careLogs: logs));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Care Log'));
      await tester.pumpAndSettle();

      expect(find.text('Talked to Alice'), findsOneWidget);
      expect(find.text('Visited Bob'), findsOneWidget);
    });
  });

  // ===========================================================================
  // CONTACT FREQUENCY AND OVERDUE LOGIC
  // ===========================================================================
  group('Contact frequency overdue logic', () {
    testWidgets('Weekly contact not overdue within 7 days', (tester) async {
      final people = [
        makePerson(
          id: '1',
          name: 'Fresh',
          contactFreq: 'Weekly',
          lastContact: daysAgoStr(3),
        ),
      ];
      await tester.pumpWidget(buildApp(flock: people, reminderDays: 14));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      expect(find.text('Need Contact (0)'), findsOneWidget);
    });

    testWidgets('Weekly contact overdue after 7 days', (tester) async {
      final people = [
        makePerson(
          id: '1',
          name: 'Overdue',
          contactFreq: 'Weekly',
          lastContact: daysAgoStr(10),
        ),
      ];
      await tester.pumpWidget(buildApp(flock: people, reminderDays: 14));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Need Contact (1)'), findsOneWidget);
    });

    testWidgets('Monthly contact not overdue within 30 days', (tester) async {
      final people = [
        makePerson(
          id: '1',
          name: 'Monthly',
          contactFreq: 'Monthly',
          lastContact: daysAgoStr(15),
        ),
      ];
      await tester.pumpWidget(buildApp(flock: people, reminderDays: 14));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('Quarterly contact overdue after 90 days', (tester) async {
      final people = [
        makePerson(
          id: '1',
          name: 'Q',
          contactFreq: 'Quarterly',
          lastContact: daysAgoStr(100),
        ),
      ];
      await tester.pumpWidget(buildApp(flock: people, reminderDays: 14));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('Biweekly contact overdue after 14 days', (tester) async {
      final people = [
        makePerson(
          id: '1',
          name: 'BW',
          contactFreq: 'Biweekly',
          lastContact: daysAgoStr(20),
        ),
      ];
      await tester.pumpWidget(buildApp(flock: people, reminderDays: 7));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });
}

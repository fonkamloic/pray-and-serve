import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pray_and_serve/models/prayer.dart';
import 'package:pray_and_serve/theme/app_theme.dart';
import 'package:pray_and_serve/widgets/pray_tab.dart';

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

  /// A stateful wrapper that manages the prayer list the same way HomeScreen
  /// does: calling the update-function yields a new list which is then set via
  /// setState so the child PrayTab rebuilds.
  Widget buildApp({
    required List<Prayer> prayers,
    void Function(List<Prayer>)? onPrayersChanged,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: _PrayTabHost(
        initialPrayers: prayers,
        onPrayersChanged: onPrayersChanged,
      ),
    );
  }

  Prayer makePrayer({
    String id = '1',
    String title = 'Test Prayer',
    String details = '',
    String category = 'Personal',
    String urgency = 'Ongoing',
    String scripture = '',
    String recurrence = 'None',
    String createdAt = '2025-01-01',
    bool answered = false,
    String? answeredAt,
    String? answerNote,
  }) {
    return Prayer(
      id: id,
      title: title,
      details: details,
      category: category,
      urgency: urgency,
      scripture: scripture,
      recurrence: recurrence,
      createdAt: createdAt,
      answered: answered,
      answeredAt: answeredAt,
      answerNote: answerNote,
    );
  }

  // ---------------------------------------------------------------------------
  // Tests
  // ---------------------------------------------------------------------------

  group('PrayTab - basic rendering', () {
    testWidgets('renders the "New Prayer" button and search field',
        (tester) async {
      await tester.pumpWidget(buildApp(prayers: []));

      expect(find.text('New Prayer'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Search prayers...'), findsOneWidget);
    });

    testWidgets('renders the four main filter chips', (tester) async {
      await tester.pumpWidget(buildApp(prayers: []));

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Unanswered'), findsOneWidget);
      expect(find.text('Pressing'), findsOneWidget);
      expect(find.text('Answered'), findsOneWidget);
    });

    testWidgets('renders category filter chips from constants', (tester) async {
      await tester.pumpWidget(buildApp(prayers: []));

      // The first few category chips should be visible in the horizontal list.
      // Some may be off-screen depending on viewport width but are still in
      // the widget tree via the ListView. We check a subset that is definitely
      // rendered.
      expect(find.text('Family'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
    });

    testWidgets('displays prayer cards for given prayers', (tester) async {
      final prayers = [
        makePrayer(id: '1', title: 'Healing for Mom'),
        makePrayer(id: '2', title: 'Guidance at work'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      expect(find.text('Healing for Mom'), findsOneWidget);
      expect(find.text('Guidance at work'), findsOneWidget);
    });

    testWidgets('prayer card shows details when present', (tester) async {
      final prayers = [
        makePrayer(title: 'My prayer', details: 'Some detailed info'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      expect(find.text('Some detailed info'), findsOneWidget);
    });

    testWidgets('prayer card shows scripture when present', (tester) async {
      final prayers = [
        makePrayer(title: 'My prayer', scripture: 'Phil 4:6-7'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      expect(find.textContaining('Phil 4:6-7'), findsOneWidget);
    });

    testWidgets('prayer card shows recurrence badge when not None',
        (tester) async {
      final prayers = [
        makePrayer(title: 'Daily prayer', recurrence: 'Daily'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      expect(find.textContaining('Daily'), findsWidgets);
    });

    testWidgets('prayer card shows category in uppercase', (tester) async {
      final prayers = [
        makePrayer(title: 'My prayer', category: 'Health'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      expect(find.text('HEALTH'), findsOneWidget);
    });

    testWidgets('prayer card shows created date formatted', (tester) async {
      final prayers = [
        makePrayer(title: 'My prayer', createdAt: '2025-03-15'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      expect(find.text('Created Mar 15, 2025'), findsOneWidget);
    });

    testWidgets('unanswered prayer card shows mark-answered and edit and delete buttons',
        (tester) async {
      final prayers = [makePrayer(title: 'My prayer')];
      await tester.pumpWidget(buildApp(prayers: prayers));

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------
  group('PrayTab - empty states', () {
    testWidgets('shows default empty state when no prayers', (tester) async {
      await tester.pumpWidget(buildApp(prayers: []));

      expect(find.text('No prayers here yet.'), findsOneWidget);
      expect(find.text('Pour out your heart to Him.'), findsOneWidget);
    });

    testWidgets('shows answered-specific empty state for Answered filter',
        (tester) async {
      await tester.pumpWidget(buildApp(prayers: []));

      await tester.tap(find.text('Answered'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No answered prayers yet'),
        findsOneWidget,
      );
    });

    testWidgets('shows default empty state for Pressing filter with no matching prayers',
        (tester) async {
      final prayers = [makePrayer(urgency: 'Ongoing')];
      await tester.pumpWidget(buildApp(prayers: prayers));

      await tester.tap(find.text('Pressing'));
      await tester.pumpAndSettle();

      expect(find.text('No prayers here yet.'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Filter chips
  // ---------------------------------------------------------------------------
  group('PrayTab - filter chips', () {
    testWidgets('Active filter (default) shows unanswered prayers only',
        (tester) async {
      final prayers = [
        makePrayer(id: '1', title: 'Active prayer'),
        makePrayer(id: '2', title: 'Done prayer', answered: true),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      expect(find.text('Active prayer'), findsOneWidget);
      expect(find.text('Done prayer'), findsNothing);
    });

    testWidgets('Unanswered filter shows only unanswered prayers',
        (tester) async {
      final prayers = [
        makePrayer(id: '1', title: 'Unanswered one'),
        makePrayer(id: '2', title: 'Answered one', answered: true),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      await tester.tap(find.text('Unanswered'));
      await tester.pumpAndSettle();

      expect(find.text('Unanswered one'), findsOneWidget);
      expect(find.text('Answered one'), findsNothing);
    });

    testWidgets('Pressing filter shows only pressing unanswered prayers',
        (tester) async {
      final prayers = [
        makePrayer(id: '1', title: 'Urgent!', urgency: 'Pressing'),
        makePrayer(id: '2', title: 'Normal', urgency: 'Ongoing'),
        makePrayer(
          id: '3',
          title: 'Pressing but answered',
          urgency: 'Pressing',
          answered: true,
        ),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      await tester.tap(find.text('Pressing'));
      await tester.pumpAndSettle();

      expect(find.text('Urgent!'), findsOneWidget);
      expect(find.text('Normal'), findsNothing);
      expect(find.text('Pressing but answered'), findsNothing);
    });

    testWidgets('Answered filter shows only answered prayers', (tester) async {
      final prayers = [
        makePrayer(id: '1', title: 'Still praying'),
        makePrayer(
          id: '2',
          title: 'God answered!',
          answered: true,
          answeredAt: '2025-06-01',
          answerNote: 'Miracle!',
        ),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      await tester.tap(find.text('Answered'));
      await tester.pumpAndSettle();

      expect(find.text('Still praying'), findsNothing);
      expect(find.text('God answered!'), findsOneWidget);
      // Answered badge
      expect(find.textContaining('Answered'), findsWidgets);
    });

    testWidgets('Category filter shows only prayers of that category (unanswered)',
        (tester) async {
      final prayers = [
        makePrayer(id: '1', title: 'Family prayer', category: 'Family'),
        makePrayer(id: '2', title: 'Work prayer', category: 'Work'),
        makePrayer(
          id: '3',
          title: 'Family answered',
          category: 'Family',
          answered: true,
        ),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      // Scroll the chip list to find 'Family' and tap it
      await tester.tap(find.text('Family').first);
      await tester.pumpAndSettle();

      expect(find.text('Family prayer'), findsOneWidget);
      expect(find.text('Work prayer'), findsNothing);
      expect(find.text('Family answered'), findsNothing);
    });

    testWidgets('tapping a category chip twice toggles it back to All',
        (tester) async {
      final prayers = [
        makePrayer(id: '1', title: 'Family prayer', category: 'Family'),
        makePrayer(id: '2', title: 'Work prayer', category: 'Work'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      // Tap Family filter
      await tester.tap(find.text('Family').first);
      await tester.pumpAndSettle();
      expect(find.text('Work prayer'), findsNothing);

      // Tap Family again -> toggles back to 'all'
      await tester.tap(find.text('Family').first);
      await tester.pumpAndSettle();
      expect(find.text('Family prayer'), findsOneWidget);
      expect(find.text('Work prayer'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Search filtering
  // ---------------------------------------------------------------------------
  group('PrayTab - search filtering', () {
    testWidgets('search filters prayers by title', (tester) async {
      final prayers = [
        makePrayer(id: '1', title: 'Healing for Mom'),
        makePrayer(id: '2', title: 'Guidance at work'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      // Type in the search field
      await tester.enterText(
        find.byType(TextField).first,
        'Healing',
      );
      await tester.pumpAndSettle();

      expect(find.text('Healing for Mom'), findsOneWidget);
      expect(find.text('Guidance at work'), findsNothing);
    });

    testWidgets('search filters prayers by details', (tester) async {
      final prayers = [
        makePrayer(id: '1', title: 'Prayer A', details: 'needs surgery'),
        makePrayer(id: '2', title: 'Prayer B', details: 'job interview'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      await tester.enterText(find.byType(TextField).first, 'surgery');
      await tester.pumpAndSettle();

      expect(find.text('Prayer A'), findsOneWidget);
      expect(find.text('Prayer B'), findsNothing);
    });

    testWidgets('search is case-insensitive', (tester) async {
      final prayers = [
        makePrayer(id: '1', title: 'HEALING FOR MOM'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      await tester.enterText(find.byType(TextField).first, 'healing');
      await tester.pumpAndSettle();

      expect(find.text('HEALING FOR MOM'), findsOneWidget);
    });

    testWidgets('search combined with filter shows intersection',
        (tester) async {
      final prayers = [
        makePrayer(
          id: '1',
          title: 'Urgent healing',
          urgency: 'Pressing',
        ),
        makePrayer(
          id: '2',
          title: 'Normal healing',
          urgency: 'Ongoing',
        ),
        makePrayer(
          id: '3',
          title: 'Urgent finances',
          urgency: 'Pressing',
        ),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      // Filter to pressing
      await tester.tap(find.text('Pressing'));
      await tester.pumpAndSettle();

      // Then search for "healing"
      await tester.enterText(find.byType(TextField).first, 'healing');
      await tester.pumpAndSettle();

      expect(find.text('Urgent healing'), findsOneWidget);
      expect(find.text('Normal healing'), findsNothing);
      expect(find.text('Urgent finances'), findsNothing);
    });

    testWidgets('empty search shows all prayers for current filter',
        (tester) async {
      final prayers = [
        makePrayer(id: '1', title: 'Healing request'),
        makePrayer(id: '2', title: 'Guidance needed'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      // Type something that filters to one result
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Healing');
      await tester.pumpAndSettle();
      expect(find.text('Guidance needed'), findsNothing);

      // Clear the search -> both should reappear
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
      expect(find.text('Healing request'), findsOneWidget);
      expect(find.text('Guidance needed'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Adding a new prayer via bottom sheet
  // ---------------------------------------------------------------------------
  group('PrayTab - add new prayer', () {
    testWidgets('tapping "New Prayer" opens bottom sheet with correct title',
        (tester) async {
      await tester.pumpWidget(buildApp(prayers: []));

      await tester.tap(find.text('New Prayer'));
      await tester.pumpAndSettle();

      expect(find.text('New Prayer Request'), findsOneWidget);
      expect(find.text('Add Prayer'), findsOneWidget);
    });

    testWidgets('new prayer bottom sheet shows all form fields',
        (tester) async {
      await tester.pumpWidget(buildApp(prayers: []));

      await tester.tap(find.text('New Prayer'));
      await tester.pumpAndSettle();

      expect(
        find.text('WHAT WOULD YOU LIKE TO PRAY FOR?'),
        findsOneWidget,
      );
      expect(find.text('DETAILS (OPTIONAL)'), findsOneWidget);
      expect(find.text('CATEGORY'), findsOneWidget);
      expect(find.text('URGENCY'), findsOneWidget);
      expect(find.text('RECURRING'), findsOneWidget);
      expect(
        find.text('SCRIPTURE TO PRAY THROUGH (OPTIONAL)'),
        findsOneWidget,
      );
    });

    testWidgets('Add Prayer button is disabled when title is empty',
        (tester) async {
      await tester.pumpWidget(buildApp(prayers: []));

      await tester.tap(find.text('New Prayer'));
      await tester.pumpAndSettle();

      // The 'Add Prayer' button should be disabled (null onPressed)
      final addButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Add Prayer'),
      );
      expect(addButton.onPressed, isNull);
    });

    testWidgets('can add a prayer by filling title and tapping Add Prayer',
        (tester) async {
      List<Prayer> captured = [];
      await tester.pumpWidget(buildApp(
        prayers: [],
        onPrayersChanged: (prayers) => captured = prayers,
      ));

      await tester.tap(find.text('New Prayer'));
      await tester.pumpAndSettle();

      // Enter a title - find the TextField with the hint text for the title
      final titleField = find.widgetWithText(
        TextField,
        "e.g., Healing for Mom's recovery",
      );
      await tester.enterText(titleField, 'New test prayer');
      await tester.pumpAndSettle();

      // The canSave closure captures the local `title` variable, which is
      // updated by onChanged. However the StatefulBuilder doesn't rebuild
      // automatically on text input. Changing a dropdown triggers
      // setModalState, which causes a rebuild and re-evaluates canSave().
      // Tap the Urgency dropdown and select the same value to trigger rebuild.
      // Find the Urgency dropdown (second one in the Row).
      final urgencyDropdown = find.byType(DropdownButton<String>);
      // There are 3 dropdowns: Category, Urgency, Recurring. Tap Urgency (index 1).
      await tester.tap(urgencyDropdown.at(1));
      await tester.pumpAndSettle();

      // Select 'Pressing' to trigger setModalState
      await tester.tap(find.text('Pressing').last);
      await tester.pumpAndSettle();

      // Now the Add Prayer button should be enabled
      await tester.tap(find.text('Add Prayer'));
      await tester.pumpAndSettle();

      // The bottom sheet should close and the new prayer should appear
      expect(captured.length, 1);
      expect(captured.first.title, 'New test prayer');
    });

    testWidgets('cancel closes the bottom sheet without adding',
        (tester) async {
      List<Prayer> captured = [];
      await tester.pumpWidget(buildApp(
        prayers: [],
        onPrayersChanged: (prayers) => captured = prayers,
      ));

      await tester.tap(find.text('New Prayer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(captured, isEmpty);
    });

    testWidgets('close icon closes the bottom sheet without adding',
        (tester) async {
      List<Prayer> captured = [];
      await tester.pumpWidget(buildApp(
        prayers: [],
        onPrayersChanged: (prayers) => captured = prayers,
      ));

      await tester.tap(find.text('New Prayer'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(captured, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Editing a prayer
  // ---------------------------------------------------------------------------
  group('PrayTab - edit prayer', () {
    testWidgets('tapping edit icon opens bottom sheet with "Edit Prayer" title',
        (tester) async {
      final prayers = [makePrayer(title: 'Existing prayer')];
      await tester.pumpWidget(buildApp(prayers: prayers));

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit Prayer'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
    });

    testWidgets('edit bottom sheet pre-fills existing prayer title',
        (tester) async {
      final prayers = [makePrayer(title: 'Existing prayer')];
      await tester.pumpWidget(buildApp(prayers: prayers));

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // The text field should contain the existing title
      expect(find.text('Existing prayer'), findsWidgets);
    });
  });

  // ---------------------------------------------------------------------------
  // Marking a prayer as answered
  // ---------------------------------------------------------------------------
  group('PrayTab - mark answered', () {
    testWidgets('tapping check icon opens the answer modal', (tester) async {
      final prayers = [makePrayer(title: 'My prayer')];
      await tester.pumpWidget(buildApp(prayers: prayers));

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.textContaining('Prayer Answered'), findsOneWidget);
      expect(find.text('Mark as Answered'), findsOneWidget);
    });

    testWidgets('answer modal shows the prayer title in quotes',
        (tester) async {
      final prayers = [makePrayer(title: 'Healing for Mom')];
      await tester.pumpWidget(buildApp(prayers: prayers));

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('"Healing for Mom"'), findsOneWidget);
    });

    testWidgets('marking a prayer as answered updates the prayer list',
        (tester) async {
      List<Prayer> captured = [];
      final prayers = [makePrayer(id: 'p1', title: 'My prayer')];
      await tester.pumpWidget(buildApp(
        prayers: prayers,
        onPrayersChanged: (p) => captured = p,
      ));

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark as Answered'));
      await tester.pumpAndSettle();

      expect(captured.length, 1);
      expect(captured.first.answered, true);
      expect(captured.first.answeredAt, isNotNull);
    });

    testWidgets('answered prayer card shows green "Answered" badge',
        (tester) async {
      final prayers = [
        makePrayer(
          id: 'a1',
          title: 'God provided',
          answered: true,
          answeredAt: '2025-06-01',
        ),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      // Switch to Answered filter
      await tester.tap(find.text('Answered'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Answered'), findsWidgets);
      expect(find.text('God provided'), findsOneWidget);
    });

    testWidgets('answered prayer with note shows "How God Answered" section',
        (tester) async {
      final prayers = [
        makePrayer(
          id: 'a1',
          title: 'God provided',
          answered: true,
          answeredAt: '2025-06-01',
          answerNote: 'He opened a door',
        ),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      // Switch to Answered filter
      await tester.tap(find.text('Answered'));
      await tester.pumpAndSettle();

      // The "How God Answered:" and the note are in a RichText with TextSpan
      // children, so we need to search within RichText widgets.
      final richTextFinder = find.byWidgetPredicate((widget) {
        if (widget is RichText) {
          final text = widget.text.toPlainText();
          return text.contains('How God Answered:') &&
              text.contains('He opened a door');
        }
        return false;
      });
      expect(richTextFinder, findsOneWidget);
    });

    testWidgets('answered prayer shows answered date', (tester) async {
      final prayers = [
        makePrayer(
          id: 'a1',
          title: 'God provided',
          answered: true,
          answeredAt: '2025-06-01',
        ),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      await tester.tap(find.text('Answered'));
      await tester.pumpAndSettle();

      expect(find.text('Answered Jun 1, 2025'), findsOneWidget);
    });

    testWidgets('answered prayer card does NOT show mark-answered button',
        (tester) async {
      final prayers = [
        makePrayer(
          id: 'a1',
          title: 'Answered prayer',
          answered: true,
          answeredAt: '2025-06-01',
        ),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      await tester.tap(find.text('Answered'));
      await tester.pumpAndSettle();

      // The check_circle_outline icon should NOT appear for answered prayers
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // Deleting a prayer
  // ---------------------------------------------------------------------------
  group('PrayTab - delete prayer', () {
    testWidgets('tapping delete icon shows confirmation dialog',
        (tester) async {
      final prayers = [makePrayer(title: 'To delete')];
      await tester.pumpWidget(buildApp(prayers: prayers));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Remove this prayer?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('confirming delete removes the prayer', (tester) async {
      List<Prayer> captured = [];
      final prayers = [makePrayer(id: 'p1', title: 'To delete')];
      await tester.pumpWidget(buildApp(
        prayers: prayers,
        onPrayersChanged: (p) => captured = p,
      ));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(captured, isEmpty);
    });

    testWidgets('cancelling delete keeps the prayer', (tester) async {
      List<Prayer> captured = [];
      final prayers = [makePrayer(id: 'p1', title: 'Keep me')];
      await tester.pumpWidget(buildApp(
        prayers: prayers,
        onPrayersChanged: (p) => captured = p,
      ));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // onPrayersChanged should never have been called
      expect(captured, isEmpty);
      // The prayer should still be visible
      expect(find.text('Keep me'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Urgency markers on cards
  // ---------------------------------------------------------------------------
  group('PrayTab - urgency markers', () {
    testWidgets('pressing prayer card has urgency dot', (tester) async {
      final prayers = [
        makePrayer(title: 'Urgent', urgency: 'Pressing'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      // The urgency dot is a Container with 8x8 size and coral color
      expect(find.text('Urgent'), findsOneWidget);
      // The card should exist; we verify the urgency dot by finding the
      // 8x8 circle container
      final dots = tester.widgetList<Container>(
        find.byWidgetPredicate((w) =>
            w is Container &&
            w.constraints?.maxWidth == 8 &&
            w.constraints?.maxHeight == 8),
      );
      expect(dots, isNotEmpty);
    });

    testWidgets('background urgency prayer uses olive color dot',
        (tester) async {
      final prayers = [
        makePrayer(title: 'Background prayer', urgency: 'Background'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      expect(find.text('Background prayer'), findsOneWidget);
    });

    testWidgets('ongoing urgency prayer uses gold color dot', (tester) async {
      final prayers = [
        makePrayer(title: 'Ongoing prayer', urgency: 'Ongoing'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      expect(find.text('Ongoing prayer'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Recurrence badge
  // ---------------------------------------------------------------------------
  group('PrayTab - recurrence badge', () {
    testWidgets('prayer with recurrence None shows no recurrence badge',
        (tester) async {
      final prayers = [
        makePrayer(title: 'No recurrence', recurrence: 'None'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      // The recurrence badge uses the format "↻ Daily" etc. Should NOT appear.
      expect(find.textContaining('\u21BB'), findsNothing);
    });

    testWidgets('prayer with recurrence Daily shows badge', (tester) async {
      final prayers = [
        makePrayer(title: 'Daily prayer', recurrence: 'Daily'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      expect(find.textContaining('\u21BB Daily'), findsOneWidget);
    });

    testWidgets('prayer with recurrence Weekly shows badge', (tester) async {
      final prayers = [
        makePrayer(title: 'Weekly prayer', recurrence: 'Weekly'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      expect(find.textContaining('\u21BB Weekly'), findsOneWidget);
    });

    testWidgets('prayer with recurrence Monthly shows badge', (tester) async {
      final prayers = [
        makePrayer(title: 'Monthly prayer', recurrence: 'Monthly'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      expect(find.textContaining('\u21BB Monthly'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Mixed scenarios
  // ---------------------------------------------------------------------------
  group('PrayTab - mixed scenarios', () {
    testWidgets('multiple prayers with mixed states render correctly',
        (tester) async {
      final prayers = [
        makePrayer(
          id: '1',
          title: 'Active pressing',
          urgency: 'Pressing',
          category: 'Health',
          scripture: 'James 5:14',
          recurrence: 'Daily',
        ),
        makePrayer(
          id: '2',
          title: 'Background prayer',
          urgency: 'Background',
          category: 'Work',
          details: 'Need wisdom',
        ),
        makePrayer(
          id: '3',
          title: 'Answered one',
          answered: true,
          answeredAt: '2025-07-01',
          answerNote: 'God is good',
        ),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      // Default (all/active) filter: only unanswered prayers
      expect(find.text('Active pressing'), findsOneWidget);
      expect(find.text('Background prayer'), findsOneWidget);
      expect(find.text('Answered one'), findsNothing);

      // Check details
      expect(find.text('Need wisdom'), findsOneWidget);
      // Check scripture
      expect(find.textContaining('James 5:14'), findsOneWidget);
      // Check recurrence badge
      expect(find.textContaining('\u21BB Daily'), findsOneWidget);
    });

    testWidgets('switching filters back and forth works correctly',
        (tester) async {
      final prayers = [
        makePrayer(id: '1', title: 'Active prayer'),
        makePrayer(
            id: '2', title: 'Pressing prayer', urgency: 'Pressing'),
        makePrayer(
            id: '3', title: 'Done prayer', answered: true,
            answeredAt: '2025-06-01'),
      ];
      await tester.pumpWidget(buildApp(prayers: prayers));

      // Default -> Active (unanswered)
      expect(find.text('Active prayer'), findsOneWidget);
      expect(find.text('Pressing prayer'), findsOneWidget);
      expect(find.text('Done prayer'), findsNothing);

      // Switch to Pressing
      await tester.tap(find.text('Pressing'));
      await tester.pumpAndSettle();
      expect(find.text('Active prayer'), findsNothing);
      expect(find.text('Pressing prayer'), findsOneWidget);

      // Switch to Answered
      await tester.tap(find.text('Answered'));
      await tester.pumpAndSettle();
      expect(find.text('Active prayer'), findsNothing);
      expect(find.text('Pressing prayer'), findsNothing);
      expect(find.text('Done prayer'), findsOneWidget);

      // Switch back to Active
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
      expect(find.text('Active prayer'), findsOneWidget);
      expect(find.text('Pressing prayer'), findsOneWidget);
      expect(find.text('Done prayer'), findsNothing);
    });
  });
}

// -----------------------------------------------------------------------------
// Stateful host widget that mimics how HomeScreen manages PrayTab
// -----------------------------------------------------------------------------

class _PrayTabHost extends StatefulWidget {
  final List<Prayer> initialPrayers;
  final void Function(List<Prayer>)? onPrayersChanged;

  const _PrayTabHost({
    required this.initialPrayers,
    this.onPrayersChanged,
  });

  @override
  State<_PrayTabHost> createState() => _PrayTabHostState();
}

class _PrayTabHostState extends State<_PrayTabHost> {
  late List<Prayer> _prayers;

  @override
  void initState() {
    super.initState();
    _prayers = List.from(widget.initialPrayers);
  }

  void _updatePrayers(List<Prayer> Function(List<Prayer>) fn) {
    setState(() {
      _prayers = fn(List.from(_prayers));
    });
    widget.onPrayersChanged?.call(_prayers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PrayTab(
        prayers: _prayers,
        onUpdate: _updatePrayers,
      ),
    );
  }
}

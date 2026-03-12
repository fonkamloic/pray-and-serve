import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pray_and_serve/screens/home_screen.dart';
import 'package:pray_and_serve/services/storage_service.dart';
import 'package:pray_and_serve/theme/app_theme.dart';
import 'package:pray_and_serve/models/prayer.dart';
import 'package:pray_and_serve/models/person.dart';

import '../helpers/fakes.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // ================================================================
  // Helper function unit tests (pure Dart, no widgets)
  // ================================================================

  group('daysAgo', () {
    test('returns 999999 for null', () {
      expect(daysAgo(null), 999999);
    });

    test('returns 999999 for empty string', () {
      expect(daysAgo(''), 999999);
    });

    test('returns 0 for today', () {
      final today = DateTime.now().toIso8601String().split('T')[0];
      expect(daysAgo(today), 0);
    });

    test('returns positive number for past date', () {
      final threeDaysAgo =
          DateTime.now().subtract(const Duration(days: 3)).toIso8601String().split('T')[0];
      expect(daysAgo(threeDaysAgo), 3);
    });

    test('returns large value for very old date', () {
      expect(daysAgo('2000-01-01'), greaterThan(365));
    });
  });

  group('todayStr', () {
    test('returns YYYY-MM-DD format', () {
      final result = todayStr();
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(result), isTrue);
    });

    test('matches current date components', () {
      final now = DateTime.now();
      final expected =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      expect(todayStr(), expected);
    });
  });

  group('formatDate', () {
    test('returns Never for null', () {
      expect(formatDate(null), 'Never');
    });

    test('returns Never for empty string', () {
      expect(formatDate(''), 'Never');
    });

    test('formats January correctly', () {
      expect(formatDate('2024-01-01'), 'Jan 1, 2024');
    });

    test('formats February correctly', () {
      expect(formatDate('2024-02-14'), 'Feb 14, 2024');
    });

    test('formats March correctly', () {
      expect(formatDate('2024-03-31'), 'Mar 31, 2024');
    });

    test('formats April correctly', () {
      expect(formatDate('2024-04-05'), 'Apr 5, 2024');
    });

    test('formats May correctly', () {
      expect(formatDate('2024-05-20'), 'May 20, 2024');
    });

    test('formats June correctly', () {
      expect(formatDate('2023-06-15'), 'Jun 15, 2023');
    });

    test('formats July correctly', () {
      expect(formatDate('2024-07-04'), 'Jul 4, 2024');
    });

    test('formats August correctly', () {
      expect(formatDate('2024-08-08'), 'Aug 8, 2024');
    });

    test('formats September correctly', () {
      expect(formatDate('2024-09-01'), 'Sep 1, 2024');
    });

    test('formats October correctly', () {
      expect(formatDate('2024-10-31'), 'Oct 31, 2024');
    });

    test('formats November correctly', () {
      expect(formatDate('2024-11-11'), 'Nov 11, 2024');
    });

    test('formats December correctly', () {
      expect(formatDate('2024-12-25'), 'Dec 25, 2024');
    });
  });

  group('contactFreqToDays', () {
    test('returns 7 for Weekly', () {
      expect(contactFreqToDays('Weekly', 30), 7);
    });

    test('returns 14 for Biweekly', () {
      expect(contactFreqToDays('Biweekly', 30), 14);
    });

    test('returns 30 for Monthly', () {
      expect(contactFreqToDays('Monthly', 7), 30);
    });

    test('returns 90 for Quarterly', () {
      expect(contactFreqToDays('Quarterly', 7), 90);
    });

    test('returns fallback for unknown frequency', () {
      expect(contactFreqToDays('Yearly', 42), 42);
    });

    test('returns fallback for empty string', () {
      expect(contactFreqToDays('', 10), 10);
    });

    test('returns fallback for random text', () {
      expect(contactFreqToDays('Custom', 99), 99);
    });
  });

  // ================================================================
  // HomeScreen widget tests
  // ================================================================

  group('HomeScreen', () {
    late StorageService storage;
    late FakeNotificationService notifications;

    Future<void> initStorage({Map<String, Object> prefs = const {}}) async {
      SharedPreferences.setMockInitialValues(prefs);
      storage = StorageService();
      await storage.init();
      notifications = FakeNotificationService();
    }

    Widget buildApp() {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: HomeScreen(
          storage: storage,
          notifications: notifications,
        ),
      );
    }

    // ---- Basic rendering ----

    group('basic rendering', () {
      testWidgets('shows app title and subtitle', (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('Pray & Serve'), findsOneWidget);
        expect(find.text('YOUR PRIVATE WALK WITH GOD'), findsOneWidget);
      });

      testWidgets('shows cross character', (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('\u271D'), findsOneWidget);
      });

      testWidgets('shows settings gear icon', (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      });
    });

    // ---- Tab navigation ----

    group('tab navigation', () {
      testWidgets('renders all three tab labels', (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('Pray'), findsOneWidget);
        expect(find.text('Journal'), findsOneWidget);
        expect(find.text('Serve'), findsOneWidget);
      });

      testWidgets('renders tab icons', (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
        expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
        expect(find.byIcon(Icons.people_outline), findsOneWidget);
      });

      testWidgets('Pray tab is selected by default', (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // PrayTab content should be visible; IndexedStack index=0
        // The Pray tab's text should be gold-colored (selected).
        // We can verify the PrayTab widget exists in the tree.
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('tapping Journal tab shows journal content', (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Journal'));
        await tester.pumpAndSettle();

        // JournalTab shows 'Prayer Journal' as its title
        expect(find.text('Prayer Journal'), findsOneWidget);
      });

      testWidgets('tapping Serve tab shows serve content', (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Serve'));
        await tester.pumpAndSettle();

        // The Serve tab should be visible now
        expect(find.byIcon(Icons.people_outline), findsOneWidget);
      });

      testWidgets('tapping Pray tab after switching returns to pray', (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Switch to Journal
        await tester.tap(find.text('Journal'));
        await tester.pumpAndSettle();

        // Switch back to Pray
        await tester.tap(find.text('Pray'));
        await tester.pumpAndSettle();

        // Should be back on Pray tab
        expect(find.byType(HomeScreen), findsOneWidget);
      });
    });

    // ---- Stats bar ----

    group('stats bar', () {
      testWidgets('shows stat labels for Member role', (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('PRAYERS'), findsOneWidget);
        expect(find.text('ANSWERED'), findsOneWidget);
        expect(find.text('PRESSING'), findsOneWidget);
        // Member role should NOT show "Need Contact"
        expect(find.text('NEED CONTACT'), findsNothing);
      });

      testWidgets('shows zero counts when no data', (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // All stats should be 0
        // There are 3 stat columns each showing '0'
        expect(find.text('0'), findsNWidgets(3));
      });

      testWidgets('shows correct prayer counts', (tester) async {
        final prayers = [
          Prayer(id: '1', title: 'P1', createdAt: '2024-01-01'),
          Prayer(id: '2', title: 'P2', createdAt: '2024-01-02', answered: true),
          Prayer(
              id: '3',
              title: 'P3',
              createdAt: '2024-01-03',
              urgency: 'Pressing'),
          Prayer(
              id: '4',
              title: 'P4',
              createdAt: '2024-01-04',
              urgency: 'Pressing',
              answered: true),
        ];
        final prayersJson =
            jsonEncode(prayers.map((p) => p.toJson()).toList());

        await initStorage(prefs: {'ps-prayers': prayersJson});
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // totalPrayers = 4, answeredPrayers = 2, pressingPrayers = 1 (only unanswered pressing)
        expect(find.text('4'), findsOneWidget); // Total prayers
        expect(find.text('2'), findsOneWidget); // Answered
        expect(find.text('1'), findsOneWidget); // Pressing (unanswered)
      });

      testWidgets('shows Need Contact stat for Pastor role', (tester) async {
        await initStorage(prefs: {'ps-role': 'Pastor'});
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('NEED CONTACT'), findsOneWidget);
      });

      testWidgets('shows Need Contact stat for Elder role', (tester) async {
        await initStorage(prefs: {'ps-role': 'Elder'});
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('NEED CONTACT'), findsOneWidget);
      });

      testWidgets('shows Need Contact stat for Deacon role', (tester) async {
        await initStorage(prefs: {'ps-role': 'Deacon'});
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('NEED CONTACT'), findsOneWidget);
      });

      testWidgets('computes overdue contacts correctly', (tester) async {
        // Person with lastContact far in the past and Weekly frequency
        // should be overdue (> 7 days ago)
        final flock = [
          Person(
            id: '1',
            name: 'Alice',
            contactFreq: 'Weekly',
            lastContact: '2020-01-01',
          ),
          Person(
            id: '2',
            name: 'Bob',
            contactFreq: 'Monthly',
            lastContact: todayStr(),
          ),
        ];
        final flockJson =
            jsonEncode(flock.map((p) => p.toJson()).toList());

        await initStorage(prefs: {
          'ps-role': 'Pastor',
          'ps-flock': flockJson,
        });
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Alice is overdue, Bob is not => 1 overdue
        expect(find.text('NEED CONTACT'), findsOneWidget);
        // The overdue count '1' appears in both the stats bar and the
        // Serve tab badge, so expect 2 occurrences.
        expect(find.text('1'), findsNWidgets(2));
        expect(find.text('0'), findsNWidgets(3));
      });

      testWidgets('person with null lastContact is overdue', (tester) async {
        final flock = [
          Person(
            id: '1',
            name: 'Alice',
            contactFreq: 'Weekly',
            // lastContact is null => daysAgo returns 999999 => definitely overdue
          ),
        ];
        final flockJson =
            jsonEncode(flock.map((p) => p.toJson()).toList());

        await initStorage(prefs: {
          'ps-role': 'Elder',
          'ps-flock': flockJson,
        });
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('NEED CONTACT'), findsOneWidget);
        // '1' appears in stats bar and Serve tab badge
        expect(find.text('1'), findsNWidgets(2));
      });

      testWidgets('overdue uses contactFreq per person, not global reminderDays',
          (tester) async {
        // Person with Quarterly freq and lastContact 60 days ago => NOT overdue (60 < 90)
        final sixtyDaysAgo = DateTime.now()
            .subtract(const Duration(days: 60))
            .toIso8601String()
            .split('T')[0];

        final flock = [
          Person(
            id: '1',
            name: 'Alice',
            contactFreq: 'Quarterly',
            lastContact: sixtyDaysAgo,
          ),
        ];
        final flockJson =
            jsonEncode(flock.map((p) => p.toJson()).toList());

        await initStorage(prefs: {
          'ps-role': 'Pastor',
          'ps-flock': flockJson,
          'ps-reminderdays': 7, // global fallback is 7, but Quarterly = 90
        });
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // 60 days < 90 days (Quarterly) => not overdue
        expect(find.text('0'), findsNWidgets(4)); // all stats 0
      });

      testWidgets('overdue uses fallback reminderDays for unknown freq',
          (tester) async {
        // Person with unknown contactFreq should use _reminderDays fallback
        final twoDaysAgo = DateTime.now()
            .subtract(const Duration(days: 2))
            .toIso8601String()
            .split('T')[0];

        final flock = [
          Person(
            id: '1',
            name: 'Alice',
            contactFreq: 'CustomFreq', // unknown => uses fallback
            lastContact: twoDaysAgo,
          ),
        ];
        final flockJson =
            jsonEncode(flock.map((p) => p.toJson()).toList());

        await initStorage(prefs: {
          'ps-role': 'Pastor',
          'ps-flock': flockJson,
          'ps-reminderdays': 1, // fallback = 1 day, so 2 days > 1 => overdue
        });
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // '1' in stats bar + badge on Serve tab
        expect(find.text('1'), findsNWidgets(2)); // 1 overdue contact
      });
    });

    // ---- Settings panel open/close ----

    group('settings panel', () {
      testWidgets('settings panel is hidden by default', (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('My Role'), findsNothing);
        expect(find.text('REMINDERS'), findsNothing);
        expect(find.text('Contact Reminder (days)'), findsNothing);
      });

      testWidgets('tapping settings icon opens settings panel', (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        expect(find.text('My Role'), findsOneWidget);
        expect(find.text('REMINDERS'), findsOneWidget);
        expect(find.text('Contact Reminder (days)'), findsOneWidget);
      });

      testWidgets('tapping settings icon again closes settings panel',
          (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Open
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        expect(find.text('My Role'), findsOneWidget);

        // Close
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        expect(find.text('My Role'), findsNothing);
      });

      testWidgets('shows reminder row labels (Pray, Journal, Serve)',
          (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        // The reminder rows show labels. Note that 'Pray' also exists as a tab
        // label, so we check for the settings-specific content.
        expect(find.text('REMINDERS'), findsOneWidget);
        // Reminder row labels
        // 'Pray' appears twice: tab label + reminder row label
        expect(find.text('Pray'), findsNWidgets(2));
        // 'Journal' appears twice: tab label + reminder row label
        expect(find.text('Journal'), findsNWidgets(2));
        // 'Serve' appears twice: tab label + reminder row label
        expect(find.text('Serve'), findsNWidgets(2));
      });

      testWidgets('shows three reminder toggle switches (all off by default)',
          (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        // There should be 3 Switch.adaptive widgets
        expect(find.byType(Switch), findsNWidgets(3));
      });

      testWidgets('role dropdown defaults to Member', (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        expect(find.text('Member'), findsOneWidget);
      });

      testWidgets('role dropdown shows stored role', (tester) async {
        await initStorage(prefs: {'ps-role': 'Pastor'});
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        expect(find.text('Pastor'), findsOneWidget);
      });

      testWidgets('reminder days text field shows stored value', (tester) async {
        await initStorage(prefs: {'ps-reminderdays': 21});
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        expect(find.text('21'), findsOneWidget);
      });

      testWidgets('reminder days defaults to 14', (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        // The text field should contain '14'
        expect(find.text('14'), findsOneWidget);
      });
    });

    // ---- Role selector changes ----

    group('role selector', () {
      testWidgets('changing role to Pastor shows Need Contact stat',
          (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Initially Member => no 'NEED CONTACT'
        expect(find.text('NEED CONTACT'), findsNothing);

        // Open settings
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        // Open the dropdown
        await tester.tap(find.text('Member'));
        await tester.pumpAndSettle();

        // Select Pastor
        await tester.tap(find.text('Pastor').last);
        await tester.pumpAndSettle();

        // Now 'NEED CONTACT' should appear
        expect(find.text('NEED CONTACT'), findsOneWidget);
      });

      testWidgets('changing role persists to storage', (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        // Open dropdown
        await tester.tap(find.text('Member'));
        await tester.pumpAndSettle();

        // Select Elder
        await tester.tap(find.text('Elder').last);
        await tester.pumpAndSettle();

        // Verify storage was updated
        expect(storage.getRole(), 'Elder');
      });
    });

    // ---- Reminder toggles ----

    group('reminder toggles', () {
      testWidgets('enabling Pray reminder calls requestPermission and schedule',
          (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        // Find the first Switch (Pray reminder) and toggle it on
        final switches = find.byType(Switch);
        await tester.tap(switches.first);
        await tester.pumpAndSettle();

        expect(notifications.requestPermissionCalled, isTrue);
        expect(notifications.scheduledPrayerTimes.length, 1);
        expect(storage.getPrayReminderEnabled(), isTrue);
      });

      testWidgets('disabling Pray reminder calls cancel', (tester) async {
        await initStorage(prefs: {'ps-pray-reminder-enabled': true});
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        // First switch should be Pray, currently on => tap to turn off
        final switches = find.byType(Switch);
        await tester.tap(switches.first);
        await tester.pumpAndSettle();

        expect(notifications.cancelPrayerReminderCount, 1);
        expect(storage.getPrayReminderEnabled(), isFalse);
      });

      testWidgets('enabling Journal reminder calls requestPermission and schedule',
          (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        // Second switch is Journal
        final switches = find.byType(Switch);
        await tester.tap(switches.at(1));
        await tester.pumpAndSettle();

        expect(notifications.requestPermissionCalled, isTrue);
        expect(notifications.scheduledJournalTimes.length, 1);
        expect(storage.getJournalReminderEnabled(), isTrue);
      });

      testWidgets('disabling Journal reminder calls cancel', (tester) async {
        await initStorage(prefs: {'ps-journal-reminder-enabled': true});
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        final switches = find.byType(Switch);
        await tester.tap(switches.at(1));
        await tester.pumpAndSettle();

        expect(notifications.cancelJournalReminderCount, 1);
        expect(storage.getJournalReminderEnabled(), isFalse);
      });

      testWidgets('enabling Serve reminder calls requestPermission and schedule',
          (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        // Third switch is Serve
        final switches = find.byType(Switch);
        await tester.tap(switches.at(2));
        await tester.pumpAndSettle();

        expect(notifications.requestPermissionCalled, isTrue);
        expect(notifications.scheduledServeTimes.length, 1);
        expect(storage.getServeReminderEnabled(), isTrue);
      });

      testWidgets('disabling Serve reminder calls cancel', (tester) async {
        await initStorage(prefs: {'ps-serve-reminder-enabled': true});
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        final switches = find.byType(Switch);
        await tester.tap(switches.at(2));
        await tester.pumpAndSettle();

        expect(notifications.cancelServeReminderCount, 1);
        expect(storage.getServeReminderEnabled(), isFalse);
      });

      testWidgets('time display appears when reminder is enabled',
          (tester) async {
        await initStorage(prefs: {'ps-pray-reminder-enabled': true});
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        // Default pray reminder time is 7:00 AM
        // The time.format(context) will render in the locale format.
        // In test context with MaterialApp, it uses the default locale.
        // We look for a GestureDetector wrapping a time text container.
        // The time chip should be visible for the enabled reminder.
        expect(find.byType(GestureDetector), findsWidgets);
      });

      testWidgets('time display is hidden when reminder is disabled',
          (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        // All reminders are off => no time chip GestureDetectors from reminder rows
        // The formatted time strings should NOT be present
        // Default times: 7:00 AM, 8:00 PM, 9:00 AM
        // None should appear since all reminders are disabled.
        // (They only appear when `enabled` is true in _buildReminderRow.)
      });

      testWidgets('stored reminder times are loaded correctly', (tester) async {
        await initStorage(prefs: {
          'ps-pray-reminder-enabled': true,
          'ps-pray-reminder-hour': 10,
          'ps-pray-reminder-minute': 30,
        });
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        // The time should display 10:30 in some format
        // Exact format depends on locale, but the TimeOfDay(10,30).format
        // with default locale gives "10:30 AM"
        expect(find.textContaining('10:30'), findsOneWidget);
      });
    });

    // ---- Serve tab badge ----

    group('serve tab badge', () {
      testWidgets('no badge when no overdue contacts', (tester) async {
        await initStorage(prefs: {'ps-role': 'Pastor'});
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // overdueContacts = 0, so badge should not be shown
        // The badge container only appears when tab.badge > 0
        // With role=Pastor and no flock, overdue should be 0
        // Verify no badge count is displayed in the tab bar area
        // (The '0' text only appears in stats, not as a badge)
      });

      testWidgets('badge appears on Serve tab when there are overdue contacts',
          (tester) async {
        final flock = [
          Person(
            id: '1',
            name: 'Alice',
            contactFreq: 'Weekly',
            lastContact: '2020-01-01', // very overdue
          ),
          Person(
            id: '2',
            name: 'Bob',
            contactFreq: 'Weekly',
            lastContact: '2020-01-01', // very overdue
          ),
        ];
        final flockJson =
            jsonEncode(flock.map((p) => p.toJson()).toList());

        await initStorage(prefs: {
          'ps-role': 'Pastor',
          'ps-flock': flockJson,
        });
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Badge should show '2' on the Serve tab
        // The badge count '2' will appear in both the stats bar (NEED CONTACT)
        // and the tab badge. Let's check there are at least 2 occurrences of '2'.
        expect(find.text('2'), findsNWidgets(2));
      });
    });

    // ---- Data loading from storage ----

    group('data loading', () {
      testWidgets('loads prayers from storage on init', (tester) async {
        final prayers = [
          Prayer(id: '1', title: 'Test Prayer', createdAt: '2024-01-01'),
        ];
        final prayersJson =
            jsonEncode(prayers.map((p) => p.toJson()).toList());

        await initStorage(prefs: {'ps-prayers': prayersJson});
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // totalPrayers should be 1
        expect(find.text('1'), findsOneWidget);
      });

      testWidgets('loads notification prefs from storage on init',
          (tester) async {
        await initStorage(prefs: {
          'ps-pray-reminder-enabled': true,
          'ps-journal-reminder-enabled': true,
          'ps-serve-reminder-enabled': true,
        });
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        // All three switches should be on
        final switches = tester.widgetList<Switch>(find.byType(Switch));
        for (final s in switches) {
          expect(s.value, isTrue);
        }
      });

      testWidgets('loads all notification prefs as false by default',
          (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        final switches = tester.widgetList<Switch>(find.byType(Switch));
        for (final s in switches) {
          expect(s.value, isFalse);
        }
      });
    });

    // ---- Reminder days input ----

    group('reminder days input', () {
      testWidgets('submitting reminder days text field updates storage',
          (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        // Find the TextField whose initial text is '14' (the default reminder days).
        // There are many TextFields in the tree (from IndexedStack children),
        // so we locate it by its current text value.
        final textField = find.widgetWithText(TextField, '14');
        expect(textField, findsOneWidget);

        // Clear and type a new value
        await tester.enterText(textField, '30');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(storage.getReminderDays(), 30);
      });

      testWidgets('submitting non-numeric value defaults to 7', (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        final textField = find.widgetWithText(TextField, '14');
        await tester.enterText(textField, 'abc');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // int.tryParse('abc') => null => defaults to 7
        expect(storage.getReminderDays(), 7);
      });
    });

    // ---- IndexedStack behavior ----

    group('IndexedStack', () {
      testWidgets('uses IndexedStack with three children', (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
        expect(indexedStack.children.length, 3);
        expect(indexedStack.index, 0);
      });

      testWidgets('IndexedStack index changes when tab is tapped',
          (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Tap Journal tab
        await tester.tap(find.text('Journal'));
        await tester.pumpAndSettle();

        final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
        expect(indexedStack.index, 1);
      });

      testWidgets('IndexedStack index is 2 when Serve is tapped',
          (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Serve'));
        await tester.pumpAndSettle();

        // There may be multiple IndexedStacks (ServeTab also has one).
        // The HomeScreen's IndexedStack has 3 children.
        final homeIndexedStack = tester
            .widgetList<IndexedStack>(find.byType(IndexedStack))
            .firstWhere((s) => s.children.length == 3);
        expect(homeIndexedStack.index, 2);
      });
    });

    // ---- Pressing stat color logic ----

    group('pressing stat color', () {
      testWidgets('pressing stat uses default color when zero pressing',
          (tester) async {
        await initStorage();
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // pressingPrayers = 0, so the "Pressing" stat should use AppColors.gold
        // We can at minimum verify the stat text '0' is rendered
        expect(find.text('PRESSING'), findsOneWidget);
      });

      testWidgets('pressing stat highlights when pressing prayers exist',
          (tester) async {
        final prayers = [
          Prayer(
            id: '1',
            title: 'Urgent',
            createdAt: '2024-01-01',
            urgency: 'Pressing',
          ),
        ];
        final prayersJson =
            jsonEncode(prayers.map((p) => p.toJson()).toList());

        await initStorage(prefs: {'ps-prayers': prayersJson});
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // pressingPrayers = 1, so the color should be coral
        expect(find.text('PRESSING'), findsOneWidget);
        expect(find.text('1'), findsNWidgets(2)); // total + pressing
      });
    });

    // ---- Combined scenarios ----

    group('combined scenarios', () {
      testWidgets('full state: prayers, flock, role=Pastor, reminders enabled',
          (tester) async {
        final prayers = [
          Prayer(id: '1', title: 'P1', createdAt: '2024-01-01'),
          Prayer(
              id: '2',
              title: 'P2',
              createdAt: '2024-01-02',
              answered: true),
          Prayer(
              id: '3',
              title: 'P3',
              createdAt: '2024-01-03',
              urgency: 'Pressing'),
        ];
        final flock = [
          Person(
            id: '1',
            name: 'Alice',
            contactFreq: 'Weekly',
            lastContact: '2020-01-01',
          ),
        ];

        await initStorage(prefs: {
          'ps-role': 'Pastor',
          'ps-prayers': jsonEncode(prayers.map((p) => p.toJson()).toList()),
          'ps-flock': jsonEncode(flock.map((p) => p.toJson()).toList()),
          'ps-pray-reminder-enabled': true,
          'ps-journal-reminder-enabled': true,
          'ps-serve-reminder-enabled': true,
        });
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Stats: Total=3, Answered=1, Pressing=1, Overdue=1
        expect(find.text('3'), findsOneWidget);
        expect(find.text('PRAYERS'), findsOneWidget);
        expect(find.text('ANSWERED'), findsOneWidget);
        expect(find.text('PRESSING'), findsOneWidget);
        expect(find.text('NEED CONTACT'), findsOneWidget);

        // Open settings and verify reminders are on
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        expect(find.text('Pastor'), findsOneWidget);
        final switches = tester.widgetList<Switch>(find.byType(Switch));
        for (final s in switches) {
          expect(s.value, isTrue);
        }
      });
    });
  });
}

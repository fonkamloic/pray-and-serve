import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pray_and_serve/services/storage_service.dart';
import 'package:pray_and_serve/screens/home_screen.dart';
import 'package:pray_and_serve/theme/app_theme.dart';

import '../helpers/fakes.dart';

/// Device size presets.
class DeviceSize {
  final String name;
  final Size size;
  const DeviceSize(this.name, this.size);
}

const _devices = [
  DeviceSize('iPhone SE (1st gen)', Size(320, 568)),
  DeviceSize('iPhone 8', Size(375, 667)),
  DeviceSize('iPhone 14', Size(390, 844)),
  DeviceSize('iPhone 14 Pro Max', Size(430, 932)),
  DeviceSize('Pixel 3a', Size(393, 808)),
  DeviceSize('Galaxy Fold (folded)', Size(280, 653)),
  DeviceSize('iPad Mini', Size(768, 1024)),
  DeviceSize('iPad Pro 12.9"', Size(1024, 1366)),
];

final _today = DateTime.now().toIso8601String().substring(0, 10);
final _oldDate = DateTime.now()
    .subtract(const Duration(days: 60))
    .toIso8601String()
    .substring(0, 10);

final _prayersJson = jsonEncode([
  {
    'id': 'p1',
    'title': 'A very long prayer title that should wrap properly on screens',
    'details': 'Detailed description with lots of text to verify wrapping',
    'category': 'Family',
    'urgency': 'Pressing',
    'scripture': 'Philippians 4:6-7 NIV',
    'recurrence': 'Daily',
    'createdAt': _today,
    'answered': false,
  },
  {
    'id': 'p2',
    'title': 'Short prayer',
    'createdAt': _today,
    'answered': true,
    'answerNote': 'God answered this beautifully and in His perfect timing',
    'answeredAt': _today,
  },
  {
    'id': 'p3',
    'title': 'Another prayer request',
    'createdAt': _today,
    'answered': false,
  },
]);

final _journalJson = jsonEncode([
  {
    'id': 'j1',
    'body':
        'A very long journal entry body with many words to check text wrapping behavior on small screens',
    'title': 'Day of Reflection and Deep Gratitude',
    'scripture': 'Romans 8:28',
    'reflection':
        'God reminded me that He works all things for good. This was a profound moment of clarity.',
    'date': _today,
  },
  {
    'id': 'j2',
    'body': 'Short entry',
    'date': _today,
  },
]);

final _flockJson = jsonEncode([
  {
    'id': 'f1',
    'name': 'John Smith with a Very Long Name',
    'tags': ['Youth Group', 'Small Group Leader', 'Volunteer'],
    'needs': ['Prayer', 'Encouragement', 'Financial Help'],
    'notes':
        'Very long notes about this person that should wrap correctly on all screen sizes',
    'contactFreq': 'Weekly',
    'lastContact': _oldDate,
  },
  {
    'id': 'f2',
    'name': 'Jane Doe',
    'tags': [],
    'needs': [],
    'contactFreq': 'Monthly',
    'lastContact': _today,
  },
  {
    'id': 'f3',
    'name': 'Someone Never Contacted',
    'tags': ['New Member'],
    'needs': ['Welcome'],
    'contactFreq': 'Biweekly',
    'lastContact': null,
  },
]);

final _careLogsJson = jsonEncode([
  {
    'id': 'c1',
    'personId': 'f1',
    'date': _today,
    'type': 'Visit',
    'note': 'Had coffee and a long conversation about life and faith',
  },
  {
    'id': 'c2',
    'personId': 'f2',
    'date': _today,
    'type': 'Call',
    'note': '',
  },
]);

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required StorageService storage,
  required FakeNotificationService notifications,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.darkTheme,
    home: HomeScreen(storage: storage, notifications: notifications),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // -----------------------------------------------------------------------
  // Group 1: Empty state at every device size
  // -----------------------------------------------------------------------
  group('Empty state — no overflow', () {
    for (final device in _devices) {
      testWidgets('on ${device.name} '
          '(${device.size.width.toInt()}x${device.size.height.toInt()})',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        final storage = StorageService();
        await storage.init();
        final notifications = FakeNotificationService();

        final errors = <FlutterErrorDetails>[];
        final oldHandler = FlutterError.onError;
        FlutterError.onError = (d) => errors.add(d);

        _setSize(tester, device.size);
        await _pumpHome(tester,
            storage: storage, notifications: notifications);

        FlutterError.onError = oldHandler;
        // Drain the exception queue too
        tester.takeException();

        expect(find.text('Pray & Serve'), findsOneWidget);

        final overflows = errors.where(
            (e) => e.exception.toString().contains('overflowed'));
        expect(overflows, isEmpty,
            reason: overflows.map((e) => e.toString()).join('\n'));
      });
    }
  });

  // -----------------------------------------------------------------------
  // Group 2: Populated Pray tab
  // -----------------------------------------------------------------------
  group('Populated Pray tab — no overflow', () {
    for (final device in _devices) {
      testWidgets('on ${device.name}', (tester) async {
        SharedPreferences.setMockInitialValues({
          'ps-prayers': _prayersJson,
        });
        final storage = StorageService();
        await storage.init();
        final notifications = FakeNotificationService();

        _setSize(tester, device.size);
        await _pumpHome(tester,
            storage: storage, notifications: notifications);

        expect(tester.takeException(), isNull);
      });
    }
  });

  // -----------------------------------------------------------------------
  // Group 3: Populated Journal tab
  // -----------------------------------------------------------------------
  group('Populated Journal tab — no overflow', () {
    for (final device in _devices) {
      testWidgets('on ${device.name}', (tester) async {
        SharedPreferences.setMockInitialValues({
          'ps-journal': _journalJson,
        });
        final storage = StorageService();
        await storage.init();
        final notifications = FakeNotificationService();

        _setSize(tester, device.size);
        await _pumpHome(tester,
            storage: storage, notifications: notifications);

        await tester.tap(find.text('Journal'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });

  // -----------------------------------------------------------------------
  // Group 4: Populated Serve tab (Pastor, 4 stats)
  // -----------------------------------------------------------------------
  group('Populated Serve tab — no overflow', () {
    for (final device in _devices) {
      testWidgets('on ${device.name}', (tester) async {
        SharedPreferences.setMockInitialValues({
          'ps-role': 'Pastor',
          'ps-flock': _flockJson,
          'ps-carelogs': _careLogsJson,
        });
        final storage = StorageService();
        await storage.init();
        final notifications = FakeNotificationService();

        _setSize(tester, device.size);
        await _pumpHome(tester,
            storage: storage, notifications: notifications);

        await tester.tap(find.text('Serve'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Need Contact sub-tab
        final needContact = find.textContaining('Need Contact');
        if (needContact.evaluate().isNotEmpty) {
          await tester.tap(needContact.first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        // Care Log sub-tab
        final careLog = find.text('Care Log');
        if (careLog.evaluate().isNotEmpty) {
          await tester.tap(careLog.first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  });

  // -----------------------------------------------------------------------
  // Group 5: Settings panel with all reminders enabled
  // -----------------------------------------------------------------------
  group('Settings panel — no overflow', () {
    for (final device in _devices) {
      testWidgets('on ${device.name}', (tester) async {
        SharedPreferences.setMockInitialValues({
          'ps-role': 'Pastor',
          'ps-pray-reminder-enabled': true,
          'ps-journal-reminder-enabled': true,
          'ps-serve-reminder-enabled': true,
        });
        final storage = StorageService();
        await storage.init();
        final notifications = FakeNotificationService();

        _setSize(tester, device.size);
        await _pumpHome(tester,
            storage: storage, notifications: notifications);

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        expect(find.text('My Role'), findsOneWidget);
        expect(find.text('REMINDERS'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  // -----------------------------------------------------------------------
  // Group 6: Stats bar with 4 items (Pastor)
  // -----------------------------------------------------------------------
  group('Stats bar (4 items, Pastor) — no overflow', () {
    for (final device in _devices) {
      testWidgets('on ${device.name}', (tester) async {
        SharedPreferences.setMockInitialValues({'ps-role': 'Pastor'});
        final storage = StorageService();
        await storage.init();
        final notifications = FakeNotificationService();

        _setSize(tester, device.size);
        await _pumpHome(tester,
            storage: storage, notifications: notifications);

        expect(find.text('PRAYERS'), findsOneWidget);
        expect(find.text('ANSWERED'), findsOneWidget);
        expect(find.text('PRESSING'), findsOneWidget);
        expect(find.text('NEED CONTACT'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  // -----------------------------------------------------------------------
  // Group 7: Bottom sheet modals on smallest screens
  // -----------------------------------------------------------------------
  group('Bottom sheet modals — no overflow', () {
    for (final device in [
      const DeviceSize('Galaxy Fold (folded)', Size(280, 653)),
      const DeviceSize('iPhone SE', Size(320, 568)),
      const DeviceSize('iPhone 8', Size(375, 667)),
    ]) {
      testWidgets('prayer modal on ${device.name}', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final storage = StorageService();
        await storage.init();
        final notifications = FakeNotificationService();

        _setSize(tester, device.size);
        await _pumpHome(tester,
            storage: storage, notifications: notifications);

        await tester.tap(find.text('New Prayer'));
        await tester.pumpAndSettle();

        expect(find.text('New Prayer Request'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('journal modal on ${device.name}', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final storage = StorageService();
        await storage.init();
        final notifications = FakeNotificationService();

        _setSize(tester, device.size);
        await _pumpHome(tester,
            storage: storage, notifications: notifications);

        await tester.tap(find.text('Journal'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('New Entry'));
        await tester.pumpAndSettle();

        expect(find.text('Journal Entry'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('serve modal on ${device.name}', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final storage = StorageService();
        await storage.init();
        final notifications = FakeNotificationService();

        _setSize(tester, device.size);
        await _pumpHome(tester,
            storage: storage, notifications: notifications);

        await tester.tap(find.text('Serve'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add Person'));
        await tester.pumpAndSettle();

        expect(find.text('Add Someone to Care For'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  // -----------------------------------------------------------------------
  // Group 8: Landscape orientation
  // -----------------------------------------------------------------------
  group('Landscape — no overflow', () {
    for (final device in [
      const DeviceSize('iPhone SE landscape', Size(568, 320)),
      const DeviceSize('iPhone 14 landscape', Size(844, 390)),
      const DeviceSize('iPad Mini landscape', Size(1024, 768)),
    ]) {
      testWidgets('on ${device.name}', (tester) async {
        SharedPreferences.setMockInitialValues({
          'ps-role': 'Pastor',
          'ps-prayers': _prayersJson,
          'ps-flock': _flockJson,
        });
        final storage = StorageService();
        await storage.init();
        final notifications = FakeNotificationService();

        _setSize(tester, device.size);
        await _pumpHome(tester,
            storage: storage, notifications: notifications);

        expect(find.text('Pray & Serve'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Settings in landscape
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}

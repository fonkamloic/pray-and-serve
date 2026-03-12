import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pray_and_serve/main.dart';
import 'package:pray_and_serve/services/storage_service.dart';
import 'package:pray_and_serve/models/prayer.dart';
import 'package:pray_and_serve/models/journal_entry.dart';
import 'package:pray_and_serve/models/person.dart';

import '../test/helpers/fakes.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('Capture App Store screenshots', (tester) async {
    // Seed realistic sample data
    final prayers = [
      Prayer(
        id: '1',
        title: 'Guidance for career transition',
        details: 'Lord, guide my steps as I consider new opportunities.',
        category: 'Personal',
        urgency: 'Pressing',
        scripture: 'Proverbs 3:5-6',
        recurrence: 'Daily',
        createdAt: '2026-03-01',
      ),
      Prayer(
        id: '2',
        title: 'Healing for Mom\'s knee surgery',
        details: 'Surgery scheduled for next week.',
        category: 'Family',
        urgency: 'Urgent',
        scripture: 'Psalm 107:20',
        recurrence: 'None',
        createdAt: '2026-03-05',
      ),
      Prayer(
        id: '3',
        title: 'Youth group revival',
        details: 'Praying for renewed passion among our youth.',
        category: 'Church',
        urgency: 'Ongoing',
        scripture: 'Joel 2:28',
        recurrence: 'Weekly',
        createdAt: '2026-02-20',
      ),
      Prayer(
        id: '4',
        title: 'Peace in the midst of uncertainty',
        category: 'Personal',
        urgency: 'Ongoing',
        scripture: 'Philippians 4:6-7',
        recurrence: 'None',
        createdAt: '2026-02-15',
      ),
      Prayer(
        id: '5',
        title: 'Wisdom for small group leading',
        category: 'Church',
        urgency: 'Ongoing',
        scripture: 'James 1:5',
        recurrence: 'Weekly',
        createdAt: '2026-03-08',
      ),
      Prayer(
        id: '6',
        title: 'Provision for missions trip',
        details: 'Trusting God for the funds needed.',
        category: 'Church',
        urgency: 'Pressing',
        answered: true,
        answeredAt: '2026-03-10',
        answerNote: 'Full amount raised! God is faithful.',
        createdAt: '2026-01-15',
      ),
    ];

    final journal = [
      JournalEntry(
        id: '1',
        date: '2026-03-12',
        title: 'A morning of gratitude',
        body:
            'Woke up with a deep sense of thankfulness today. The sunrise reminded me of His mercies that are new every morning.',
        scripture: 'Lamentations 3:22-23',
        reflection: 'God\'s faithfulness sustains me even when I forget to notice.',
      ),
      JournalEntry(
        id: '2',
        date: '2026-03-10',
        title: 'Lessons from Sunday\'s sermon',
        body:
            'Pastor David spoke about surrendering control. It hit home — I\'ve been gripping too tightly to my plans.',
        scripture: 'Matthew 6:34',
      ),
      JournalEntry(
        id: '3',
        date: '2026-03-07',
        title: 'Prayer answered!',
        body:
            'The missions trip is fully funded. Every dollar came through at just the right time. God\'s timing is perfect.',
        reflection: 'When I look back, I see His hand in every detail.',
      ),
    ];

    final flock = [
      Person(
        id: '1',
        name: 'Sarah Johnson',
        notes: 'Going through a difficult season after her father\'s passing.',
        tags: ['Small Group A'],
        needs: ['Grief support', 'Meals'],
        contactFreq: 'Weekly',
        lastContact: '2026-03-10',
      ),
      Person(
        id: '2',
        name: 'David & Maria Chen',
        notes: 'New to the church. Looking for community.',
        tags: ['Newcomers'],
        needs: ['Welcome visit', 'Small group placement'],
        contactFreq: 'Biweekly',
        lastContact: '2026-03-05',
      ),
      Person(
        id: '3',
        name: 'James Williams',
        notes: 'Recovering from surgery. Homebound for 6 weeks.',
        tags: ['Small Group B'],
        needs: ['Hospital visit', 'Transportation'],
        contactFreq: 'Weekly',
        lastContact: '2026-02-20',
      ),
      Person(
        id: '4',
        name: 'Emily Rogers',
        notes: 'Preparing for baptism next month.',
        tags: ['Youth'],
        needs: ['Baptism prep'],
        contactFreq: 'Monthly',
        lastContact: '2026-03-01',
      ),
    ];

    SharedPreferences.setMockInitialValues({
      'ps-prayers': jsonEncode(prayers.map((p) => p.toJson()).toList()),
      'ps-journal': jsonEncode(journal.map((j) => j.toJson()).toList()),
      'ps-flock': jsonEncode(flock.map((f) => f.toJson()).toList()),
      'ps-carelogs': jsonEncode([]),
      'ps-role': 'Pastor',
      'ps-reminderdays': 14,
    });

    final storage = StorageService();
    await storage.init();
    final notifications = FakeNotificationService();

    await tester.pumpWidget(PrayAndServeApp(
      storage: storage,
      notifications: notifications,
    ));
    await tester.pumpAndSettle();

    // Screenshot 1: Pray tab with prayer list
    await binding.takeScreenshot('01_pray_tab');

    // Screenshot 2: Tap "New Prayer" to show bottom sheet
    await tester.tap(find.text('New Prayer'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02_new_prayer');

    // Close the bottom sheet
    await tester.tapAt(const Offset(10, 100));
    await tester.pumpAndSettle();

    // Screenshot 3: Journal tab
    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('03_journal_tab');

    // Screenshot 4: Serve tab
    await tester.tap(find.text('Serve'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('04_serve_tab');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pray_and_serve/models/journal_entry.dart';

void main() {
  group('JournalEntry', () {
    group('constructor defaults', () {
      test('applies default values for optional fields', () {
        final entry = JournalEntry(id: '1', date: '2026-01-01');

        expect(entry.id, '1');
        expect(entry.date, '2026-01-01');
        expect(entry.title, '');
        expect(entry.body, '');
        expect(entry.scripture, '');
        expect(entry.reflection, '');
      });
    });

    group('constructor with all fields', () {
      test('sets every field when provided', () {
        final entry = JournalEntry(
          id: '2',
          date: '2026-03-12',
          title: 'Morning Devotion',
          body: 'Spent time in prayer and worship.',
          scripture: 'Psalm 119:105',
          reflection: 'God is faithful.',
        );

        expect(entry.id, '2');
        expect(entry.date, '2026-03-12');
        expect(entry.title, 'Morning Devotion');
        expect(entry.body, 'Spent time in prayer and worship.');
        expect(entry.scripture, 'Psalm 119:105');
        expect(entry.reflection, 'God is faithful.');
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final entry = JournalEntry(id: '3', date: '2026-02-01');
        final json = entry.toJson();

        expect(json['id'], '3');
        expect(json['date'], '2026-02-01');
        expect(json['title'], '');
        expect(json['body'], '');
        expect(json['scripture'], '');
        expect(json['reflection'], '');
      });

      test('serializes non-default values', () {
        final entry = JournalEntry(
          id: '4',
          date: '2026-04-01',
          title: 'Quiet Time',
          body: 'Read Romans 8.',
          scripture: 'Romans 8:28',
          reflection: 'All things work together for good.',
        );
        final json = entry.toJson();

        expect(json['title'], 'Quiet Time');
        expect(json['body'], 'Read Romans 8.');
        expect(json['scripture'], 'Romans 8:28');
        expect(json['reflection'], 'All things work together for good.');
      });
    });

    group('fromJson', () {
      test('deserializes a fully populated JSON map', () {
        final json = {
          'id': '10',
          'date': '2026-05-01',
          'title': 'Sabbath Rest',
          'body': 'A day of rest and worship.',
          'scripture': 'Genesis 2:3',
          'reflection': 'Rest is a gift.',
        };

        final entry = JournalEntry.fromJson(json);

        expect(entry.id, '10');
        expect(entry.date, '2026-05-01');
        expect(entry.title, 'Sabbath Rest');
        expect(entry.body, 'A day of rest and worship.');
        expect(entry.scripture, 'Genesis 2:3');
        expect(entry.reflection, 'Rest is a gift.');
      });

      test('applies defaults when optional fields are missing', () {
        final json = {
          'id': '11',
          'date': '2026-06-01',
        };

        final entry = JournalEntry.fromJson(json);

        expect(entry.title, '');
        expect(entry.body, '');
        expect(entry.scripture, '');
        expect(entry.reflection, '');
      });

      test('applies defaults when optional fields are explicitly null', () {
        final json = {
          'id': '12',
          'date': '2026-07-01',
          'title': null,
          'body': null,
          'scripture': null,
          'reflection': null,
        };

        final entry = JournalEntry.fromJson(json);

        expect(entry.title, '');
        expect(entry.body, '');
        expect(entry.scripture, '');
        expect(entry.reflection, '');
      });
    });

    group('toJson / fromJson round-trip', () {
      test('round-trips an entry with defaults', () {
        final original = JournalEntry(id: '20', date: '2026-08-01');
        final restored = JournalEntry.fromJson(original.toJson());

        expect(restored.id, original.id);
        expect(restored.date, original.date);
        expect(restored.title, original.title);
        expect(restored.body, original.body);
        expect(restored.scripture, original.scripture);
        expect(restored.reflection, original.reflection);
      });

      test('round-trips a fully populated entry', () {
        final original = JournalEntry(
          id: '21',
          date: '2026-09-01',
          title: 'Testimony',
          body: 'God answered my prayer today.',
          scripture: 'Philippians 4:6',
          reflection: 'Do not be anxious about anything.',
        );
        final restored = JournalEntry.fromJson(original.toJson());

        expect(restored.id, original.id);
        expect(restored.date, original.date);
        expect(restored.title, original.title);
        expect(restored.body, original.body);
        expect(restored.scripture, original.scripture);
        expect(restored.reflection, original.reflection);
      });
    });

    group('mutable fields', () {
      test('allows updating mutable fields', () {
        final entry = JournalEntry(id: '30', date: '2026-10-01');

        entry.date = '2026-10-02';
        entry.title = 'Updated';
        entry.body = 'New body';
        entry.scripture = 'John 3:16';
        entry.reflection = 'God so loved the world.';

        expect(entry.date, '2026-10-02');
        expect(entry.title, 'Updated');
        expect(entry.body, 'New body');
        expect(entry.scripture, 'John 3:16');
        expect(entry.reflection, 'God so loved the world.');
      });
    });
  });
}

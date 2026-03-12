import 'package:flutter_test/flutter_test.dart';
import 'package:pray_and_serve/models/prayer.dart';

void main() {
  group('Prayer', () {
    group('constructor defaults', () {
      test('applies default values for optional fields', () {
        final prayer = Prayer(
          id: '1',
          title: 'Test Prayer',
          createdAt: '2026-01-01',
        );

        expect(prayer.id, '1');
        expect(prayer.title, 'Test Prayer');
        expect(prayer.details, '');
        expect(prayer.category, 'Personal');
        expect(prayer.urgency, 'Ongoing');
        expect(prayer.scripture, '');
        expect(prayer.recurrence, 'None');
        expect(prayer.createdAt, '2026-01-01');
        expect(prayer.answered, false);
        expect(prayer.answeredAt, isNull);
        expect(prayer.answerNote, isNull);
      });
    });

    group('constructor with all fields', () {
      test('sets every field when provided', () {
        final prayer = Prayer(
          id: '42',
          title: 'Healing',
          details: 'Pray for healing',
          category: 'Health',
          urgency: 'Pressing',
          scripture: 'James 5:16',
          recurrence: 'Daily',
          createdAt: '2026-03-01',
          answered: true,
          answeredAt: '2026-03-10',
          answerNote: 'Healed completely',
        );

        expect(prayer.id, '42');
        expect(prayer.title, 'Healing');
        expect(prayer.details, 'Pray for healing');
        expect(prayer.category, 'Health');
        expect(prayer.urgency, 'Pressing');
        expect(prayer.scripture, 'James 5:16');
        expect(prayer.recurrence, 'Daily');
        expect(prayer.createdAt, '2026-03-01');
        expect(prayer.answered, true);
        expect(prayer.answeredAt, '2026-03-10');
        expect(prayer.answerNote, 'Healed completely');
      });
    });

    group('toJson', () {
      test('serializes all fields including nulls', () {
        final prayer = Prayer(
          id: '1',
          title: 'Test',
          createdAt: '2026-01-01',
        );
        final json = prayer.toJson();

        expect(json['id'], '1');
        expect(json['title'], 'Test');
        expect(json['details'], '');
        expect(json['category'], 'Personal');
        expect(json['urgency'], 'Ongoing');
        expect(json['scripture'], '');
        expect(json['recurrence'], 'None');
        expect(json['createdAt'], '2026-01-01');
        expect(json['answered'], false);
        expect(json['answeredAt'], isNull);
        expect(json['answerNote'], isNull);
      });

      test('serializes answered prayer with all nullable fields', () {
        final prayer = Prayer(
          id: '2',
          title: 'Answered',
          createdAt: '2026-02-01',
          answered: true,
          answeredAt: '2026-02-15',
          answerNote: 'God is good',
        );
        final json = prayer.toJson();

        expect(json['answered'], true);
        expect(json['answeredAt'], '2026-02-15');
        expect(json['answerNote'], 'God is good');
      });
    });

    group('fromJson', () {
      test('deserializes a fully populated JSON map', () {
        final json = {
          'id': '10',
          'title': 'Full Prayer',
          'details': 'All details',
          'category': 'Family',
          'urgency': 'Pressing',
          'scripture': 'Psalm 23:1',
          'recurrence': 'Weekly',
          'createdAt': '2026-05-01',
          'answered': true,
          'answeredAt': '2026-05-10',
          'answerNote': 'Peace received',
        };

        final prayer = Prayer.fromJson(json);

        expect(prayer.id, '10');
        expect(prayer.title, 'Full Prayer');
        expect(prayer.details, 'All details');
        expect(prayer.category, 'Family');
        expect(prayer.urgency, 'Pressing');
        expect(prayer.scripture, 'Psalm 23:1');
        expect(prayer.recurrence, 'Weekly');
        expect(prayer.createdAt, '2026-05-01');
        expect(prayer.answered, true);
        expect(prayer.answeredAt, '2026-05-10');
        expect(prayer.answerNote, 'Peace received');
      });

      test('applies defaults when optional fields are missing', () {
        final json = {
          'id': '11',
          'title': 'Minimal',
          'createdAt': '2026-06-01',
        };

        final prayer = Prayer.fromJson(json);

        expect(prayer.details, '');
        expect(prayer.category, 'Personal');
        expect(prayer.urgency, 'Ongoing');
        expect(prayer.scripture, '');
        expect(prayer.recurrence, 'None');
        expect(prayer.answered, false);
        expect(prayer.answeredAt, isNull);
        expect(prayer.answerNote, isNull);
      });

      test('applies defaults when optional fields are explicitly null', () {
        final json = {
          'id': '12',
          'title': 'Null fields',
          'createdAt': '2026-07-01',
          'details': null,
          'category': null,
          'urgency': null,
          'scripture': null,
          'recurrence': null,
          'answered': null,
          'answeredAt': null,
          'answerNote': null,
        };

        final prayer = Prayer.fromJson(json);

        expect(prayer.details, '');
        expect(prayer.category, 'Personal');
        expect(prayer.urgency, 'Ongoing');
        expect(prayer.scripture, '');
        expect(prayer.recurrence, 'None');
        expect(prayer.answered, false);
        expect(prayer.answeredAt, isNull);
        expect(prayer.answerNote, isNull);
      });
    });

    group('toJson / fromJson round-trip', () {
      test('round-trips a prayer with defaults', () {
        final original = Prayer(
          id: '20',
          title: 'Round Trip',
          createdAt: '2026-08-01',
        );
        final restored = Prayer.fromJson(original.toJson());

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.details, original.details);
        expect(restored.category, original.category);
        expect(restored.urgency, original.urgency);
        expect(restored.scripture, original.scripture);
        expect(restored.recurrence, original.recurrence);
        expect(restored.createdAt, original.createdAt);
        expect(restored.answered, original.answered);
        expect(restored.answeredAt, original.answeredAt);
        expect(restored.answerNote, original.answerNote);
      });

      test('round-trips a fully populated prayer', () {
        final original = Prayer(
          id: '21',
          title: 'Complete',
          details: 'Details here',
          category: 'Work',
          urgency: 'Background',
          scripture: 'Proverbs 3:5',
          recurrence: 'Monthly',
          createdAt: '2026-09-01',
          answered: true,
          answeredAt: '2026-09-15',
          answerNote: 'Promotion received',
        );
        final restored = Prayer.fromJson(original.toJson());

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.details, original.details);
        expect(restored.category, original.category);
        expect(restored.urgency, original.urgency);
        expect(restored.scripture, original.scripture);
        expect(restored.recurrence, original.recurrence);
        expect(restored.createdAt, original.createdAt);
        expect(restored.answered, original.answered);
        expect(restored.answeredAt, original.answeredAt);
        expect(restored.answerNote, original.answerNote);
      });
    });

    group('mutable fields', () {
      test('allows updating mutable string fields', () {
        final prayer = Prayer(
          id: '30',
          title: 'Mutable',
          createdAt: '2026-10-01',
        );

        prayer.title = 'Updated Title';
        prayer.details = 'New details';
        prayer.category = 'Health';
        prayer.urgency = 'Pressing';
        prayer.scripture = 'Romans 8:28';
        prayer.recurrence = 'Daily';
        prayer.createdAt = '2026-10-02';

        expect(prayer.title, 'Updated Title');
        expect(prayer.details, 'New details');
        expect(prayer.category, 'Health');
        expect(prayer.urgency, 'Pressing');
        expect(prayer.scripture, 'Romans 8:28');
        expect(prayer.recurrence, 'Daily');
        expect(prayer.createdAt, '2026-10-02');
      });

      test('allows updating answered status and related fields', () {
        final prayer = Prayer(
          id: '31',
          title: 'Answer Me',
          createdAt: '2026-11-01',
        );

        expect(prayer.answered, false);
        expect(prayer.answeredAt, isNull);
        expect(prayer.answerNote, isNull);

        prayer.answered = true;
        prayer.answeredAt = '2026-11-10';
        prayer.answerNote = 'Answered!';

        expect(prayer.answered, true);
        expect(prayer.answeredAt, '2026-11-10');
        expect(prayer.answerNote, 'Answered!');
      });

      test('allows setting nullable fields back to null', () {
        final prayer = Prayer(
          id: '32',
          title: 'Nullable',
          createdAt: '2026-12-01',
          answeredAt: '2026-12-05',
          answerNote: 'Note',
        );

        prayer.answeredAt = null;
        prayer.answerNote = null;

        expect(prayer.answeredAt, isNull);
        expect(prayer.answerNote, isNull);
      });
    });
  });
}

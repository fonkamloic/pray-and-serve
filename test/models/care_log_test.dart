import 'package:flutter_test/flutter_test.dart';
import 'package:pray_and_serve/models/care_log.dart';

void main() {
  group('CareLog', () {
    group('constructor defaults', () {
      test('applies default values for optional fields', () {
        final log = CareLog(
          id: '1',
          personId: 'p1',
          date: '2026-01-01',
        );

        expect(log.id, '1');
        expect(log.personId, 'p1');
        expect(log.date, '2026-01-01');
        expect(log.type, 'Call');
        expect(log.note, '');
      });
    });

    group('constructor with all fields', () {
      test('sets every field when provided', () {
        final log = CareLog(
          id: '2',
          personId: 'p2',
          date: '2026-03-12',
          type: 'Visit',
          note: 'Brought dinner to the family.',
        );

        expect(log.id, '2');
        expect(log.personId, 'p2');
        expect(log.date, '2026-03-12');
        expect(log.type, 'Visit');
        expect(log.note, 'Brought dinner to the family.');
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final log = CareLog(
          id: '3',
          personId: 'p3',
          date: '2026-02-01',
        );
        final json = log.toJson();

        expect(json['id'], '3');
        expect(json['personId'], 'p3');
        expect(json['date'], '2026-02-01');
        expect(json['type'], 'Call');
        expect(json['note'], '');
      });

      test('serializes non-default values', () {
        final log = CareLog(
          id: '4',
          personId: 'p4',
          date: '2026-04-01',
          type: 'Coffee',
          note: 'Caught up over coffee.',
        );
        final json = log.toJson();

        expect(json['type'], 'Coffee');
        expect(json['note'], 'Caught up over coffee.');
      });
    });

    group('fromJson', () {
      test('deserializes a fully populated JSON map', () {
        final json = {
          'id': '10',
          'personId': 'p10',
          'date': '2026-05-01',
          'type': 'Email',
          'note': 'Sent an encouraging message.',
        };

        final log = CareLog.fromJson(json);

        expect(log.id, '10');
        expect(log.personId, 'p10');
        expect(log.date, '2026-05-01');
        expect(log.type, 'Email');
        expect(log.note, 'Sent an encouraging message.');
      });

      test('applies defaults when optional fields are missing', () {
        final json = {
          'id': '11',
          'personId': 'p11',
          'date': '2026-06-01',
        };

        final log = CareLog.fromJson(json);

        expect(log.type, 'Call');
        expect(log.note, '');
      });

      test('applies defaults when optional fields are explicitly null', () {
        final json = {
          'id': '12',
          'personId': 'p12',
          'date': '2026-07-01',
          'type': null,
          'note': null,
        };

        final log = CareLog.fromJson(json);

        expect(log.type, 'Call');
        expect(log.note, '');
      });
    });

    group('toJson / fromJson round-trip', () {
      test('round-trips a care log with defaults', () {
        final original = CareLog(
          id: '20',
          personId: 'p20',
          date: '2026-08-01',
        );
        final restored = CareLog.fromJson(original.toJson());

        expect(restored.id, original.id);
        expect(restored.personId, original.personId);
        expect(restored.date, original.date);
        expect(restored.type, original.type);
        expect(restored.note, original.note);
      });

      test('round-trips a fully populated care log', () {
        final original = CareLog(
          id: '21',
          personId: 'p21',
          date: '2026-09-01',
          type: 'Prayer Together',
          note: 'Prayed for healing.',
        );
        final restored = CareLog.fromJson(original.toJson());

        expect(restored.id, original.id);
        expect(restored.personId, original.personId);
        expect(restored.date, original.date);
        expect(restored.type, original.type);
        expect(restored.note, original.note);
      });
    });

    group('mutable fields', () {
      test('allows updating mutable fields', () {
        final log = CareLog(
          id: '30',
          personId: 'p30',
          date: '2026-10-01',
        );

        log.date = '2026-10-02';
        log.type = 'Text';
        log.note = 'Sent a text message.';

        expect(log.date, '2026-10-02');
        expect(log.type, 'Text');
        expect(log.note, 'Sent a text message.');
      });
    });
  });
}

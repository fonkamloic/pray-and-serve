import 'package:flutter_test/flutter_test.dart';
import 'package:pray_and_serve/models/person.dart';

void main() {
  group('Person', () {
    group('constructor defaults', () {
      test('applies default values for optional fields', () {
        final person = Person(id: '1', name: 'Alice');

        expect(person.id, '1');
        expect(person.name, 'Alice');
        expect(person.notes, '');
        expect(person.tags, isEmpty);
        expect(person.needs, isEmpty);
        expect(person.contactFreq, 'Monthly');
        expect(person.lastContact, isNull);
      });
    });

    group('constructor with all fields', () {
      test('sets every field when provided', () {
        final person = Person(
          id: '2',
          name: 'Bob',
          notes: 'Good friend',
          tags: ['Grieving', 'Elderly'],
          needs: ['Meals', 'Prayer'],
          contactFreq: 'Weekly',
          lastContact: '2026-03-01',
        );

        expect(person.id, '2');
        expect(person.name, 'Bob');
        expect(person.notes, 'Good friend');
        expect(person.tags, ['Grieving', 'Elderly']);
        expect(person.needs, ['Meals', 'Prayer']);
        expect(person.contactFreq, 'Weekly');
        expect(person.lastContact, '2026-03-01');
      });
    });

    group('toJson', () {
      test('serializes all fields including null lastContact', () {
        final person = Person(id: '3', name: 'Carol');
        final json = person.toJson();

        expect(json['id'], '3');
        expect(json['name'], 'Carol');
        expect(json['notes'], '');
        expect(json['tags'], <String>[]);
        expect(json['needs'], <String>[]);
        expect(json['contactFreq'], 'Monthly');
        expect(json['lastContact'], isNull);
      });

      test('serializes lists and non-null lastContact', () {
        final person = Person(
          id: '4',
          name: 'Dan',
          tags: ['New Believer'],
          needs: ['Mentoring'],
          lastContact: '2026-02-15',
        );
        final json = person.toJson();

        expect(json['tags'], ['New Believer']);
        expect(json['needs'], ['Mentoring']);
        expect(json['lastContact'], '2026-02-15');
      });
    });

    group('fromJson', () {
      test('deserializes a fully populated JSON map', () {
        final json = {
          'id': '10',
          'name': 'Eve',
          'notes': 'Church member',
          'tags': ['Growing', 'Hospital'],
          'needs': ['Encouragement', 'Financial'],
          'contactFreq': 'Biweekly',
          'lastContact': '2026-01-20',
        };

        final person = Person.fromJson(json);

        expect(person.id, '10');
        expect(person.name, 'Eve');
        expect(person.notes, 'Church member');
        expect(person.tags, ['Growing', 'Hospital']);
        expect(person.needs, ['Encouragement', 'Financial']);
        expect(person.contactFreq, 'Biweekly');
        expect(person.lastContact, '2026-01-20');
      });

      test('applies defaults when optional fields are missing', () {
        final json = {
          'id': '11',
          'name': 'Frank',
        };

        final person = Person.fromJson(json);

        expect(person.notes, '');
        expect(person.tags, isEmpty);
        expect(person.needs, isEmpty);
        expect(person.contactFreq, 'Monthly');
        expect(person.lastContact, isNull);
      });

      test('applies defaults when optional fields are explicitly null', () {
        final json = {
          'id': '12',
          'name': 'Grace',
          'notes': null,
          'tags': null,
          'needs': null,
          'contactFreq': null,
          'lastContact': null,
        };

        final person = Person.fromJson(json);

        expect(person.notes, '');
        expect(person.tags, isEmpty);
        expect(person.needs, isEmpty);
        expect(person.contactFreq, 'Monthly');
        expect(person.lastContact, isNull);
      });
    });

    group('toJson / fromJson round-trip', () {
      test('round-trips a person with defaults', () {
        final original = Person(id: '20', name: 'Hank');
        final restored = Person.fromJson(original.toJson());

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.notes, original.notes);
        expect(restored.tags, original.tags);
        expect(restored.needs, original.needs);
        expect(restored.contactFreq, original.contactFreq);
        expect(restored.lastContact, original.lastContact);
      });

      test('round-trips a fully populated person', () {
        final original = Person(
          id: '21',
          name: 'Iris',
          notes: 'Needs follow-up',
          tags: ['Struggling', 'Needs Visit'],
          needs: ['Home Repair', 'Transportation'],
          contactFreq: 'Quarterly',
          lastContact: '2026-04-01',
        );
        final restored = Person.fromJson(original.toJson());

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.notes, original.notes);
        expect(restored.tags, original.tags);
        expect(restored.needs, original.needs);
        expect(restored.contactFreq, original.contactFreq);
        expect(restored.lastContact, original.lastContact);
      });
    });

    group('lists behavior', () {
      test('tags and needs are independent mutable lists', () {
        final person = Person(
          id: '30',
          name: 'Jack',
          tags: ['Elderly'],
          needs: ['Meals'],
        );

        person.tags = ['Elderly', 'Homebound'];
        person.needs = ['Meals', 'Hospital Visit'];

        expect(person.tags, ['Elderly', 'Homebound']);
        expect(person.needs, ['Meals', 'Hospital Visit']);
      });

      test('empty lists serialize and deserialize correctly', () {
        final person = Person(id: '31', name: 'Kate');
        final json = person.toJson();

        expect(json['tags'], <String>[]);
        expect(json['needs'], <String>[]);

        final restored = Person.fromJson(json);
        expect(restored.tags, isEmpty);
        expect(restored.needs, isEmpty);
      });
    });

    group('null lastContact', () {
      test('lastContact defaults to null', () {
        final person = Person(id: '40', name: 'Leo');
        expect(person.lastContact, isNull);
      });

      test('lastContact can be set and cleared', () {
        final person = Person(
          id: '41',
          name: 'Mia',
          lastContact: '2026-05-01',
        );
        expect(person.lastContact, '2026-05-01');

        person.lastContact = null;
        expect(person.lastContact, isNull);
      });

      test('null lastContact survives round-trip', () {
        final original = Person(id: '42', name: 'Nora');
        final restored = Person.fromJson(original.toJson());
        expect(restored.lastContact, isNull);
      });
    });
  });
}

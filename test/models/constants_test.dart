import 'package:flutter_test/flutter_test.dart';
import 'package:pray_and_serve/models/constants.dart';

void main() {
  group('constants', () {
    group('categories', () {
      test('is non-empty', () {
        expect(categories, isNotEmpty);
      });

      test('contains no duplicates', () {
        expect(categories.toSet().length, categories.length);
      });

      test('contains expected values', () {
        expect(categories, contains('Family'));
        expect(categories, contains('Health'));
        expect(categories, contains('Work'));
        expect(categories, contains('Spiritual Growth'));
        expect(categories, contains('World'));
        expect(categories, contains('Gratitude'));
        expect(categories, contains('Church'));
        expect(categories, contains('Personal'));
      });

      test('has exactly 8 entries', () {
        expect(categories.length, 8);
      });
    });

    group('urgencyLevels', () {
      test('is non-empty', () {
        expect(urgencyLevels, isNotEmpty);
      });

      test('contains no duplicates', () {
        expect(urgencyLevels.toSet().length, urgencyLevels.length);
      });

      test('contains expected values', () {
        expect(urgencyLevels, contains('Pressing'));
        expect(urgencyLevels, contains('Ongoing'));
        expect(urgencyLevels, contains('Background'));
      });

      test('has exactly 3 entries', () {
        expect(urgencyLevels.length, 3);
      });
    });

    group('roles', () {
      test('is non-empty', () {
        expect(roles, isNotEmpty);
      });

      test('contains no duplicates', () {
        expect(roles.toSet().length, roles.length);
      });

      test('contains expected values', () {
        expect(roles, contains('Member'));
        expect(roles, contains('Pastor'));
        expect(roles, contains('Elder'));
        expect(roles, contains('Deacon'));
      });

      test('has exactly 4 entries', () {
        expect(roles.length, 4);
      });
    });

    group('recurrenceOptions', () {
      test('is non-empty', () {
        expect(recurrenceOptions, isNotEmpty);
      });

      test('contains no duplicates', () {
        expect(recurrenceOptions.toSet().length, recurrenceOptions.length);
      });

      test('contains expected values', () {
        expect(recurrenceOptions, contains('None'));
        expect(recurrenceOptions, contains('Daily'));
        expect(recurrenceOptions, contains('Weekly'));
        expect(recurrenceOptions, contains('Monthly'));
      });

      test('has exactly 4 entries', () {
        expect(recurrenceOptions.length, 4);
      });
    });

    group('careTags', () {
      test('is non-empty', () {
        expect(careTags, isNotEmpty);
      });

      test('contains no duplicates', () {
        expect(careTags.toSet().length, careTags.length);
      });

      test('contains expected values', () {
        expect(careTags, contains('Grieving'));
        expect(careTags, contains('New Believer'));
        expect(careTags, contains('Struggling'));
        expect(careTags, contains('Growing'));
        expect(careTags, contains('Needs Visit'));
        expect(careTags, contains('Hospital'));
        expect(careTags, contains('Homebound'));
        expect(careTags, contains('Elderly'));
        expect(careTags, contains('Unsaved'));
      });

      test('has exactly 9 entries', () {
        expect(careTags.length, 9);
      });
    });

    group('needTypes', () {
      test('is non-empty', () {
        expect(needTypes, isNotEmpty);
      });

      test('contains no duplicates', () {
        expect(needTypes.toSet().length, needTypes.length);
      });

      test('contains expected values', () {
        expect(needTypes, contains('Meals'));
        expect(needTypes, contains('Transportation'));
        expect(needTypes, contains('Financial'));
        expect(needTypes, contains('Home Repair'));
        expect(needTypes, contains('Hospital Visit'));
        expect(needTypes, contains('Encouragement'));
        expect(needTypes, contains('Prayer'));
        expect(needTypes, contains('Mentoring'));
      });

      test('has exactly 8 entries', () {
        expect(needTypes.length, 8);
      });
    });

    group('contactTypes', () {
      test('is non-empty', () {
        expect(contactTypes, isNotEmpty);
      });

      test('contains no duplicates', () {
        expect(contactTypes.toSet().length, contactTypes.length);
      });

      test('contains expected values', () {
        expect(contactTypes, contains('Call'));
        expect(contactTypes, contains('Text'));
        expect(contactTypes, contains('Visit'));
        expect(contactTypes, contains('Coffee'));
        expect(contactTypes, contains('Email'));
        expect(contactTypes, contains('Prayer Together'));
      });

      test('has exactly 6 entries', () {
        expect(contactTypes.length, 6);
      });
    });

    group('contactFrequencies', () {
      test('is non-empty', () {
        expect(contactFrequencies, isNotEmpty);
      });

      test('contains no duplicates', () {
        expect(contactFrequencies.toSet().length, contactFrequencies.length);
      });

      test('contains expected values', () {
        expect(contactFrequencies, contains('Weekly'));
        expect(contactFrequencies, contains('Biweekly'));
        expect(contactFrequencies, contains('Monthly'));
        expect(contactFrequencies, contains('Quarterly'));
      });

      test('has exactly 4 entries', () {
        expect(contactFrequencies.length, 4);
      });
    });
  });
}

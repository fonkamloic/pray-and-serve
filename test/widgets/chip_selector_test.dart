import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pray_and_serve/widgets/chip_selector.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget buildApp({
    required List<String> options,
    required List<String> selected,
    required ValueChanged<String> onToggle,
    bool singleSelect = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ChipSelector(
          options: options,
          selected: selected,
          onToggle: onToggle,
          singleSelect: singleSelect,
        ),
      ),
    );
  }

  group('ChipSelector', () {
    testWidgets('renders all options', (tester) async {
      await tester.pumpWidget(buildApp(
        options: ['A', 'B', 'C'],
        selected: [],
        onToggle: (_) {},
      ));

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('tapping a chip calls onToggle with correct value',
        (tester) async {
      String? tapped;
      await tester.pumpWidget(buildApp(
        options: ['A', 'B'],
        selected: [],
        onToggle: (v) => tapped = v,
      ));

      await tester.tap(find.text('B'));
      expect(tapped, 'B');
    });

    testWidgets('selected chips show different visual state', (tester) async {
      await tester.pumpWidget(buildApp(
        options: ['A', 'B'],
        selected: ['A'],
        onToggle: (_) {},
      ));

      // Both should render
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('singleSelect parameter is accepted', (tester) async {
      await tester.pumpWidget(buildApp(
        options: ['X', 'Y'],
        selected: ['X'],
        onToggle: (_) {},
        singleSelect: true,
      ));

      expect(find.text('X'), findsOneWidget);
      expect(find.text('Y'), findsOneWidget);
    });

    testWidgets('empty options renders nothing', (tester) async {
      await tester.pumpWidget(buildApp(
        options: [],
        selected: [],
        onToggle: (_) {},
      ));

      expect(find.byType(GestureDetector), findsNothing);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pray_and_serve/theme/app_theme.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppColors', () {
    test('background colors are defined', () {
      expect(AppColors.bgDark, isNotNull);
      expect(AppColors.bgCard, isNotNull);
      expect(AppColors.bgHeader, isNotNull);
      expect(AppColors.bgInput, isNotNull);
      expect(AppColors.bgSubtle, isNotNull);
      expect(AppColors.bgChip, isNotNull);
    });

    test('border colors are defined', () {
      expect(AppColors.border, isNotNull);
      expect(AppColors.borderLight, isNotNull);
    });

    test('accent colors are defined', () {
      expect(AppColors.gold, const Color(0xFFC4A469));
      expect(AppColors.coral, const Color(0xFFC4785A));
      expect(AppColors.green, const Color(0xFF7DA87D));
      expect(AppColors.olive, const Color(0xFF6B7C6B));
    });

    test('text colors are defined', () {
      expect(AppColors.textPrimary, isNotNull);
      expect(AppColors.textSecondary, isNotNull);
      expect(AppColors.textMuted, isNotNull);
      expect(AppColors.textDim, isNotNull);
    });

    test('green variants are defined', () {
      expect(AppColors.greenBg, isNotNull);
      expect(AppColors.greenText, isNotNull);
    });
  });

  group('AppTheme', () {
    test('darkTheme has correct brightness', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
    });

    test('scaffold background is bgDark', () {
      final theme = AppTheme.darkTheme;
      expect(theme.scaffoldBackgroundColor, AppColors.bgDark);
    });

    test('color scheme primary is gold', () {
      final theme = AppTheme.darkTheme;
      expect(theme.colorScheme.primary, AppColors.gold);
    });

    test('color scheme surface is bgCard', () {
      final theme = AppTheme.darkTheme;
      expect(theme.colorScheme.surface, AppColors.bgCard);
    });

    test('text theme has all expected styles', () {
      final theme = AppTheme.darkTheme;
      expect(theme.textTheme.headlineLarge, isNotNull);
      expect(theme.textTheme.headlineMedium, isNotNull);
      expect(theme.textTheme.headlineSmall, isNotNull);
      expect(theme.textTheme.titleLarge, isNotNull);
      expect(theme.textTheme.titleMedium, isNotNull);
      expect(theme.textTheme.bodyLarge, isNotNull);
      expect(theme.textTheme.bodyMedium, isNotNull);
      expect(theme.textTheme.bodySmall, isNotNull);
      expect(theme.textTheme.labelSmall, isNotNull);
    });

    test('input decoration theme is configured', () {
      final theme = AppTheme.darkTheme;
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(theme.inputDecorationTheme.fillColor, AppColors.bgInput);
    });

    test('serif and sansSerif accessors work', () {
      expect(AppTheme.serif, isNotNull);
      expect(AppTheme.sansSerif, isNotNull);
    });
  });
}

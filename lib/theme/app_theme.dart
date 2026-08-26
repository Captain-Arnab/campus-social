import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// MiCampus design tokens — campus event ticket identity.
class AppColors {
  AppColors._();

  /// Primary accent (CTAs, active states) — NOT for background washes.
  static const Color accent = Color(0xFFFF5F15);
  static const Color accentLight = Color(0xFFFF9068);
  static const Color accentDark = Color(0xFFE04E0B);

  static const Color navy = Color(0xFF1A2233);
  static const Color navyMuted = Color(0xFF3D4A5C);
  static const Color cream = Color(0xFFF7F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0EDE8);

  static const Color teal = Color(0xFF2A9D8F);
  static const Color gold = Color(0xFFD4A853);
  static const Color indigo = Color(0xFF5B6CFF);

  static const Color textPrimary = navy;
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnAccent = Colors.white;
  static const Color border = Color(0xFFE5E0D8);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF2E7D32);

  static Color categoryColor(String? category) {
    final c = (category ?? '').toLowerCase().trim();
    if (c.contains('sport')) return teal;
    if (c.contains('cultural') || c.contains('music')) return gold;
    if (c.contains('tech') || c.contains('it')) return indigo;
    if (c.contains('academic')) return const Color(0xFF7C6CF0);
    if (c.contains('social')) return accent;
    return accent;
  }

  static IconData categoryIcon(String? category) {
    final c = (category ?? '').toLowerCase().trim();
    if (c.contains('sport')) return Icons.sports_basketball_rounded;
    if (c.contains('cultural') || c.contains('music')) return Icons.music_note_rounded;
    if (c.contains('tech') || c.contains('it')) return Icons.memory_rounded;
    if (c.contains('academic')) return Icons.menu_book_rounded;
    if (c.contains('social')) return Icons.groups_rounded;
    return Icons.confirmation_number_rounded;
  }
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  AppRadius._();
  static const double card = 20;
  static const double button = 12;
  static const double chip = 12;
  static const double sm = 8;
}

class AppShadows {
  AppShadows._();
  static List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.navy.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  static List<BoxShadow> cardLifted = [
    BoxShadow(
      color: AppColors.navy.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}

class AppTheme {
  AppTheme._();

  static TextTheme _buildTextTheme(TextTheme base) {
    final display = GoogleFonts.soraTextTheme(base);
    final body = GoogleFonts.interTextTheme(base);
    return TextTheme(
      displayLarge: display.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
        letterSpacing: -0.5,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
      ),
      displaySmall: display.displaySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
      ),
      titleLarge: display.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.navyMuted,
      ),
      bodyLarge: body.bodyLarge?.copyWith(color: AppColors.navy),
      bodyMedium: body.bodyMedium?.copyWith(color: AppColors.navyMuted),
      bodySmall: body.bodySmall?.copyWith(color: AppColors.textSecondary),
      labelLarge: body.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
      ),
      labelMedium: body.labelMedium?.copyWith(color: AppColors.textSecondary),
      labelSmall: body.labelSmall?.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      ),
    );
  }

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
        primary: AppColors.accent,
        onPrimary: Colors.white,
        surface: AppColors.cream,
        onSurface: AppColors.navy,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cream,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.navy,
        titleTextStyle: GoogleFonts.sora(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarContrastEnforced: false,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

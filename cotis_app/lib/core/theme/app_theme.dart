import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Colors (Electric Blue)
  static const primary = Color(0xFF2962FF);
  static const primaryDark = Color(0xFF0039CB);
  static const primaryLight = Color(0xFFE3F2FD);
  static const primaryMid = Color(0xFF2979FF);

  // Gradient Colors
  static const gradientStart = Color(0xFF2962FF);
  static const gradientEnd = Color(0xFF7C4DFF);

  // Status Colors
  static const success = Color(0xFF00C853);
  static const successLight = Color(0xFFE8F5E9);
  static const danger = Color(0xFFFF1744);
  static const dangerLight = Color(0xFFFFEBEE);
  static const warning = Color(0xFFFF9100);
  static const warningLight = Color(0xFFFFF3E0);

  // Light Theme Colors
  static const background = Color(0xFFF8F9FE);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF0F4F8);
  static const border = Color(0xFFE2E8F0);
  static const borderStrong = Color(0xFFCBD5E1);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);
  static const textInverse = Color(0xFFFFFFFF);

  // Dark Theme Colors
  static const backgroundDark = Color(0xFF0B0F19);
  static const surfaceDark = Color(0xFF131A2A);
  static const surface2Dark = Color(0xFF1E293B);
  static const borderDark = Color(0xFF334155);
  static const borderStrongDark = Color(0xFF475569);
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textSecondaryDark = Color(0xFF94A3B8);
  static const textTertiaryDark = Color(0xFF64748B);
}

class AppTheme {
  static TextStyle _displayStyle(
    double fontSize, {
    FontWeight fontWeight = FontWeight.w700,
    required Color color,
    double height = 1.1,
    double letterSpacing = -0.4,
  }) {
    return GoogleFonts.syne(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = isDark ? _darkScheme : _lightScheme;
    final textTheme = isDark ? _darkTextTheme : _lightTextTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? scheme.surface : AppColors.primary,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: _displayStyle(18, 
          fontWeight: FontWeight.w700, 
          color: isDark ? scheme.onSurface : AppColors.textInverse, 
          letterSpacing: -0.2
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 4,
          shadowColor: scheme.primary.withValues(alpha: 0.4),
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surface2Dark : AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant;
          return GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: color);
        }),
      ),
    );
  }

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.textInverse,
    primaryContainer: AppColors.primaryLight,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.primaryMid,
    onSecondary: AppColors.textInverse,
    surface: AppColors.background,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.border,
    outlineVariant: AppColors.borderStrong,
    error: AppColors.danger,
    onError: AppColors.textInverse,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryMid,
    onPrimary: AppColors.textInverse,
    primaryContainer: Color(0xFF1E2A4A),
    onPrimaryContainer: AppColors.primaryLight,
    secondary: AppColors.primaryLight,
    onSecondary: AppColors.primaryDark,
    surface: AppColors.backgroundDark,
    onSurface: AppColors.textPrimaryDark,
    onSurfaceVariant: AppColors.textSecondaryDark,
    outline: AppColors.borderDark,
    outlineVariant: AppColors.borderStrongDark,
    error: AppColors.danger,
    onError: AppColors.textInverse,
  );

  static TextTheme get _lightTextTheme => GoogleFonts.dmSansTextTheme().copyWith(
    displayLarge: _displayStyle(57, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
    displayMedium: _displayStyle(45, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    displaySmall: _displayStyle(36, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    headlineLarge: _displayStyle(32, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
    headlineMedium: _displayStyle(28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    headlineSmall: _displayStyle(24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    titleLarge: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    titleMedium: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    titleSmall: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    bodyLarge: GoogleFonts.dmSans(fontSize: 16, color: AppColors.textPrimary),
    bodyMedium: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
    bodySmall: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
    labelLarge: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    labelMedium: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
    labelSmall: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
  );

  static TextTheme get _darkTextTheme => GoogleFonts.dmSansTextTheme().copyWith(
    displayLarge: _displayStyle(57, fontWeight: FontWeight.w800, color: AppColors.textPrimaryDark),
    displayMedium: _displayStyle(45, fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
    displaySmall: _displayStyle(36, fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
    headlineLarge: _displayStyle(32, fontWeight: FontWeight.w800, color: AppColors.textPrimaryDark),
    headlineMedium: _displayStyle(28, fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
    headlineSmall: _displayStyle(24, fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
    titleLarge: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
    titleMedium: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
    titleSmall: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
    bodyLarge: GoogleFonts.dmSans(fontSize: 16, color: AppColors.textPrimaryDark),
    bodyMedium: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimaryDark),
    bodySmall: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondaryDark),
    labelLarge: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
    labelMedium: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryDark),
    labelSmall: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondaryDark),
  );
}

import 'package:flutter/material.dart';
import 'brand_colors.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: BrandColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: BrandColors.darkAccent,
        secondary: BrandColors.darkAccent,
        surface: BrandColors.darkGlassSurface,
        error: BrandColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: BrandColors.darkTextPrimary,
        outline: BrandColors.darkGlassBorder,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: BrandColors.darkTextPrimary),
        displayMedium: AppTypography.displayMedium.copyWith(color: BrandColors.darkTextPrimary),
        titleLarge: AppTypography.headingLarge.copyWith(color: BrandColors.darkTextPrimary),
        titleMedium: AppTypography.headingMedium.copyWith(color: BrandColors.darkTextPrimary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: BrandColors.darkTextPrimary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: BrandColors.darkTextSecondary),
        labelLarge: AppTypography.buttonText.copyWith(color: BrandColors.darkTextPrimary),
        labelSmall: AppTypography.metadata.copyWith(color: BrandColors.darkTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: BrandColors.darkTextPrimary),
        titleTextStyle: AppTypography.headingLarge.copyWith(color: BrandColors.darkTextPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BrandColors.darkGlassSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BrandColors.darkGlassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BrandColors.darkGlassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BrandColors.darkAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BrandColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BrandColors.error, width: 1.5),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(color: BrandColors.darkTextSecondary),
        hintStyle: AppTypography.bodyMedium.copyWith(color: BrandColors.darkTextSecondary),
      ),
      dividerTheme: const DividerThemeData(
        color: BrandColors.darkGlassBorder,
        space: 1,
        thickness: 1,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: BrandColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: BrandColors.lightAccent,
        secondary: BrandColors.lightAccent,
        surface: BrandColors.lightGlassSurface,
        error: BrandColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: BrandColors.lightTextPrimary,
        outline: BrandColors.lightGlassBorder,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: BrandColors.lightTextPrimary),
        displayMedium: AppTypography.displayMedium.copyWith(color: BrandColors.lightTextPrimary),
        titleLarge: AppTypography.headingLarge.copyWith(color: BrandColors.lightTextPrimary),
        titleMedium: AppTypography.headingMedium.copyWith(color: BrandColors.lightTextPrimary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: BrandColors.lightTextPrimary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: BrandColors.lightTextSecondary),
        labelLarge: AppTypography.buttonText.copyWith(color: BrandColors.lightTextPrimary),
        labelSmall: AppTypography.metadata.copyWith(color: BrandColors.lightTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: BrandColors.lightTextPrimary),
        titleTextStyle: AppTypography.headingLarge.copyWith(color: BrandColors.lightTextPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BrandColors.lightGlassSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BrandColors.lightGlassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BrandColors.lightGlassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BrandColors.lightAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BrandColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BrandColors.error, width: 1.5),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(color: BrandColors.lightTextSecondary),
        hintStyle: AppTypography.bodyMedium.copyWith(color: BrandColors.lightTextSecondary),
      ),
      dividerTheme: const DividerThemeData(
        color: BrandColors.lightGlassBorder,
        space: 1,
        thickness: 1,
      ),
    );
  }
}

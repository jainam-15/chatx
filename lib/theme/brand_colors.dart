import 'package:flutter/material.dart';

class BrandColors {
  BrandColors._();

  // Core Brand Colors from Logo
  static const Color brandBlue = Color(0xFF7FA1FF);
  static const Color brandPurple = Color(0xFFB584F5);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandBlue, brandPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark Mode Palette
  static const Color darkBackground = Color(0xFF09090B); // Very dark almost black
  static const Color darkGlassSurface = Color(0x1AFFFFFF); // 10% white for glass
  static const Color darkGlassBorder = Color(0x33FFFFFF); // 20% white for edge highlights
  static const Color darkAccent = brandPurple; 
  static const Color darkTextPrimary = Color(0xFFF4F4F5);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);

  // Light Mode Palette (Apple Premium)
  static const Color lightBackground = Color(0xFFF2F2F7); // iOS Secondary System Background
  static const Color lightGlassSurface = Color(0xB3FFFFFF); // 70% white for liquid glass
  static const Color lightGlassBorder = Color(0xE6FFFFFF); // 90% white for sharp edge highlights
  static const Color lightAccent = brandBlue;
  static const Color lightTextPrimary = Color(0xFF000000); // Pitch black
  static const Color lightTextSecondary = Color(0xFF8E8E93); // iOS System Gray

  // Common Semantic Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color error = Color(0xFFEF4444); // Rose
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color online = Color(0xFF10B981);
  static const Color offline = Color(0xFF6B7280);
}

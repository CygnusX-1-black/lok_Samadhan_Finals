import 'package:flutter/material.dart';

/// Govt of India Minimalist Color Palette
/// Clean, accessible, high contrast with National Emblem & Tricolor inspired accents.
class AppColors {
  // Primary Govt Colors
  static const Color navyDark = Color(0xFF0B192C);      // Ashoka Navy / Deep Govt Blue
  static const Color navyMedium = Color(0xFF1E3A8A);    // Secondary Navy
  static const Color navyLight = Color(0xFF3B82F6);     // Light Blue Accent
  
  // National Saffron / Warm Amber (Primary Call-To-Action & Voice Triggers)
  static const Color saffronPrimary = Color(0xFFE65100); // Deep Saffron
  static const Color saffronLight = Color(0xFFFF9800);   // Warm Amber / Highlight
  static const Color saffronBackground = Color(0xFFFFF3E0); // Soft Saffron Tint

  // India Emerald Green (Success, Verified, Resolved, SLA Compliant)
  static const Color emeraldPrimary = Color(0xFF1B5E20); // Deep India Green
  static const Color emeraldLight = Color(0xFF2E7D32);   // Green Accent
  static const Color emeraldBackground = Color(0xFFE8F5E9); // Soft Green Tint

  // Neutral Minimalist Surfaces & Backgrounds
  static const Color background = Color(0xFFF8FAFC);     // Soft Cream / Warm Slate Off-White
  static const Color surface = Color(0xFFFFFFFF);        // Pure White Card Surface
  static const Color surfaceSubtle = Color(0xFFF1F5F9);  // Subtle Secondary Card/Box Background
  static const Color cardBorder = Color(0xFFE2E8F0);     // Minimal Subtle Border

  // Typography & Text
  static const Color textPrimary = Color(0xFF0F172A);    // Slate Dark (Near Black)
  static const Color textSecondary = Color(0xFF475569);  // Slate Medium Gray
  static const Color textMuted = Color(0xFF94A3B8);      // Light Muted Gray

  // Alert & Escalation Colors
  static const Color warningRed = Color(0xFFDC2626);     // SLA Overdue / High Urgency
  static const Color errorRed = Color(0xFFDC2626);       // Form & validation errors
  static const Color warningRedBg = Color(0xFFFEF2F2);   // SLA Overdue Background
  static const Color amberOrange = Color(0xFFD97706);    // Medium Urgency / Warning
  static const Color amberOrangeBg = Color(0xFFFFFBEB);  // Amber Background
  static const Color purpleHitl = Color(0xFF7C3AED);     // HITL Review Queue Color
  static const Color purpleHitlBg = Color(0xFFF3E8FF);   // HITL Review Background
  static const Color emeraldDark = Color(0xFF1B5E20);    // Deep emerald green
}

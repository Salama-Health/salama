import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary brand (deep medical blue) ─────────────────────────────────
  static const Color primary         = Color(0xFF0F4C81);
  static const Color primaryDark     = Color(0xFF0A3A63);
  static const Color primaryMid      = Color(0xFF0D4372);
  static const Color primaryLight    = Color(0xFF3B7BB5);
  static const Color primaryLighter  = Color(0xFFCFE0EF);
  static const Color primarySurface  = Color(0xFFE7EFF7);
  static const Color primaryDeep     = Color(0xFF062742);

  // ── Backgrounds ───────────────────────────────────────────────────────
  static const Color background      = Color(0xFFF4F7FA);
  static const Color backgroundAlt   = Color(0xFFE9F0F6);
  static const Color cardBackground  = Color(0xFFFFFFFF);
  static const Color surfaceLight    = Color(0xFFFAFCFD);
  static const Color surfaceElevated = Color(0xFFEEF3F8);

  // ── Borders ───────────────────────────────────────────────────────────
  static const Color border          = Color(0x1A000000);
  static const Color borderMedium    = Color(0x26000000);
  static const Color borderStrong    = Color(0x40000000);
  static const Color borderLight     = Color(0x14000000);
  static const Color borderFocus     = primary;
  static const Color divider         = Color(0x14000000);

  // ── Text ──────────────────────────────────────────────────────────────
  static const Color textPrimary     = Color(0xFF0B1A26);
  static const Color textSecondary   = Color(0xFF43525E);
  static const Color textTertiary    = Color(0xFF7A8893);
  static const Color textMuted       = Color(0xFFA8B3BC);
  static const Color textOnPrimary   = Color(0xFFFFFFFF);

  // ── Status ────────────────────────────────────────────────────────────
  static const Color success         = Color(0xFF15803D);
  static const Color successMid      = Color(0xFF22C55E);
  static const Color successLight    = Color(0xFFDCFCE7);

  static const Color warning         = Color(0xFFB45309);
  static const Color warningMid      = Color(0xFFF59E0B);
  static const Color warningLight    = Color(0xFFFEF3C7);
  static const Color warningSurface  = Color(0xFFFEF6EC);

  static const Color error           = Color(0xFFB91C1C);
  static const Color errorMid        = Color(0xFFEF4444);
  static const Color errorLight      = Color(0xFFFEE2E2);

  static const Color info            = Color(0xFF1D4ED8);
  static const Color infoMid         = Color(0xFF3B82F6);
  static const Color infoLight       = Color(0xFFDBEAFE);

  static const Color accentPurple    = Color(0xFF7C3AED);
  static const Color accentPurpleLt  = Color(0xFFEDE9FE);

  static const Color neutral         = Color(0xFF4B5563);
  static const Color neutralSurface  = Color(0xFFF3F4F6);
  static const Color neutralBorder   = Color(0xFFD1D5DB);

  // ── Risk levels (immunization priority) ───────────────────────────────
  static const Color riskHigh        = Color(0xFFDC2626);
  static const Color riskHighLight   = Color(0xFFFEE2E2);
  static const Color riskMedium      = Color(0xFFEA580C);
  static const Color riskMediumLight = Color(0xFFFFEDD5);
  static const Color riskWatch       = Color(0xFFD97706);
  static const Color riskWatchLight  = Color(0xFFFEF3C7);
  static const Color riskLow         = Color(0xFF15803D);
  static const Color riskLowLight    = Color(0xFFDCFCE7);

  // ── Navigation ────────────────────────────────────────────────────────
  static const Color navActive       = primary;
  static const Color navInactive     = Color(0xFF8D9AA5);
  static const Color navBackground   = Color(0xFFFFFFFF);
  static const Color navBorder       = Color(0x1A000000);

  // ── Shadow ────────────────────────────────────────────────────────────
  static const Color shadowColor     = Color(0xFF062742);

  // ── Chart palette ─────────────────────────────────────────────────────
  static const Color chartBar1       = Color(0xFFAFC8DE);
  static const Color chartBar2       = Color(0xFF3B7BB5);
  static const Color chartBar3       = Color(0xFF0F4C81);
  static const Color chartLine       = Color(0xFF0F4C81);

  static const List<Color> chartPalette = [
    Color(0xFF0F4C81),
    Color(0xFF3B7BB5),
    Color(0xFFAFC8DE),
    Color(0xFFB45309),
    Color(0xFF1D4ED8),
    Color(0xFF15803D),
  ];

  // ── Gradients ─────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0A3A63), Color(0xFF1A6AAB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    colors: [Color(0xFF0F4C81), Color(0xFF1A6AAB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFE7EFF7), Color(0xFFF4F7FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFCFD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

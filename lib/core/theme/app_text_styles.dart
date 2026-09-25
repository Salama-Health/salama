import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography for Salama Health.
///
/// Every style is a lazily-initialised `static final`, not a getter: a getter
/// re-ran the GoogleFonts lookup and allocated a fresh TextStyle on every
/// access, and these are read dozens of times per frame in list rows. Resolving
/// each style once removes that work from the render path.
class AppTextStyles {
  AppTextStyles._();

  // ── Display ───────────────────────────────────────────────────────────
  static final TextStyle displayLarge = GoogleFonts.inter(
        fontSize: 28, fontWeight: FontWeight.w800,
        color: AppColors.textPrimary, height: 1.15, letterSpacing: -0.8,
      );

  static final TextStyle displayMedium = GoogleFonts.inter(
        fontSize: 24, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, height: 1.2, letterSpacing: -0.5,
      );

  // ── Headings ──────────────────────────────────────────────────────────
  static final TextStyle h1 = GoogleFonts.inter(
        fontSize: 17, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, height: 1.3, letterSpacing: -0.2,
      );

  static final TextStyle h2 = GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, height: 1.35, letterSpacing: -0.1,
      );

  static final TextStyle h3 = GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, height: 1.4,
      );

  static final TextStyle h4 = GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, height: 1.4,
      );

  // ── Body ──────────────────────────────────────────────────────────────
  static final TextStyle bodyLarge = GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary, height: 1.55,
      );

  static final TextStyle bodyMedium = GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary, height: 1.55,
      );

  static final TextStyle bodySmall = GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary, height: 1.5,
      );

  static final TextStyle bodySemibold = GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, height: 1.5,
      );

  static final TextStyle bodyLargeSemibold = GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, height: 1.5,
      );

  // ── Labels ────────────────────────────────────────────────────────────
  static final TextStyle labelLarge = GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: 0.0,
      );

  static final TextStyle labelMedium = GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary, letterSpacing: 0.1,
      );

  static final TextStyle labelSmall = GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary, letterSpacing: 0.15,
      );

  // ── Caption ───────────────────────────────────────────────────────────
  static final TextStyle caption = GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary, height: 1.4,
      );

  static final TextStyle captionMuted = GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: AppColors.textTertiary, height: 1.4,
      );

  // ── Buttons ───────────────────────────────────────────────────────────
  static final TextStyle buttonLarge = GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1,
        color: AppColors.textOnPrimary,
      );

  static final TextStyle buttonMedium = GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.1,
        color: AppColors.textOnPrimary,
      );

  // ── Scores / Numbers ──────────────────────────────────────────────────
  static final TextStyle statNumber = GoogleFonts.inter(
        fontSize: 34, fontWeight: FontWeight.w800,
        color: AppColors.textPrimary, height: 1.0, letterSpacing: -1.5,
      );

  static final TextStyle statNumberSmall = GoogleFonts.inter(
        fontSize: 22, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, height: 1.0, letterSpacing: -0.5,
      );

  static final TextStyle scoreMd = GoogleFonts.inter(
        fontSize: 22, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, height: 1.0, letterSpacing: -0.5,
      );

  static final TextStyle scoreSm = GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, height: 1.0, letterSpacing: -0.2,
      );

  static final TextStyle percentage = GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: AppColors.successMid, height: 1.2,
      );

  // ── Navigation ────────────────────────────────────────────────────────
  static final TextStyle navLabel = GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.1,
      );
}

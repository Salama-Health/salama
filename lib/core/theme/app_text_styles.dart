import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Display ───────────────────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 28, fontWeight: FontWeight.w800,
        color: AppColors.textPrimary, height: 1.15, letterSpacing: -0.8,
      );

  static TextStyle get displayMedium => GoogleFonts.inter(
        fontSize: 24, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, height: 1.2, letterSpacing: -0.5,
      );

  // ── Headings ──────────────────────────────────────────────────────────
  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 17, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, height: 1.3, letterSpacing: -0.2,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, height: 1.35, letterSpacing: -0.1,
      );

  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, height: 1.4,
      );

  static TextStyle get h4 => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, height: 1.4,
      );

  // ── Body ──────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary, height: 1.55,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary, height: 1.55,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary, height: 1.5,
      );

  static TextStyle get bodySemibold => GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, height: 1.5,
      );

  static TextStyle get bodyLargeSemibold => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, height: 1.5,
      );

  // ── Labels ────────────────────────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: 0.0,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary, letterSpacing: 0.1,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary, letterSpacing: 0.15,
      );

  // ── Caption ───────────────────────────────────────────────────────────
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary, height: 1.4,
      );

  static TextStyle get captionMuted => GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: AppColors.textTertiary, height: 1.4,
      );

  // ── Buttons ───────────────────────────────────────────────────────────
  static TextStyle get buttonLarge => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1,
        color: AppColors.textOnPrimary,
      );

  static TextStyle get buttonMedium => GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.1,
        color: AppColors.textOnPrimary,
      );

  // ── Scores / Numbers ──────────────────────────────────────────────────
  static TextStyle get statNumber => GoogleFonts.inter(
        fontSize: 34, fontWeight: FontWeight.w800,
        color: AppColors.textPrimary, height: 1.0, letterSpacing: -1.5,
      );

  static TextStyle get statNumberSmall => GoogleFonts.inter(
        fontSize: 22, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, height: 1.0, letterSpacing: -0.5,
      );

  static TextStyle get scoreMd => GoogleFonts.inter(
        fontSize: 22, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, height: 1.0, letterSpacing: -0.5,
      );

  static TextStyle get scoreSm => GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, height: 1.0, letterSpacing: -0.2,
      );

  static TextStyle get percentage => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: AppColors.successMid, height: 1.2,
      );

  // ── Navigation ────────────────────────────────────────────────────────
  static TextStyle get navLabel => GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.1,
      );
}

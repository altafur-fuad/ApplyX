import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// ApplyX design tokens — typography scale.
///
/// Source of truth: design.md § "Final typography"
///
/// Uses Inter via google_fonts. Falls back to system sans-serif
/// if the network font is unavailable.
class AppTypography {
  AppTypography._();

  static TextStyle _inter({
    required double fontSize,
    required FontWeight fontWeight,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ── Scale ─────────────────────────────────────────────────────────────

  /// Display — 34 / Extra Bold
  static TextStyle display({Color? color}) => _inter(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: color ?? AppColors.textPrimary,
        height: 1.2,
      );

  /// H1 — 30 / Bold
  static TextStyle h1({Color? color}) => _inter(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        height: 1.25,
      );

  /// H2 — 26 / Bold
  static TextStyle h2({Color? color}) => _inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        height: 1.3,
      );

  /// H3 — 20 / Semi Bold
  static TextStyle h3({Color? color}) => _inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
        height: 1.35,
      );

  /// Body — 16 / Regular
  static TextStyle body({Color? color}) => _inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textPrimary,
        height: 1.5,
      );

  /// Body Small — 14 / Regular
  static TextStyle bodySmall({Color? color}) => _inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textSecondary,
        height: 1.45,
      );

  /// Caption — 12 / Regular
  static TextStyle caption({Color? color}) => _inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textSecondary,
        height: 1.4,
      );

  /// Button — 15 / Semi Bold
  static TextStyle button({Color? color}) => _inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
        height: 1.2,
        letterSpacing: 0.2,
      );

  /// Label / Chip — 13 / Medium
  static TextStyle label({Color? color}) => _inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textSecondary,
        height: 1.3,
      );
}

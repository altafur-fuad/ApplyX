import 'dart:ui';

/// ApplyX design tokens — color palette.
///
/// Source of truth: design.md
/// These tokens must match the new warm visual language.
class AppColors {
  AppColors._();

  // ── Core palette ──────────────────────────────────────────────────────

  /// App background — warm cream
  static const Color background = Color(0xFFFFF9E8);

  /// Default card / container surface
  static const Color surface = Color(0xFFFFF6DC);

  /// Elevated card / sheet surface
  static const Color surfaceElevated = Color(0xFFFFF3D2);

  /// Primary brand accent — golden orange
  static const Color primary = Color(0xFFF2B65D);

  /// AI-state accent — warm yellow
  static const Color aiAccent = Color(0xFFF7C95E);

  /// Success — soft green
  static const Color success = Color(0xFF5E9C76);

  /// Warning / human-approval — golden orange
  static const Color warning = Color(0xFFEFAE58);

  /// Danger / error — soft peach/coral
  static const Color danger = Color(0xFFE58F6B);

  // ── Text ──────────────────────────────────────────────────────────────

  /// Primary text — warm dark brown
  static const Color textPrimary = Color(0xFF5A4635);

  /// Secondary / muted text
  static const Color textSecondary = Color(0xFF9A8875);

  // ── Borders ───────────────────────────────────────────────────────────

  /// Default border / divider
  static const Color border = Color(0xFFEEDCB6);

  // ── Agent state colors ────────────────────────────────────────────────
  // design.md: 

  /// Agent: actively running
  static const Color agentActive = aiAccent;

  /// Agent: completed
  static const Color agentCompleted = success;

  /// Agent: waiting for human approval
  static const Color agentApproval = warning;

  /// Agent: queued / inactive
  static const Color agentQueued = textSecondary;

  /// Agent: failed
  static const Color agentFailed = danger;

  /// Agent: cancelled
  static const Color agentCancelled = textSecondary;

  // ── Utility ───────────────────────────────────────────────────────────

  /// Transparent
  static const Color transparent = Color(0x00000000);

  /// White with opacity helpers
  static const Color white = Color(0xFFFFFFFF);
  static const Color white50 = Color(0x80FFFFFF);
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color white05 = Color(0x0DFFFFFF);
}

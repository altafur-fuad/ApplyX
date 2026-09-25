import 'dart:ui';

/// ApplyX design tokens — color palette.
///
/// Source of truth: design.md § "Final color tokens"
/// These tokens must match the approved Figma design.
/// Do not hard-code these values in widgets; use [AppColors] constants.
class AppColors {
  AppColors._();

  // ── Core palette ──────────────────────────────────────────────────────

  /// App background — darkest surface
  static const Color background = Color(0xFF0B0F14);

  /// Default card / container surface
  static const Color surface = Color(0xFF121821);

  /// Elevated card / sheet surface
  static const Color surfaceElevated = Color(0xFF18212C);

  /// Primary brand accent — purple
  static const Color primary = Color(0xFF7C5CFC);

  /// AI-state accent — cyan
  static const Color aiAccent = Color(0xFF39D9FF);

  /// Success — green
  static const Color success = Color(0xFF4ADE80);

  /// Warning / human-approval — amber
  static const Color warning = Color(0xFFFBBF24);

  /// Danger / error — rose
  static const Color danger = Color(0xFFFB7185);

  // ── Text ──────────────────────────────────────────────────────────────

  /// Primary text — near-white
  static const Color textPrimary = Color(0xFFF5F7FA);

  /// Secondary / muted text
  static const Color textSecondary = Color(0xFF9AA7B5);

  // ── Borders ───────────────────────────────────────────────────────────

  /// Default border / divider
  static const Color border = Color(0xFF263241);

  // ── Agent state colors ────────────────────────────────────────────────
  // design.md: cyan = active, green = completed, amber = approval, muted = queued

  /// Agent: actively running
  static const Color agentActive = aiAccent;

  /// Agent: completed
  static const Color agentCompleted = success;

  /// Agent: waiting for human approval
  static const Color agentApproval = warning;

  /// Agent: queued / inactive
  static const Color agentQueued = Color(0xFF4A5568);

  /// Agent: failed
  static const Color agentFailed = danger;

  /// Agent: cancelled
  static const Color agentCancelled = textSecondary;

  // ── Utility ───────────────────────────────────────────────────────────

  /// Transparent
  static const Color transparent = Color(0x00000000);

  /// White with opacity helpers
  static const Color white = Color(0xFFFFFFFF);
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color white05 = Color(0x0DFFFFFF);
}

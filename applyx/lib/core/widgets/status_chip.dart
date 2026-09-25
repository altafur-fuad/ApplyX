import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Status chip — displays agent/application state with color coding.
///
/// design.md agent state visual contract:
/// - cyan → active/running
/// - green → completed
/// - amber → approval required
/// - muted → queued
/// - danger → failed
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  /// Named constructors for standard agent states.
  factory StatusChip.queued() => const StatusChip(
        label: 'Queued',
        color: AppColors.agentQueued,
        icon: Icons.schedule,
      );

  factory StatusChip.running() => const StatusChip(
        label: 'Running',
        color: AppColors.agentActive,
        icon: Icons.sync,
      );

  factory StatusChip.completed() => const StatusChip(
        label: 'Completed',
        color: AppColors.agentCompleted,
        icon: Icons.check_circle_outline,
      );

  factory StatusChip.approval() => const StatusChip(
        label: 'Approval Required',
        color: AppColors.agentApproval,
        icon: Icons.front_hand_outlined,
      );

  factory StatusChip.failed() => const StatusChip(
        label: 'Failed',
        color: AppColors.agentFailed,
        icon: Icons.error_outline,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTypography.label(color: color),
          ),
        ],
      ),
    );
  }
}

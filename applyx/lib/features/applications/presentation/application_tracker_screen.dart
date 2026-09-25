import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/surface_card.dart';

/// Application Tracker screen.
///
/// design.md § 6.11:
/// Use timeline/status chips instead of only tables.
/// PRD § 7.11 statuses: saved, preparing, ready_for_review,
/// submitted, under_review, interview, rejected, offer, withdrawn.
class ApplicationTrackerScreen extends StatelessWidget {
  const ApplicationTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Applications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.lg,
          ),
          children: const [
            _ApplicationCard(
              title: 'Flutter Developer Intern',
              org: 'TechCorp Inc.',
              status: 'Ready for review',
              statusColor: AppColors.warning,
              deadline: 'Deadline in 3 days',
              deadlineUrgent: true,
            ),
            SizedBox(height: AppSpacing.md),
            _ApplicationCard(
              title: 'Mobile App Engineering Intern',
              org: 'StartupAI',
              status: 'Preparing',
              statusColor: AppColors.aiAccent,
              deadline: 'Deadline in 12 days',
              deadlineUrgent: false,
            ),
            SizedBox(height: AppSpacing.md),
            _ApplicationCard(
              title: 'Mobile App Research Assistant',
              org: 'University of Dhaka',
              status: 'Submitted',
              statusColor: AppColors.success,
              deadline: 'Follow-up next week',
              deadlineUrgent: false,
            ),
            SizedBox(height: AppSpacing.md),
            _ApplicationCard(
              title: 'Junior Android Developer',
              org: 'LocalTech BD',
              status: 'Rejected',
              statusColor: AppColors.danger,
              deadline: '',
              deadlineUrgent: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.title,
    required this.org,
    required this.status,
    required this.statusColor,
    required this.deadline,
    required this.deadlineUrgent,
  });

  final String title;
  final String org;
  final String status;
  final Color statusColor;
  final String deadline;
  final bool deadlineUrgent;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: () => context.push(AppRoutes.opportunityDetail),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusChip(label: status, color: statusColor),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.business_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(org, style: AppTypography.caption()),
            ],
          ),
          if (deadline.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              deadline,
              style: AppTypography.caption(
                color: deadlineUrgent ? AppColors.warning : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

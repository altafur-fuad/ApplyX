import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/app_states.dart';
import 'providers/application_provider.dart';
import '../domain/application.dart';

class ApplicationTrackerScreen extends ConsumerWidget {
  const ApplicationTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(applicationsProvider);

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
        child: applicationsAsync.when(
          data: (applications) {
            if (applications.isEmpty) {
              return AppEmptyState(
                icon: Icons.list_alt,
                title: 'No active applications',
                message: 'No active applications yet.',
                actionLabel: 'Go Back',
                onAction: () => context.pop(),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: AppSpacing.lg,
              ),
              itemCount: applications.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final app = applications[index];
                return _ApplicationCard(
                  oppId: app.opportunityId,
                  title: app.title,
                  org: app.organization,
                  status: _formatStatus(app.status),
                  statusColor: _getStatusColor(app.status),
                  deadline: app.deadline,
                  deadlineUrgent: app.deadlineUrgent,
                );
              },
            );
          },
          loading: () => const AppLoadingState(message: 'Loading applications...'),
          error: (error, stack) => AppErrorState(
            message: 'Couldn\'t load applications.',
            onRetry: () => ref.refresh(applicationsProvider),
          ),
        ),
      ),
    );
  }

  String _formatStatus(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.saved: return 'Saved';
      case ApplicationStatus.preparing: return 'Preparing';
      case ApplicationStatus.readyForReview: return 'Ready for review';
      case ApplicationStatus.submitted: return 'Submitted';
      case ApplicationStatus.underReview: return 'Under Review';
      case ApplicationStatus.interview: return 'Interview';
      case ApplicationStatus.rejected: return 'Rejected';
      case ApplicationStatus.offer: return 'Offer';
      case ApplicationStatus.withdrawn: return 'Withdrawn';
    }
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.preparing:
      case ApplicationStatus.underReview:
        return AppColors.aiAccent;
      case ApplicationStatus.readyForReview:
        return AppColors.warning;
      case ApplicationStatus.submitted:
      case ApplicationStatus.interview:
      case ApplicationStatus.offer:
        return AppColors.success;
      case ApplicationStatus.rejected:
      case ApplicationStatus.withdrawn:
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.oppId,
    required this.title,
    required this.org,
    required this.status,
    required this.statusColor,
    required this.deadline,
    required this.deadlineUrgent,
  });

  final String oppId;
  final String title;
  final String org;
  final String status;
  final Color statusColor;
  final String deadline;
  final bool deadlineUrgent;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: () => context.push('${AppRoutes.opportunityDetail}/$oppId'),
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

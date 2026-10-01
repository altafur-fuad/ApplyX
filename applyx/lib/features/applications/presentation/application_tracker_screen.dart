import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/organic_background.dart';
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
        title: const Text('Tracker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTypography.h3(color: AppColors.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: OrganicBackground(
        child: SafeArea(
          child: applicationsAsync.when(
            data: (applications) {
              if (applications.isEmpty) {
                return AppEmptyState(
                  icon: Icons.list_alt,
                  title: 'No active applications',
                  message: 'Your tracker is clear.',
                  actionLabel: 'Discover Opportunities',
                  onAction: () => context.go(AppRoutes.discover),
                );
              }

              // Group applications into swimlanes
              final grouped = <String, List<Application>>{
                'In Progress': [],
                'Applied': [],
                'Interviewing': [],
                'Closed': [],
              };

              for (final app in applications) {
                switch (app.status) {
                  case ApplicationStatus.saved:
                  case ApplicationStatus.preparing:
                  case ApplicationStatus.readyForReview:
                    grouped['In Progress']!.add(app);
                    break;
                  case ApplicationStatus.submitted:
                  case ApplicationStatus.underReview:
                    grouped['Applied']!.add(app);
                    break;
                  case ApplicationStatus.interview:
                  case ApplicationStatus.offer:
                    grouped['Interviewing']!.add(app);
                    break;
                  case ApplicationStatus.rejected:
                  case ApplicationStatus.withdrawn:
                    grouped['Closed']!.add(app);
                    break;
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: AppSpacing.lg,
                  bottom: AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Command Center', style: AppTypography.h1(color: AppColors.textPrimary)),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Manage and track your career pipeline.',
                            style: AppTypography.bodySmall(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
                    
                    if (grouped['Interviewing']!.isNotEmpty)
                      _Swimlane(title: 'Interviewing', apps: grouped['Interviewing']!),
                    if (grouped['Applied']!.isNotEmpty)
                      _Swimlane(title: 'Applied', apps: grouped['Applied']!),
                    if (grouped['In Progress']!.isNotEmpty)
                      _Swimlane(title: 'In Progress', apps: grouped['In Progress']!),
                    if (grouped['Closed']!.isNotEmpty)
                      _Swimlane(title: 'Closed', apps: grouped['Closed']!),
                  ],
                ),
              );
            },
            loading: () => const AppLoadingState(message: 'Loading tracker...'),
            error: (error, stack) => AppErrorState(
              message: 'Couldn\'t load applications.',
              onRetry: () => ref.refresh(applicationsProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _Swimlane extends StatelessWidget {
  const _Swimlane({required this.title, required this.apps});

  final String title;
  final List<Application> apps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          child: Row(
            children: [
              Text(title, style: AppTypography.h3()),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${apps.length}',
                  style: AppTypography.caption(color: AppColors.primary).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            scrollDirection: Axis.horizontal,
            itemCount: apps.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final app = apps[index];
              return SizedBox(
                width: 260,
                child: _KanbanCard(
                  id: app.id,
                  title: app.title,
                  org: app.organization,
                  statusLabel: _formatDetailedStatus(app.status),
                  statusColor: _getStatusColor(app.status),
                  deadline: app.deadline,
                  deadlineUrgent: app.deadlineUrgent,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  String _formatDetailedStatus(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.saved:
        return 'Saved';
      case ApplicationStatus.preparing:
        return 'AI Preparing';
      case ApplicationStatus.readyForReview:
        return 'Ready for Review';
      case ApplicationStatus.submitted:
        return 'Submitted';
      case ApplicationStatus.underReview:
        return 'Under Review';
      case ApplicationStatus.interview:
        return 'Interviewing';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.offer:
        return 'Offer';
      case ApplicationStatus.withdrawn:
        return 'Withdrawn';
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
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({
    required this.id,
    required this.title,
    required this.org,
    required this.statusLabel,
    required this.statusColor,
    required this.deadline,
    required this.deadlineUrgent,
  });

  final String id;
  final String title;
  final String org;
  final String statusLabel;
  final Color statusColor;
  final String deadline;
  final bool deadlineUrgent;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: () => context.push('${AppRoutes.applicationTracker}/application-detail/$id'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  statusLabel,
                  style: AppTypography.caption(color: statusColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h3(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  org,
                  style: AppTypography.bodySmall(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (deadline.isNotEmpty) ...[
            const Divider(color: AppColors.border),
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: deadlineUrgent ? AppColors.warning : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  deadline,
                  style: AppTypography.caption(
                    color: deadlineUrgent ? AppColors.warning : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

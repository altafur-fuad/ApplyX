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
import '../../goals/presentation/providers/goal_provider.dart';
import 'providers/opportunity_provider.dart';
import '../domain/opportunity.dart';

class OpportunityResultsScreen extends ConsumerWidget {
  const OpportunityResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunitiesAsync = ref.watch(opportunitiesProvider);
    final activeGoalAsync = ref.watch(activeGoalProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Results'),
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
          child: opportunitiesAsync.when(
            data: (opportunities) {
              if (opportunities.isEmpty) {
                return AppEmptyState(
                  icon: Icons.search_off,
                  title: 'No opportunities found',
                  message: "Your agent hasn't found any matches yet.",
                  actionLabel: 'Go Back',
                  onAction: () => context.pop(),
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding,
                        AppSpacing.lg,
                        AppSpacing.pagePadding,
                        AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${opportunities.length} matches',
                                  style: AppTypography.caption(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          activeGoalAsync.when(
                            data: (goal) => Text(
                              goal?.title ?? 'No Active Goal',
                              style: AppTypography.h1(color: AppColors.textPrimary),
                            ),
                            loading: () => Text('Loading goal...', style: AppTypography.h1()),
                            error: (_, __) => Text('Goal Error', style: AppTypography.h1()),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Your agent has processed these opportunities.',
                            style: AppTypography.bodySmall(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  _sectionHeader('All Opportunities'),
                  ...opportunities.map(
                    (opp) => _opportunityCard(
                      context,
                      opp,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxl),
                  ),
                ],
              );
            },
            loading: () =>
                const AppLoadingState(message: 'Loading opportunities...'),
            error: (error, stack) => AppErrorState(
              message: 'Couldn\'t load opportunities.',
              onRetry: () => ref.refresh(opportunitiesProvider),
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.lg,
          AppSpacing.pagePadding,
          AppSpacing.md,
        ),
        child: Text(title, style: AppTypography.h3()),
      ),
    );
  }

  SliverToBoxAdapter _opportunityCard(
    BuildContext context,
    Opportunity opportunity,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.md,
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          onTap: () =>
              context.push('${AppRoutes.opportunityDetail}/${opportunity.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                opportunity.title,
                style: AppTypography.body(color: AppColors.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              _infoRow(Icons.business_outlined, opportunity.organization),
              if (opportunity.location != null) ...[
                const SizedBox(height: 6),
                _infoRow(Icons.location_on_outlined, opportunity.location!),
              ],
              if (opportunity.deadline != null) ...[
                const SizedBox(height: 6),
                _infoRow(
                  Icons.calendar_today_outlined,
                  'Deadline: ${opportunity.deadline!.toLocal().toString().split(' ')[0]}',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.caption(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

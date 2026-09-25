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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
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

            final recommended = opportunities.where((o) => o.matchLevel == MatchLevel.strong).toList();
            final needsReview = opportunities.where((o) => o.matchLevel == MatchLevel.review).toList();

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
                            StatusChip.completed(),
                            const Spacer(),
                            Text(
                              '${opportunities.length} opportunities found',
                              style: AppTypography.caption(),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        activeGoalAsync.when(
                          data: (goal) => Text(
                            goal?.title ?? 'No Active Goal',
                            style: AppTypography.h2(),
                          ),
                          loading: () => const Text('Loading goal...'),
                          error: (_, __) => const Text('Goal Error'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Agent found ${opportunities.length} opportunities. ${recommended.length} are strong matches.',
                          style: AppTypography.bodySmall(),
                        ),
                      ],
                    ),
                  ),
                ),

                if (recommended.isNotEmpty) ...[
                  _sectionHeader('Recommended'),
                  ...recommended.map((opp) => _opportunityCard(context, opp, AppColors.success, 'Strong Match')),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
                ],

                if (needsReview.isNotEmpty) ...[
                  _sectionHeader('Needs Review'),
                  ...needsReview.map((opp) => _opportunityCard(context, opp, AppColors.warning, 'Needs Review')),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.section)),
                ],
              ],
            );
          },
          loading: () => const AppLoadingState(message: 'Loading opportunities...'),
          error: (error, stack) => AppErrorState(
            message: 'Couldn\'t load opportunities.',
            onRetry: () => ref.refresh(opportunitiesProvider),
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
          0,
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
    Color matchColor,
    String matchLabel,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.md,
        ),
        child: SurfaceCard(
          onTap: () => context.push('${AppRoutes.opportunityDetail}/${opportunity.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      opportunity.title,
                      style: AppTypography.body(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusChip(label: matchLabel, color: matchColor),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _infoRow(Icons.business_outlined, opportunity.organization),
              const SizedBox(height: 6),
              _infoRow(Icons.location_on_outlined, opportunity.location),
              const SizedBox(height: 6),
              if (opportunity.deadline != null)
                _infoRow(Icons.calendar_today_outlined, 'Deadline: ${opportunity.deadline}'),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppColors.aiAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        opportunity.reason,
                        style: AppTypography.caption(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTypography.caption(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

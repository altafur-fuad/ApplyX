import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/app_states.dart';
import 'providers/opportunity_provider.dart';
import '../domain/opportunity.dart';

class OpportunityDetailScreen extends ConsumerWidget {
  const OpportunityDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunityAsync = ref.watch(opportunityDetailProvider(id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Opportunity'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: opportunityAsync.when(
          data: (opportunity) {
            if (opportunity == null) {
              return AppErrorState(
                message: 'Opportunity not found.',
                onRetry: () => context.pop(),
              );
            }

            final isStrongMatch = opportunity.matchLevel == MatchLevel.strong;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),

                        // Title + match chip
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                opportunity.title,
                                style: AppTypography.h2(),
                              ),
                            ),
                            StatusChip(
                              label: isStrongMatch
                                  ? 'Strong Match'
                                  : 'Needs Review',
                              color: isStrongMatch
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Quick info row
                        Wrap(
                          spacing: AppSpacing.lg,
                          runSpacing: AppSpacing.sm,
                          children: [
                            _infoChip(
                              Icons.business_outlined,
                              opportunity.organization,
                            ),
                            _infoChip(
                              Icons.location_on_outlined,
                              opportunity.location,
                            ),
                            if (opportunity.deadline != null)
                              _infoChip(
                                Icons.calendar_today_outlined,
                                opportunity.deadline!,
                              ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // Overview
                        _sectionTitle('Overview'),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${opportunity.organization} is looking for a motivated candidate to join their team. You will work on exciting projects and collaborate with experienced professionals.',
                          style: AppTypography.body(
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Why this matches
                        _sectionTitle('Why this matches'),
                        const SizedBox(height: AppSpacing.sm),
                        SurfaceCard(
                          color: AppColors.surfaceElevated,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [_matchRow(opportunity.reason)],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Source
                        _sectionTitle('Source'),
                        const SizedBox(height: AppSpacing.sm),
                        SurfaceCard(
                          color: AppColors.surfaceElevated,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.link,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  opportunity.sourceUrl,
                                  style: AppTypography.caption(
                                    color: AppColors.aiAccent,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recently fetched',
                                style: AppTypography.caption(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),

                // Bottom CTA
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.lg,
                    AppSpacing.pagePadding,
                    AppSpacing.xxl,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: AppPrimaryButton(
                    label: 'Prepare Application',
                    onPressed: () => context.push('${AppRoutes.approval}/$id'),
                  ),
                ),
              ],
            );
          },
          loading: () => const AppLoadingState(message: 'Loading details...'),
          error: (error, stack) => AppErrorState(
            message: 'Couldn\'t load details.',
            onRetry: () => ref.refresh(opportunityDetailProvider(id)),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: AppTypography.h3());
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: AppTypography.caption()),
      ],
    );
  }

  Widget _matchRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome, size: 16, color: AppColors.aiAccent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

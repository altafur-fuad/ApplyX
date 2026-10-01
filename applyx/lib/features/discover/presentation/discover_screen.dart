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
import '../../opportunities/presentation/providers/opportunity_provider.dart';
import '../../opportunities/domain/opportunity.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunitiesAsync = ref.watch(opportunitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: OrganicBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Search & Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.xl,
                  AppSpacing.pagePadding,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Discover', style: AppTypography.h1()),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'AI-curated opportunities for your profile',
                      style: AppTypography.bodySmall(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Fake search bar
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Search roles, companies...',
                            style: AppTypography.body(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Categories / Chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                  children: [
                    _categoryChip('Top Matches', true),
                    const SizedBox(width: AppSpacing.sm),
                    _categoryChip('Engineering', false),
                    const SizedBox(width: AppSpacing.sm),
                    _categoryChip('Design', false),
                    const SizedBox(width: AppSpacing.sm),
                    _categoryChip('Remote', false),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Masonry / Staggered Grid (simulated with a Wrap/ListView for now, using horizontal scrolling sections)
              Expanded(
                child: opportunitiesAsync.when(
                  data: (opportunities) {
                    if (opportunities.isEmpty) {
                      return const AppEmptyState(
                        icon: Icons.search_off,
                        title: 'No recommendations',
                        message: 'Complete your profile to get matches.',
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.pagePadding,
                        right: AppSpacing.pagePadding,
                        bottom: AppSpacing.xxl,
                      ),
                      children: [
                        Text('Trending for you', style: AppTypography.h3()),
                        const SizedBox(height: AppSpacing.md),
                        ...opportunities.map((opp) => _DiscoverCard(opportunity: opp)),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Error loading recommendations')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String label, bool isSelected) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.white.withValues(alpha: 0.8),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall(
          color: isSelected ? AppColors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({required this.opportunity});

  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        onTap: () => context.push('${AppRoutes.discover}/opportunity-detail/${opportunity.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      opportunity.organization.substring(0, 1).toUpperCase(),
                      style: AppTypography.h3(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opportunity.title,
                        style: AppTypography.h3(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opportunity.organization,
                        style: AppTypography.bodySmall(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.bookmark_border, color: AppColors.textSecondary, size: 20),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (opportunity.location != null)
                  _tag(opportunity.location!),
                _tag('98% Match', isHighlight: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isHighlight ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
      ),
      child: Text(
        text,
        style: AppTypography.caption(color: isHighlight ? AppColors.primary : AppColors.textSecondary),
      ),
    );
  }
}

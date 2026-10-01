import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/organic_background.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/app_states.dart';

import '../../profile/presentation/providers/profile_provider.dart';
import '../../goals/presentation/providers/goal_provider.dart';
import '../../opportunities/presentation/providers/opportunity_provider.dart';
import '../../applications/presentation/providers/application_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final activeGoalAsync = ref.watch(activeGoalProvider);
    final opportunitiesAsync = ref.watch(opportunitiesProvider);
    final applicationsAsync = ref.watch(applicationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: OrganicBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Greeting header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.xxl,
                    AppSpacing.pagePadding,
                    AppSpacing.lg,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good morning',
                              style: AppTypography.bodySmall(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            profileAsync.when(
                              data: (profile) => Text(
                                '${profile.fullName.split(' ').first} 👋',
                                style: AppTypography.h1(color: AppColors.textPrimary),
                              ),
                              loading: () =>
                                  Text('Loading...', style: AppTypography.h1(color: AppColors.textPrimary)),
                              error: (_, __) =>
                                  Text('User 👋', style: AppTypography.h1(color: AppColors.textPrimary)),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.profile),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.surface,
                            child: profileAsync.when(
                              data: (profile) => Text(
                                profile.fullName.isNotEmpty
                                    ? profile.fullName[0].toUpperCase()
                                    : '?',
                                style: AppTypography.h3(color: AppColors.primary),
                              ),
                              loading: () => const CircularProgressIndicator(strokeWidth: 2),
                              error: (_, __) => Text(
                                '?',
                                style: AppTypography.h3(color: AppColors.primary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

              // Active goal / quick create
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding,
                  ),
                  child: activeGoalAsync.when(
                    data: (goal) {
                      if (goal == null) {
                        return GlassCard(
                          onTap: () => context.push(AppRoutes.createGoal),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.add_task, color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Text('No Active Goal', style: AppTypography.h3()),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Create your first goal and let ApplyX plan the next steps.',
                                style: AppTypography.bodySmall(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        );
                      }

                      return GlassCard(
                        onTap: () => context.push(AppRoutes.agentActivity),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  color: AppColors.aiAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Active Goal',
                                  style: AppTypography.label(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                StatusChip.running(),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(goal.title, style: AppTypography.h3()),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Checking eligibility for 6 opportunities...',
                              style: AppTypography.bodySmall(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const AppLoadingState(),
                    error: (_, __) =>
                        const AppErrorState(message: 'Error loading goal'),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // Quick actions (Redesigned as floating items instead of heavy cards)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _QuickActionItem(
                        icon: Icons.add,
                        label: 'New Goal',
                        onTap: () => context.push(AppRoutes.createGoal),
                      ),
                      _QuickActionItem(
                        icon: Icons.track_changes,
                        label: 'Tracker',
                        onTap: () => context.push(AppRoutes.applicationTracker),
                      ),
                      _QuickActionItem(
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () => context.push(AppRoutes.settings),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

              // Section: Top Opportunities
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Opportunities', style: AppTypography.h3()),
                      TextButton(
                        onPressed: () =>
                            context.push(AppRoutes.opportunityResults),
                        child: Text(
                          'See all',
                          style: AppTypography.bodySmall(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Opportunities
              opportunitiesAsync.when(
                data: (opportunities) {
                  if (opportunities.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.pagePadding),
                        child: Text('No opportunities yet.', style: AppTypography.bodySmall(color: AppColors.textSecondary)),
                      ),
                    );
                  }

                  final recentOps = opportunities.take(2).toList();
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePadding,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final opp = recentOps[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _OpportunityMiniCard(
                            id: opp.id,
                            title: opp.title,
                            org: opp.organization,
                            location: opp.location ?? '',
                          ),
                        );
                      }, childCount: recentOps.length),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SliverToBoxAdapter(
                  child: Text('Error loading opportunities'),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // Section: Application Deadlines
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding,
                  ),
                  child: Text('Upcoming Deadlines', style: AppTypography.h3()),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              applicationsAsync.when(
                data: (applications) {
                  final urgentApp = applications
                      .where((a) => a.deadlineUrgent)
                      .firstOrNull;

                  if (urgentApp == null) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                        child: Text('No upcoming deadlines.', style: AppTypography.bodySmall(color: AppColors.textSecondary)),
                      ),
                    );
                  }

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding,
                        0,
                        AppSpacing.pagePadding,
                        AppSpacing.xxl,
                      ),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${urgentApp.title} — ${urgentApp.organization}',
                                    style: AppTypography.body(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    urgentApp.deadline,
                                    style: AppTypography.caption(
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SliverToBoxAdapter(child: Text('Error')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white.withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: AppTypography.caption(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _OpportunityMiniCard extends StatelessWidget {
  const _OpportunityMiniCard({
    required this.id,
    required this.title,
    required this.org,
    required this.location,
  });

  final String id;
  final String title;
  final String org;
  final String location;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('${AppRoutes.opportunityDetail}/$id'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: AppSpacing.md),
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(location, style: AppTypography.caption()),
            ],
          ),
        ],
      ),
    );
  }
}

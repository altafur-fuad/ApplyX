import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/app_states.dart';

import '../../profile/presentation/providers/profile_provider.dart';
import '../../goals/presentation/providers/goal_provider.dart';
import '../../opportunities/presentation/providers/opportunity_provider.dart';
import '../../applications/presentation/providers/application_provider.dart';

import '../../opportunities/domain/opportunity.dart';

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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Greeting header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.xl,
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
                            style: AppTypography.bodySmall(),
                          ),
                          const SizedBox(height: 4),
                          profileAsync.when(
                            data: (profile) => Text(
                              '${profile.fullName.split(' ').first} 👋',
                              style: AppTypography.h2(),
                            ),
                            loading: () => Text('Loading...', style: AppTypography.h2()),
                            error: (_, __) => Text('User 👋', style: AppTypography.h2()),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.profile),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.surfaceElevated,
                        child: profileAsync.when(
                          data: (profile) => Text(
                            profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : '?',
                            style: AppTypography.h3(color: AppColors.primary),
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => Text('?', style: AppTypography.h3(color: AppColors.primary)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Active goal / quick create
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                child: activeGoalAsync.when(
                  data: (goal) {
                    if (goal == null) {
                      return SurfaceCard(
                        onTap: () => context.push(AppRoutes.createGoal),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No Active Goal',
                              style: AppTypography.h3(),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Create your first goal and let ApplyX plan the next steps.',
                              style: AppTypography.bodySmall(),
                            ),
                          ],
                        ),
                      );
                    }

                    return SurfaceCard(
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
                                  color: AppColors.aiAccent,
                                ),
                              ),
                              const Spacer(),
                              StatusChip.running(),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            goal.title,
                            style: AppTypography.h3(),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Checking eligibility for 6 opportunities...',
                            style: AppTypography.bodySmall(),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const AppLoadingState(),
                  error: (_, __) => const AppErrorState(message: 'Error loading goal'),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

            // Quick actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.add_circle_outline,
                        label: 'New Goal',
                        onTap: () => context.push(AppRoutes.createGoal),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.list_alt_outlined,
                        label: 'Tracker',
                        onTap: () => context.push(AppRoutes.applicationTracker),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () => context.push(AppRoutes.settings),
                      ),
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
                      onPressed: () => context.push(AppRoutes.opportunityResults),
                      child: Text(
                        'See all',
                        style: AppTypography.bodySmall(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Mock opportunity cards
            opportunitiesAsync.when(
              data: (opportunities) {
                if (opportunities.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.pagePadding),
                      child: Text('No opportunities yet.'),
                    ),
                  );
                }

                final recentOps = opportunities.take(2).toList();
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final opp = recentOps[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _OpportunityMiniCard(
                            id: opp.id,
                            title: opp.title,
                            org: opp.organization,
                            location: opp.location,
                            match: opp.matchLevel == MatchLevel.strong ? 'Strong Match' : 'Needs Review',
                            matchColor: opp.matchLevel == MatchLevel.strong ? AppColors.success : AppColors.warning,
                          ),
                        );
                      },
                      childCount: recentOps.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SliverToBoxAdapter(child: Text('Error loading opportunities')),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

            // Section: Application Deadlines
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                child: Text('Upcoming Deadlines', style: AppTypography.h3()),
              ),
            ),

            applicationsAsync.when(
              data: (applications) {
                final urgentApp = applications.where((a) => a.deadlineUrgent).firstOrNull;

                if (urgentApp == null) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.pagePadding),
                      child: Text('No upcoming deadlines.'),
                    ),
                  );
                }

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      AppSpacing.md,
                      AppSpacing.pagePadding,
                      AppSpacing.section,
                    ),
                    child: SurfaceCard(
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 48,
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
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SliverToBoxAdapter(child: Text('Error')),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: AppTypography.caption()),
          ],
        ),
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
    required this.match,
    required this.matchColor,
  });

  final String id;
  final String title;
  final String org;
  final String location;
  final String match;
  final Color matchColor;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: () => context.push('${AppRoutes.opportunityDetail}/$id'),
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
              StatusChip(label: match, color: matchColor),
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

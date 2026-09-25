import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/status_chip.dart';

/// Home dashboard screen.
///
/// design.md § 6.4 hierarchy:
/// Greeting → Active Goal / Quick Create → Agent Status
/// → Top Opportunities → Application Deadlines
///
/// Uses mock data clearly separated for future backend integration.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                          Text(
                            'Altafur 👋',
                            style: AppTypography.h2(),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.profile),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.surfaceElevated,
                        child: Text(
                          'A',
                          style: AppTypography.h3(color: AppColors.primary),
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
                child: SurfaceCard(
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
                        'Find paid remote Flutter internships',
                        style: AppTypography.h3(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Checking eligibility for 6 opportunities...',
                        style: AppTypography.bodySmall(),
                      ),
                    ],
                  ),
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
                        onTap: () =>
                            context.push(AppRoutes.applicationTracker),
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
                      onPressed: () =>
                          context.push(AppRoutes.opportunityResults),
                      child: Text(
                        'See all',
                        style:
                            AppTypography.bodySmall(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Mock opportunity cards
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _OpportunityMiniCard(
                    title: 'Flutter Developer Intern',
                    org: 'TechCorp Inc.',
                    location: 'Remote',
                    match: 'Strong Match',
                    matchColor: AppColors.success,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _OpportunityMiniCard(
                    title: 'Mobile App Research Assistant',
                    org: 'University of Dhaka',
                    location: 'Hybrid',
                    match: 'Needs Review',
                    matchColor: AppColors.warning,
                  ),
                ]),
              ),
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

            SliverToBoxAdapter(
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
                              'Flutter Intern — TechCorp',
                              style: AppTypography.body(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Deadline in 3 days',
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick action button tile for the home dashboard.
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

/// Compact opportunity card for the home feed.
class _OpportunityMiniCard extends StatelessWidget {
  const _OpportunityMiniCard({
    required this.title,
    required this.org,
    required this.location,
    required this.match,
    required this.matchColor,
  });

  final String title;
  final String org;
  final String location;
  final String match;
  final Color matchColor;

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

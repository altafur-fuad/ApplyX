import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/surface_card.dart';

/// Opportunity Results screen.
///
/// design.md § 6.7:
/// Top: goal, status, summary.
/// Groups: Recommended, Needs Review, Not Enough Evidence.
/// Each card: Title, Org, Remote/Location, Deadline, Match reason, Source.
class OpportunityResultsScreen extends StatelessWidget {
  const OpportunityResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: CustomScrollView(
          slivers: [
            // Summary
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
                          '6 opportunities found',
                          style: AppTypography.caption(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Find paid remote Flutter internships',
                      style: AppTypography.h2(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Agent found 6 opportunities across 3 sources. 3 are strong matches.',
                      style: AppTypography.bodySmall(),
                    ),
                  ],
                ),
              ),
            ),

            // Section: Recommended
            _sectionHeader('Recommended'),
            _opportunityCard(
              context,
              title: 'Flutter Developer Intern',
              org: 'TechCorp Inc.',
              location: 'Remote',
              deadline: 'Oct 15, 2026',
              reason: 'Strong Flutter skills match. Remote position.',
              matchColor: AppColors.success,
              matchLabel: 'Strong Match',
            ),
            _opportunityCard(
              context,
              title: 'Mobile App Engineering Intern',
              org: 'StartupAI',
              location: 'Remote',
              deadline: 'Oct 20, 2026',
              reason: 'Dart/Flutter listed. Paid internship.',
              matchColor: AppColors.success,
              matchLabel: 'Strong Match',
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

            // Section: Needs Review
            _sectionHeader('Needs Review'),
            _opportunityCard(
              context,
              title: 'Mobile App Research Assistant',
              org: 'University of Dhaka',
              location: 'Hybrid — Dhaka',
              deadline: 'Nov 1, 2026',
              reason: 'Relevant skills but hybrid preference unclear.',
              matchColor: AppColors.warning,
              matchLabel: 'Needs Review',
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.section),
            ),
          ],
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
    BuildContext context, {
    required String title,
    required String org,
    required String location,
    required String deadline,
    required String reason,
    required Color matchColor,
    required String matchLabel,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.md,
        ),
        child: SurfaceCard(
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusChip(label: matchLabel, color: matchColor),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _infoRow(Icons.business_outlined, org),
              const SizedBox(height: 6),
              _infoRow(Icons.location_on_outlined, location),
              const SizedBox(height: 6),
              _infoRow(Icons.calendar_today_outlined, 'Deadline: $deadline'),
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
                        reason,
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

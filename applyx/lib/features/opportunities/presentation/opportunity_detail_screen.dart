import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/surface_card.dart';

/// Opportunity Detail screen.
///
/// design.md § 6.8:
/// Sections: Overview, Requirements, Why this matches,
/// Missing requirements, Source/evidence, Deadline, Actions.
/// Primary CTA: "Prepare Application"
class OpportunityDetailScreen extends StatelessWidget {
  const OpportunityDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: Column(
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
                            'Flutter Developer Intern',
                            style: AppTypography.h2(),
                          ),
                        ),
                        StatusChip(
                          label: 'Strong Match',
                          color: AppColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Quick info row
                    Wrap(
                      spacing: AppSpacing.lg,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _infoChip(Icons.business_outlined, 'TechCorp Inc.'),
                        _infoChip(Icons.location_on_outlined, 'Remote'),
                        _infoChip(
                          Icons.calendar_today_outlined,
                          'Oct 15, 2026',
                        ),
                        _infoChip(Icons.paid_outlined, 'Paid'),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Overview
                    _sectionTitle('Overview'),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'TechCorp is looking for a motivated Flutter Developer Intern to join their mobile team. You will work on production mobile applications, collaborate with senior engineers, and contribute to open-source tools.',
                      style: AppTypography.body(color: AppColors.textSecondary),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Requirements
                    _sectionTitle('Requirements'),
                    const SizedBox(height: AppSpacing.sm),
                    _requirementRow('Flutter / Dart experience', true),
                    _requirementRow('Understanding of REST APIs', true),
                    _requirementRow('Git version control', true),
                    _requirementRow(
                      'Currently enrolled in CS program',
                      true,
                    ),
                    _requirementRow(
                      '2+ years professional experience',
                      false,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Why this matches
                    _sectionTitle('Why this matches'),
                    const SizedBox(height: AppSpacing.sm),
                    SurfaceCard(
                      color: AppColors.surfaceElevated,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _matchRow(
                            'Flutter is listed as your top skill.',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _matchRow(
                            'Remote position matches your preference.',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _matchRow(
                            'You are a CSE student — meets education requirement.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Missing / needs review
                    _sectionTitle('Missing Requirements'),
                    const SizedBox(height: AppSpacing.sm),
                    SurfaceCard(
                      color: AppColors.surfaceElevated,
                      borderColor:
                          AppColors.warning.withValues(alpha: 0.3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '2+ years professional experience — you have project experience but may not meet this requirement. Review the original listing.',
                              style: AppTypography.bodySmall(),
                            ),
                          ),
                        ],
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
                              'techcorp.com/careers/flutter-intern',
                              style: AppTypography.caption(
                                color: AppColors.aiAccent,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Fetched 2h ago',
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
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: AppPrimaryButton(
                label: 'Prepare Application',
                onPressed: () => context.push(AppRoutes.approval),
              ),
            ),
          ],
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

  Widget _requirementRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            met ? Icons.check_circle : Icons.cancel_outlined,
            size: 18,
            color: met ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppTypography.bodySmall()),
          ),
        ],
      ),
    );
  }

  Widget _matchRow(String text) {
    return Row(
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
            text,
            style:
                AppTypography.bodySmall(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

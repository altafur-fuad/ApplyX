import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/surface_card.dart';

/// Approval screen — critical trust screen.
///
/// design.md § 6.10:
/// Show: action, target, generated content preview, risk, approve/reject.
/// "Approval should never be a hidden modal triggered after a confusing action."
///
/// Human approval actions must always be visually distinct
/// from autonomous agent activity.
class ApprovalScreen extends StatelessWidget {
  const ApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Approval Required'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
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

                    // Approval indicator
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color:
                              AppColors.warning.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.front_hand,
                          color: AppColors.warning,
                          size: 32,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    Center(
                      child: Text(
                        'Agent wants to:',
                        style: AppTypography.bodySmall(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: Text(
                        'Submit Application',
                        style: AppTypography.h2(),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Target
                    _detailSection(
                      'Target',
                      Icons.business_outlined,
                      'TechCorp Inc. — Flutter Developer Intern',
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Content preview
                    Text('Generated Content', style: AppTypography.h3()),
                    const SizedBox(height: AppSpacing.sm),
                    SurfaceCard(
                      color: AppColors.surfaceElevated,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _previewRow('Resume', 'Tailored for Flutter role'),
                          const Divider(height: AppSpacing.xl),
                          _previewRow(
                            'Cover Letter',
                            'Personalized 3-paragraph letter',
                          ),
                          const Divider(height: AppSpacing.xl),
                          _previewRow(
                            'Portfolio Link',
                            'github.com/example',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Risk notice
                    SurfaceCard(
                      borderColor:
                          AppColors.warning.withValues(alpha: 0.4),
                      color: AppColors.warning.withValues(alpha: 0.05),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'External Submission',
                                  style: AppTypography.body(
                                    color: AppColors.warning,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'This will submit your application materials to TechCorp Inc. This action cannot be undone.',
                                  style: AppTypography.bodySmall(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // Action buttons
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
              child: Column(
                children: [
                  AppPrimaryButton(
                    label: 'Approve & Continue',
                    onPressed: () {
                      // Simulated approval → go to tracker
                      context.go(AppRoutes.applicationTracker);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSecondaryButton(
                    label: 'Review First',
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailSection(String label, IconData icon, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label()),
        const SizedBox(height: AppSpacing.sm),
        SurfaceCard(
          color: AppColors.surfaceElevated,
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  value,
                  style: AppTypography.body(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _previewRow(String label, String detail) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body()),
        Flexible(
          child: Text(
            detail,
            style: AppTypography.caption(),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

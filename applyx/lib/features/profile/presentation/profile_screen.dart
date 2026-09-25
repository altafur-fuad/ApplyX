import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/surface_card.dart';

/// Profile screen.
///
/// design.md § 6.12:
/// Sections: About, Skills, Education, Experience, Projects, Links, Documents.
/// Show profile completeness without gamifying it excessively.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Avatar + name
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.surfaceElevated,
                      child: Text(
                        'A',
                        style: AppTypography.h1(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Altafur Fuad', style: AppTypography.h2()),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'CSE Student | Flutter | Python | ML',
                      style: AppTypography.bodySmall(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Profile completeness — subtle indicator
              SurfaceCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile strength',
                            style: AppTypography.label(),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 0.72,
                              backgroundColor:
                                  AppColors.border,
                              color: AppColors.primary,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Text(
                      '72%',
                      style: AppTypography.h3(color: AppColors.primary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Skills
              _sectionTitle('Skills'),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: const [
                  _SkillChip('Flutter'),
                  _SkillChip('Dart'),
                  _SkillChip('Python'),
                  _SkillChip('Machine Learning'),
                  _SkillChip('Firebase'),
                  _SkillChip('Git'),
                  _SkillChip('REST APIs'),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Education
              _sectionTitle('Education'),
              const SizedBox(height: AppSpacing.md),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'B.Sc. in Computer Science & Engineering',
                      style: AppTypography.body(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'University of Dhaka • 2023 – 2027',
                      style: AppTypography.caption(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Projects
              _sectionTitle('Projects'),
              const SizedBox(height: AppSpacing.md),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ApplyX', style: AppTypography.body()),
                    const SizedBox(height: 4),
                    Text(
                      'Agentic AI opportunity assistant built with Flutter.',
                      style: AppTypography.caption(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Links
              _sectionTitle('Links'),
              const SizedBox(height: AppSpacing.md),
              SurfaceCard(
                child: Column(
                  children: [
                    _linkRow(Icons.code, 'GitHub', 'github.com/altafur-fuad'),
                    const Divider(height: AppSpacing.lg),
                    _linkRow(
                      Icons.work_outline,
                      'LinkedIn',
                      'linkedin.com/in/altafur-fuad',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.section),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: AppTypography.h3());
  }

  Widget _linkRow(IconData icon, String label, String url) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.body()),
            Text(
              url,
              style: AppTypography.caption(color: AppColors.aiAccent),
            ),
          ],
        ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.label(color: AppColors.primary),
      ),
    );
  }
}

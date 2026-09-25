import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/app_states.dart';
import 'providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

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
        child: profileAsync.when(
          data: (profile) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.surfaceElevated,
                          child: Text(
                            profile.fullName.isNotEmpty
                                ? profile.fullName[0].toUpperCase()
                                : '?',
                            style: AppTypography.h1(color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(profile.fullName, style: AppTypography.h2()),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          profile.headline,
                          style: AppTypography.bodySmall(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

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
                                  backgroundColor: AppColors.border,
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

                  _sectionTitle('Skills'),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: profile.skills
                        .map((skill) => _SkillChip(skill))
                        .toList(),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  _sectionTitle('Location'),
                  const SizedBox(height: AppSpacing.md),
                  SurfaceCard(
                    child: Text(profile.location, style: AppTypography.body()),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  _sectionTitle('Bio'),
                  const SizedBox(height: AppSpacing.md),
                  SurfaceCard(
                    child: Text(profile.bio, style: AppTypography.body()),
                  ),

                  const SizedBox(height: AppSpacing.section),
                ],
              ),
            );
          },
          loading: () => const AppLoadingState(message: 'Loading profile...'),
          error: (error, stack) => AppErrorState(
            message: 'Could not load profile.',
            onRetry: () => ref.refresh(profileProvider),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: AppTypography.h3());
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: AppTypography.label(color: AppColors.primary)),
    );
  }
}

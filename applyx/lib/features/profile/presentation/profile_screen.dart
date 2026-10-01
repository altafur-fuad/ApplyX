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
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTypography.h3(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: OrganicBackground(
        child: SafeArea(
          child: profileAsync.when(
            data: (profile) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    // Header Profile Card
                    GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              profile.fullName.isNotEmpty
                                  ? profile.fullName[0].toUpperCase()
                                  : '?',
                              style: AppTypography.h1(color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(profile.fullName, style: AppTypography.h2(color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Text(
                                  profile.headline,
                                  style: AppTypography.bodySmall(color: AppColors.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Agent Context / Knowledge Base
                    Text('Source Documents', style: AppTypography.h3(color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'The agent uses these to generate your materials.',
                      style: AppTypography.caption(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildDocumentCard(Icons.picture_as_pdf, 'Master Resume.pdf', 'Updated 2 days ago'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDocumentCard(Icons.text_snippet, 'Cover Letter Templates.docx', 'Updated last week'),
                    const SizedBox(height: AppSpacing.sm),
                    GlassCard(
                      onTap: () {},
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add, color: AppColors.primary, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Upload Document', style: AppTypography.body(color: AppColors.primary)),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Connected Accounts / Integrations
                    Text('Connected Accounts', style: AppTypography.h3(color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.md),
                    _buildIntegrationCard('LinkedIn', 'Synced today', true),
                    const SizedBox(height: AppSpacing.sm),
                    _buildIntegrationCard('GitHub', 'Not connected', false),
                    const SizedBox(height: AppSpacing.sm),
                    _buildIntegrationCard('Portfolio Website', 'Scraped on Monday', true),

                    const SizedBox(height: AppSpacing.xxl),

                    // Skills (Existing profile data representation)
                    Text('Verified Skills', style: AppTypography.h3(color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: profile.skills
                          .map((skill) => _SkillChip(skill))
                          .toList(),
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
      ),
    );
  }

  Widget _buildDocumentCard(IconData icon, String title, String subtitle) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.aiAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.aiAccent, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.body(color: AppColors.textPrimary)),
                Text(subtitle, style: AppTypography.caption(color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationCard(String platform, String status, bool connected) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: connected ? AppColors.success.withValues(alpha: 0.1) : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: connected ? AppColors.success.withValues(alpha: 0.3) : AppColors.border),
            ),
            child: Icon(
              Icons.link, 
              color: connected ? AppColors.success : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(platform, style: AppTypography.body(color: AppColors.textPrimary)),
                Text(status, style: AppTypography.caption(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (connected)
            const Icon(Icons.check_circle, color: AppColors.success, size: 20)
          else
            TextButton(
              onPressed: () {},
              child: Text('Connect', style: AppTypography.bodySmall(color: AppColors.primary)),
            ),
        ],
      ),
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: AppTypography.label(color: AppColors.primary)),
    );
  }
}

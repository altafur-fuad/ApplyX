import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/organic_background.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTypography.h3(color: AppColors.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: OrganicBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.lg,
            ),
            children: [
              _sectionTitle('General'),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  children: [
                    _settingsRow(
                      Icons.notifications_outlined,
                      'Notifications',
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _settingsRow(
                      Icons.auto_awesome_outlined,
                      'AI Preferences',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              _sectionTitle('Privacy & Data'),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  children: [
                    _settingsRow(Icons.shield_outlined, 'Privacy', onTap: () {}),
                    const Divider(height: 1, color: AppColors.border),
                    _settingsRow(Icons.link, 'Connected Accounts', onTap: () {}),
                    const Divider(height: 1, color: AppColors.border),
                    _settingsRow(
                      Icons.download_outlined,
                      'Export Data',
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _settingsRow(
                      Icons.delete_outline,
                      'Delete Account',
                      textColor: AppColors.danger,
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              _sectionTitle('About'),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  children: [
                    _settingsRow(
                      Icons.info_outline,
                      'About ApplyX',
                      trailing: Text('v1.0.0', style: AppTypography.caption(color: AppColors.textSecondary)),
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _settingsRow(
                      Icons.description_outlined,
                      'Terms of Service',
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _settingsRow(
                      Icons.policy_outlined,
                      'Privacy Policy',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Sign out
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _settingsRow(
                  Icons.logout,
                  'Sign Out',
                  textColor: AppColors.danger,
                  onTap: () async {
                    await ref.read(authRepositoryProvider).signOut();
                  },
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
    return Text(title, style: AppTypography.h3(color: AppColors.textPrimary));
  }

  Widget _settingsRow(
    IconData icon,
    String label, {
    Color? textColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textColor ?? AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body(
                  color: textColor ?? AppColors.textPrimary,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}

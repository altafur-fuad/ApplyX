import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/surface_card.dart';

/// Settings screen.
///
/// design.md § 6.13:
/// Sections: Notifications, AI preferences, Privacy,
/// Connected accounts, Data export/delete, About.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.lg,
          ),
          children: [
            _sectionTitle('General'),
            const SizedBox(height: AppSpacing.md),
            SurfaceCard(
              child: Column(
                children: [
                  _settingsRow(
                    Icons.notifications_outlined,
                    'Notifications',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
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
            SurfaceCard(
              child: Column(
                children: [
                  _settingsRow(
                    Icons.shield_outlined,
                    'Privacy',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _settingsRow(
                    Icons.link,
                    'Connected Accounts',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _settingsRow(
                    Icons.download_outlined,
                    'Export Data',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
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
            SurfaceCard(
              child: Column(
                children: [
                  _settingsRow(
                    Icons.info_outline,
                    'About ApplyX',
                    trailing: Text(
                      'v1.0.0',
                      style: AppTypography.caption(),
                    ),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _settingsRow(
                    Icons.description_outlined,
                    'Terms of Service',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
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
            SurfaceCard(
              child: _settingsRow(
                Icons.logout,
                'Sign Out',
                textColor: AppColors.danger,
                onTap: () {
                  // TODO: Connect to auth service
                },
              ),
            ),

            const SizedBox(height: AppSpacing.section),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: AppTypography.h3());
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: textColor ?? AppColors.textSecondary,
            ),
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

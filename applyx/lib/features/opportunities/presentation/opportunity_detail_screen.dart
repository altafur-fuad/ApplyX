import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/organic_background.dart';
import '../../../core/widgets/app_states.dart';
import 'providers/opportunity_provider.dart';

class OpportunityDetailScreen extends ConsumerWidget {
  const OpportunityDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunityAsync = ref.watch(opportunityDetailProvider(id));
    final matchAsync = ref.watch(opportunityMatchProvider(id));
    final saveState = ref.watch(saveOpportunityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Executive Brief'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTypography.h3(color: AppColors.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: saveState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.bookmark_outline),
            onPressed: saveState.isLoading
                ? null
                : () async {
                    await ref.read(saveOpportunityProvider.notifier).save(id);
                    if (context.mounted) {
                      final error = ref.read(saveOpportunityProvider).error;
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to save opportunity')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opportunity saved!')),
                        );
                      }
                    }
                  },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: OrganicBackground(
        child: SafeArea(
          child: opportunityAsync.when(
            data: (opportunity) {
              return Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
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
                                        opportunity.title,
                                        style: AppTypography.h1(color: AppColors.textPrimary),
                                      ),
                                    ),
                                    matchAsync.maybeWhen(
                                      data: (match) {
                                        final isEligible = match.eligibilityStatus == 'eligible' || match.eligibilityStatus == 'likely_eligible';
                                        return StatusChip(
                                          label: isEligible ? 'Eligible' : 'Review',
                                          color: isEligible ? AppColors.success : AppColors.warning,
                                        );
                                      },
                                      orElse: () => const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // Quick info row
                                Wrap(
                                  spacing: AppSpacing.lg,
                                  runSpacing: AppSpacing.md,
                                  children: [
                                    _infoChip(
                                      Icons.business_outlined,
                                      opportunity.organization,
                                    ),
                                    if (opportunity.location != null)
                                      _infoChip(
                                        Icons.location_on_outlined,
                                        opportunity.location!,
                                      ),
                                    if (opportunity.deadline != null)
                                      _infoChip(
                                        Icons.calendar_today_outlined,
                                        opportunity.deadline!.toLocal().toString().split(' ')[0],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xxl),

                                if (opportunity.description != null && opportunity.description!.isNotEmpty) ...[
                                  Text('Overview', style: AppTypography.h3()),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    opportunity.description!,
                                    style: AppTypography.body(color: AppColors.textSecondary).copyWith(height: 1.6),
                                  ),
                                  const SizedBox(height: AppSpacing.xxl),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Match Analysis Sections
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                            child: matchAsync.when(
                              data: (match) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (match.fitReasons.isNotEmpty) ...[
                                    Text('Why this matches', style: AppTypography.h3()),
                                    const SizedBox(height: AppSpacing.md),
                                    GlassCard(
                                      padding: const EdgeInsets.all(AppSpacing.lg),
                                      child: Column(
                                        children: match.fitReasons.map((reason) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12.0),
                                          child: _matchRow(reason, Icons.check_circle, AppColors.success),
                                        )).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxl),
                                  ],
                                  if (match.missingRequirements.isNotEmpty) ...[
                                    Text('Missing Requirements', style: AppTypography.h3()),
                                    const SizedBox(height: AppSpacing.md),
                                    GlassCard(
                                      padding: const EdgeInsets.all(AppSpacing.lg),
                                      child: Column(
                                        children: match.missingRequirements.map((req) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12.0),
                                          child: _matchRow(req, Icons.warning, AppColors.warning),
                                        )).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxl),
                                  ],
                                  if (match.evidence.isNotEmpty) ...[
                                    Text('AI Evidence', style: AppTypography.h3()),
                                    const SizedBox(height: AppSpacing.md),
                                    GlassCard(
                                      padding: const EdgeInsets.all(AppSpacing.lg),
                                      child: Column(
                                        children: match.evidence.map((ev) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12.0),
                                          child: _matchRow(ev.claim, Icons.auto_awesome, AppColors.aiAccent),
                                        )).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxl),
                                  ],
                                ],
                              ),
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(child: CircularProgressIndicator()),
                              ),
                              error: (err, st) => const SizedBox.shrink(),
                            ),
                          ),
                        ),

                        // Source Link
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Source', style: AppTypography.h3()),
                                const SizedBox(height: AppSpacing.md),
                                GlassCard(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.link,
                                        size: 18,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          opportunity.sourceUrl,
                                          style: AppTypography.caption(
                                            color: AppColors.primary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 100), // padding for FAB/CTA
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const AppLoadingState(message: 'Loading brief...'),
            error: (error, stack) => AppErrorState(
              message: 'Couldn\'t load details.',
              onRetry: () => ref.refresh(opportunityDetailProvider(id)),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: opportunityAsync.maybeWhen(
        data: (opportunity) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          child: AppPrimaryButton(
            label: 'Prepare Application',
            onPressed: () => context.push('${AppRoutes.approval}/$id'),
          ),
        ),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(text, style: AppTypography.caption(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _matchRow(String text, IconData icon, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              text,
              style: AppTypography.bodySmall(color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

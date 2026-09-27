import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/surface_card.dart';
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
        title: const Text('Opportunity'),
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
      body: SafeArea(
        child: opportunityAsync.when(
          data: (opportunity) {
            return Column(
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
                                opportunity.title,
                                style: AppTypography.h2(),
                              ),
                            ),
                            matchAsync.maybeWhen(
                              data: (match) {
                                final isEligible = match.eligibilityStatus == 'eligible' || match.eligibilityStatus == 'likely_eligible';
                                return StatusChip(
                                  label: isEligible ? 'Eligible' : 'Needs Review',
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
                          runSpacing: AppSpacing.sm,
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
                          _sectionTitle('Overview'),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            opportunity.description!,
                            style: AppTypography.body(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],

                        // Match Analysis
                        matchAsync.when(
                          data: (match) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (match.fitReasons.isNotEmpty) ...[
                                _sectionTitle('Why this matches'),
                                const SizedBox(height: AppSpacing.sm),
                                SurfaceCard(
                                  color: AppColors.surfaceElevated,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: match.fitReasons.map((reason) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: _matchRow(reason, Icons.check_circle, AppColors.success),
                                    )).toList(),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                              ],
                              if (match.missingRequirements.isNotEmpty) ...[
                                _sectionTitle('Missing Requirements'),
                                const SizedBox(height: AppSpacing.sm),
                                SurfaceCard(
                                  color: AppColors.surfaceElevated,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: match.missingRequirements.map((req) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: _matchRow(req, Icons.warning, AppColors.warning),
                                    )).toList(),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                              ],
                              if (match.evidence.isNotEmpty) ...[
                                _sectionTitle('Evidence'),
                                const SizedBox(height: AppSpacing.sm),
                                SurfaceCard(
                                  color: AppColors.surfaceElevated,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: match.evidence.map((ev) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: _matchRow(ev.claim, Icons.info_outline, AppColors.aiAccent),
                                    )).toList(),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                              ],
                            ],
                          ),
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (err, st) => const SizedBox.shrink(),
                        ),

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
                                  opportunity.sourceUrl,
                                  style: AppTypography.caption(
                                    color: AppColors.aiAccent,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: AppPrimaryButton(
                    label: 'Prepare Application',
                    onPressed: () => context.push('${AppRoutes.approval}/$id'),
                  ),
                ),
              ],
            );
          },
          loading: () => const AppLoadingState(message: 'Loading details...'),
          error: (error, stack) => AppErrorState(
            message: 'Couldn\'t load details.',
            onRetry: () => ref.refresh(opportunityDetailProvider(id)),
          ),
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

  Widget _matchRow(String text, IconData icon, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

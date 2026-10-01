import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/organic_background.dart';
import '../../../core/widgets/app_states.dart';
import '../../opportunities/presentation/providers/opportunity_provider.dart';
import 'providers/application_provider.dart';
import '../../opportunities/domain/opportunity.dart';

class ApprovalScreen extends ConsumerStatefulWidget {
  const ApprovalScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends ConsumerState<ApprovalScreen> {
  int _step = 0; // 0 = Verification, 1 = Final Approval
  bool _isApproving = false;
  
  final Map<int, bool> _verifiedFacts = {
    0: true,
    1: false,
    2: true,
  };

  @override
  Widget build(BuildContext context) {
    final opportunityAsync = ref.watch(opportunityDetailProvider(widget.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_step == 0 ? 'Verify Facts' : 'Final Review'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTypography.h3(color: AppColors.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
            } else {
              context.pop();
            }
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: OrganicBackground(
        child: SafeArea(
          child: opportunityAsync.when(
            data: (opportunity) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pagePadding,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _step == 0
                            ? _buildVerificationStep(opportunity)
                            : _buildApprovalStep(opportunity),
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
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.9),
                      border: const Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Column(
                      children: [
                        if (_step == 0)
                          AppPrimaryButton(
                            label: 'Continue to Review',
                            icon: Icons.arrow_forward,
                            onPressed: () => setState(() => _step = 1),
                          )
                        else
                          _buildGlowingApproveButton(opportunity),
                        const SizedBox(height: AppSpacing.md),
                        AppSecondaryButton(
                          label: 'Cancel',
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const AppLoadingState(),
            error: (error, stack) => AppErrorState(
              message: 'Failed to load details.',
              onRetry: () => ref.refresh(opportunityDetailProvider(widget.id)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationStep(Opportunity opportunity) {
    return Column(
      key: const ValueKey('step_0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fact_check, color: AppColors.primary, size: 40),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Text(
            'Human Verification',
            style: AppTypography.h2(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            'Verify the agent\'s claims before continuing.',
            style: AppTypography.body(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text('Target Opportunity', style: AppTypography.h3(color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.md),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.business_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opportunity.title, style: AppTypography.body(color: AppColors.textPrimary)),
                    Text(opportunity.organization, style: AppTypography.caption(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text('Fact Verification', style: AppTypography.h3(color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.md),
        _buildVerificationCard(
          index: 0,
          agentClaim: '3+ years with Flutter framework',
          profileFact: 'Resume: "Started Flutter dev in Jan 2022"',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildVerificationCard(
          index: 1,
          agentClaim: 'Willing to relocate to San Francisco',
          profileFact: 'Profile: Location preferences not set',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildVerificationCard(
          index: 2,
          agentClaim: 'Experience with CI/CD and Fastlane',
          profileFact: 'Github: 4 projects using Github Actions & Fastlane',
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildApprovalStep(Opportunity opportunity) {
    return Column(
      key: const ValueKey('step_1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.rocket_launch, color: AppColors.success, size: 40),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Text(
            'Ready to Launch',
            style: AppTypography.h2(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            'Review the generated materials.',
            style: AppTypography.body(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        Text('Generated Packet', style: AppTypography.h3(color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.md),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _packetRow(Icons.description_outlined, 'Resume.pdf', 'Tailored for ${opportunity.organization}'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(color: AppColors.border),
              ),
              _packetRow(Icons.email_outlined, 'Cover Letter', '3-paragraph personalized letter'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(color: AppColors.border),
              ),
              _packetRow(Icons.link, 'Portfolio', 'github.com/altafur-fuad'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // Warning
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('External Submission', style: AppTypography.body(color: AppColors.warning)),
                    const SizedBox(height: 4),
                    Text(
                      'This will submit your application materials directly to the employer. This action cannot be undone.',
                      style: AppTypography.bodySmall(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _packetRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
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
        const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
      ],
    );
  }

  Widget _buildGlowingApproveButton(Opportunity opportunity) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: AppPrimaryButton(
        label: _isApproving ? 'Submitting...' : 'Approve & Submit',
        icon: _isApproving ? Icons.hourglass_empty : Icons.send_rounded,
        onPressed: _isApproving ? null : () async {
          setState(() => _isApproving = true);
          final repo = ref.read(applicationRepositoryProvider);
          final app = await repo.createApplication(widget.id, 'submitted');
          if (!mounted) return;
          setState(() => _isApproving = false);
          if (app != null) {
            ref.invalidate(applicationsProvider);
            context.go(AppRoutes.applicationTracker);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to submit application')),
            );
          }
        },
      ),
    );
  }

  Widget _buildVerificationCard({
    required int index,
    required String agentClaim,
    required String profileFact,
  }) {
    final isVerified = _verifiedFacts[index] ?? false;

    return GestureDetector(
      onTap: () {
        setState(() {
          _verifiedFacts[index] = !isVerified;
        });
      },
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isVerified ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isVerified ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: isVerified
                  ? const Icon(Icons.check, size: 16, color: AppColors.white)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology, size: 14, color: AppColors.aiAccent),
                      const SizedBox(width: 4),
                      Text('Agent Claim', style: AppTypography.caption(color: AppColors.aiAccent)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(agentClaim, style: AppTypography.body(color: AppColors.textPrimary)),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('Profile Fact', style: AppTypography.caption(color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(profileFact, style: AppTypography.bodySmall(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

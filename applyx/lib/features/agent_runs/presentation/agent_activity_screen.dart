import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/surface_card.dart';

/// Agent step data for the activity timeline.
class _AgentStep {
  _AgentStep({
    required this.title,
    required this.description,
    this.status = _StepStatus.queued,
  });

  final String title;
  final String description;
  _StepStatus status;
}

enum _StepStatus { queued, running, completed, approval, failed }

/// Agent Activity screen — the signature ApplyX interaction.
///
/// design.md § 6.6: shows an execution timeline.
/// Each step is expandable. Animation reflects actual agent state.
///
/// IMPORTANT: This simulates agent progress with local state.
/// Real implementation will poll/stream backend agent_run events.
class AgentActivityScreen extends StatefulWidget {
  const AgentActivityScreen({super.key});

  @override
  State<AgentActivityScreen> createState() => _AgentActivityScreenState();
}

class _AgentActivityScreenState extends State<AgentActivityScreen> {
  final List<_AgentStep> _steps = [
    _AgentStep(
      title: 'Goal received',
      description: 'Processing your goal request.',
      status: _StepStatus.completed,
    ),
    _AgentStep(
      title: 'Plan created',
      description: 'Breaking goal into research and analysis tasks.',
      status: _StepStatus.completed,
    ),
    _AgentStep(
      title: 'Searching opportunities',
      description: 'Querying approved sources for matching opportunities.',
      status: _StepStatus.completed,
    ),
    _AgentStep(
      title: 'Checking eligibility',
      description: 'Comparing requirements against your profile.',
      status: _StepStatus.running,
    ),
    _AgentStep(
      title: 'Comparing your profile',
      description: 'Analyzing skill and experience fit.',
    ),
    _AgentStep(
      title: 'Preparing documents',
      description: 'Drafting tailored application materials.',
    ),
    _AgentStep(
      title: 'Verification',
      description: 'Verifying claims and source freshness.',
    ),
  ];

  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  /// Simulates agent progress by advancing one step at a time.
  /// Clearly labeled: this is mock behavior for UI development.
  void _startSimulation() {
    _simulationTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        final runningIndex =
            _steps.indexWhere((s) => s.status == _StepStatus.running);
        if (runningIndex == -1) {
          timer.cancel();
          return;
        }

        setState(() {
          _steps[runningIndex].status = _StepStatus.completed;
          if (runningIndex + 1 < _steps.length) {
            _steps[runningIndex + 1].status = _StepStatus.running;
          }
        });

        // When all steps complete, allow navigation
        if (_steps.every((s) => s.status == _StepStatus.completed)) {
          timer.cancel();
        }
      },
    );
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  bool get _isComplete =>
      _steps.every((s) => s.status == _StepStatus.completed);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agent Activity'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Goal summary
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.lg,
                AppSpacing.pagePadding,
                AppSpacing.xl,
              ),
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Goal', style: AppTypography.label()),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Find paid remote Flutter internships',
                      style: AppTypography.h3(),
                    ),
                  ],
                ),
              ),
            ),

            // Timeline
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return _AgentStepTile(
                    step: _steps[index],
                    isLast: index == _steps.length - 1,
                  );
                },
              ),
            ),

            // View results button
            if (_isComplete)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.lg,
                  AppSpacing.pagePadding,
                  AppSpacing.section,
                ),
                child: AppPrimaryButton(
                  label: 'View Results',
                  onPressed: () =>
                      context.push(AppRoutes.opportunityResults),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Single step in the agent timeline.
class _AgentStepTile extends StatelessWidget {
  const _AgentStepTile({
    required this.step,
    required this.isLast,
  });

  final _AgentStep step;
  final bool isLast;

  Color get _dotColor {
    switch (step.status) {
      case _StepStatus.completed:
        return AppColors.agentCompleted;
      case _StepStatus.running:
        return AppColors.agentActive;
      case _StepStatus.approval:
        return AppColors.agentApproval;
      case _StepStatus.failed:
        return AppColors.agentFailed;
      case _StepStatus.queued:
        return AppColors.agentQueued;
    }
  }

  IconData get _icon {
    switch (step.status) {
      case _StepStatus.completed:
        return Icons.check_circle;
      case _StepStatus.running:
        return Icons.sync;
      case _StepStatus.approval:
        return Icons.front_hand;
      case _StepStatus.failed:
        return Icons.error;
      case _StepStatus.queued:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Icon(_icon, color: _dotColor, size: 22),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: AppTypography.body(
                      color: step.status == _StepStatus.queued
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.description,
                    style: AppTypography.caption(),
                  ),
                  if (step.status == _StepStatus.running) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        backgroundColor:
                            AppColors.aiAccent.withValues(alpha: 0.15),
                        color: AppColors.aiAccent,
                        minHeight: 3,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

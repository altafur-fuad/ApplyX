import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/app_states.dart';
import 'providers/agent_provider.dart';
import '../../goals/presentation/providers/goal_provider.dart';
import '../domain/agent_run.dart';

class AgentActivityScreen extends ConsumerStatefulWidget {
  const AgentActivityScreen({super.key});

  @override
  ConsumerState<AgentActivityScreen> createState() => _AgentActivityScreenState();
}

class _AgentActivityScreenState extends ConsumerState<AgentActivityScreen> {
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  void _startSimulation() {
    _simulationTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        ref.read(agentRunProvider.notifier).simulateProgress();
        
        final state = ref.read(agentRunProvider);
        if (state.value?.status == AgentStatus.completed || state.value?.status == AgentStatus.failed) {
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

  @override
  Widget build(BuildContext context) {
    final agentRunAsync = ref.watch(agentRunProvider);
    final activeGoalAsync = ref.watch(activeGoalProvider);

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
        child: agentRunAsync.when(
          data: (run) {
            if (run == null) {
              return const AppEmptyState(
                icon: Icons.auto_awesome,
                title: 'No active agent',
                message: 'Start a goal to run the agent.',
              );
            }

            final isComplete = run.status == AgentStatus.completed;

            return Column(
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
                        activeGoalAsync.when(
                          data: (goal) => Text(
                            goal?.title ?? 'Unknown Goal',
                            style: AppTypography.h3(),
                          ),
                          loading: () => const Text('Loading...'),
                          error: (_, __) => const Text('Error loading goal'),
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
                    itemCount: run.steps.length,
                    itemBuilder: (context, index) {
                      return _AgentStepTile(
                        step: run.steps[index],
                        isLast: index == run.steps.length - 1,
                      );
                    },
                  ),
                ),

                // View results button
                if (isComplete)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      AppSpacing.lg,
                      AppSpacing.pagePadding,
                      AppSpacing.section,
                    ),
                    child: AppPrimaryButton(
                      label: 'View Results',
                      onPressed: () => context.push(AppRoutes.opportunityResults),
                    ),
                  ),
              ],
            );
          },
          loading: () => const AppLoadingState(message: 'Initializing Agent...'),
          error: (error, stack) => AppErrorState(
            message: 'Failed to connect to agent.',
            onRetry: () => ref.refresh(agentRunProvider),
          ),
        ),
      ),
    );
  }
}

class _AgentStepTile extends StatelessWidget {
  const _AgentStepTile({
    required this.step,
    required this.isLast,
  });

  final AgentStep step;
  final bool isLast;

  Color get _dotColor {
    switch (step.status) {
      case AgentStatus.completed:
        return AppColors.agentCompleted;
      case AgentStatus.running:
        return AppColors.agentActive;
      case AgentStatus.approval:
        return AppColors.agentApproval;
      case AgentStatus.failed:
        return AppColors.agentFailed;
      case AgentStatus.queued:
      case AgentStatus.cancelled:
        return AppColors.agentQueued;
    }
  }

  IconData get _icon {
    switch (step.status) {
      case AgentStatus.completed:
        return Icons.check_circle;
      case AgentStatus.running:
        return Icons.sync;
      case AgentStatus.approval:
        return Icons.front_hand;
      case AgentStatus.failed:
        return Icons.error;
      case AgentStatus.queued:
      case AgentStatus.cancelled:
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
                      color: step.status == AgentStatus.queued
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.description,
                    style: AppTypography.caption(),
                  ),
                  if (step.status == AgentStatus.running) ...[
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

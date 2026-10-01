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
import 'providers/agent_provider.dart';
import '../../goals/presentation/providers/goal_provider.dart';
import '../domain/agent_run.dart';

class AgentActivityScreen extends ConsumerWidget {
  const AgentActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentRunAsync = ref.watch(agentRunProvider);
    final activeGoalAsync = ref.watch(activeGoalProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agent Activity'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTypography.h3(color: AppColors.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Cancel polling when leaving the screen
            ref.read(agentRunProvider.notifier).stopPolling();
            context.pop();
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: OrganicBackground(
        child: SafeArea(
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
              final isRunning = run.status == AgentStatus.running ||
                  run.status == AgentStatus.planning ||
                  run.status == AgentStatus.queued;
              final isFailed = run.status == AgentStatus.failed;

              return Column(
                children: [
                  // Goal summary
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      AppSpacing.md,
                      AppSpacing.pagePadding,
                      AppSpacing.xl,
                    ),
                    child: GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.flag_outlined, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text('Current Goal', style: AppTypography.label(color: AppColors.primary)),
                            ],
                          ),
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

                  if (isRunning && run.progress != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.white),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: run.progress! / 100,
                                  minHeight: 8,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.aiAccent),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text('${run.progress}%', style: AppTypography.label(color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Timeline
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.white.withValues(alpha: 0.5)),
                      ),
                      child: ListView.builder(
                        itemCount: run.events.length,
                        itemBuilder: (context, index) {
                          return _AgentEventTile(
                            event: run.events[index],
                            isLast: index == run.events.length - 1,
                            runStatus: run.status,
                          );
                        },
                      ),
                    ),
                  ),

                  // View results or Retry button
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
                        onPressed: () =>
                            context.push(AppRoutes.opportunityResults),
                      ),
                    ),
                  if (isFailed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding,
                        AppSpacing.lg,
                        AppSpacing.pagePadding,
                        AppSpacing.section,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            run.error ?? 'Agent run failed.',
                            style: AppTypography.bodySmall(color: AppColors.danger),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppPrimaryButton(
                            label: 'Cancel',
                            onPressed: () => context.pop(),
                          ),
                        ],
                      ),
                    ),
                  if (isRunning)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding,
                        AppSpacing.lg,
                        AppSpacing.pagePadding,
                        AppSpacing.section,
                      ),
                      child: TextButton(
                        onPressed: () async {
                          try {
                            await ref.read(agentRunProvider.notifier).cancelRun();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to cancel run.')),
                              );
                            }
                          }
                        },
                        child: const Text('Cancel Run', style: TextStyle(color: AppColors.danger)),
                      ),
                    ),
                ],
              );
            },
            loading: () =>
                const AppLoadingState(message: 'Initializing Agent...'),
            error: (error, stack) => AppErrorState(
              message: 'Failed to connect to agent.',
              onRetry: () => ref.read(agentRunProvider.notifier).startRun(''), 
            ),
          ),
        ),
      ),
    );
  }
}

class _AgentEventTile extends StatelessWidget {
  const _AgentEventTile({required this.event, required this.isLast, required this.runStatus});

  final AgentRunEvent event;
  final bool isLast;
  final AgentStatus runStatus;

  Color get _dotColor {
    if (event.eventType.contains('failed') || event.eventType.contains('error')) {
      return AppColors.danger;
    }
    if (event.eventType.contains('completed') || event.eventType.contains('found')) {
      return AppColors.success;
    }
    return AppColors.primary;
  }

  IconData get _icon {
    if (event.eventType.contains('failed') || event.eventType.contains('error')) {
      return Icons.error;
    }
    if (event.eventType.contains('completed') || event.eventType.contains('found')) {
      return Icons.check_circle;
    }
    return Icons.sync;
  }

  String get _title {
    final type = event.eventType.toLowerCase();
    if (type == 'run_created') return 'Agent initialized';
    if (type == 'plan_created') return 'Plan created';
    if (type == 'task_started') return 'Task started: ${event.message ?? event.payload['task_name'] ?? ''}';
    if (type == 'task_completed') return 'Task completed: ${event.message ?? ''}';
    if (type == 'source_found') return 'Source found: ${event.message ?? ''}';
    if (type == 'run_completed') return 'Goal achieved';
    if (type == 'run_failed') return 'Run failed';
    return event.message ?? event.eventType;
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _dotColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, color: _dotColor, size: 20),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6), // align with icon
                  Text(
                    _title,
                    style: AppTypography.body(color: AppColors.textPrimary),
                  ),
                  if (isLast && (runStatus == AgentStatus.running || runStatus == AgentStatus.planning)) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.white),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Working...', style: AppTypography.bodySmall(color: AppColors.primary)),
                        ],
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

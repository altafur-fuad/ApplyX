import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/organic_background.dart';
import '../../../core/network/api_exception.dart';
import '../domain/goal.dart';
import 'providers/goal_provider.dart';
import '../../agent_runs/presentation/providers/agent_provider.dart';

class CreateGoalScreen extends ConsumerStatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _goalController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  static const List<String> _exampleChips = [
    'Find an internship',
    'Find research opportunities',
    'Prepare for hackathons',
    'Entry-level jobs',
  ];

  @override
  void initState() {
    super.initState();
    // Auto focus the input to make it feel conversational immediately
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _onStartAgent() async {
    final text = _goalController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
    });
    _focusNode.unfocus();

    try {
      final repository = ref.read(goalRepositoryProvider);
      
      final request = CreateGoalRequest(
        title: text.length > 50 ? '${text.substring(0, 47)}...' : text,
        rawGoal: text,
      );

      final goal = await repository.createGoal(request);
      
      ref.invalidate(activeGoalProvider);

      await ref.read(agentRunProvider.notifier).startRun(goal.id);

      if (mounted) {
        context.pushReplacement(AppRoutes.agentActivity);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onChipTap(String text) {
    if (_isLoading) return;
    _goalController.text = text;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: _isLoading ? null : () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: OrganicBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xxl),
                      
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppColors.primary, size: 28),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'New Goal',
                            style: AppTypography.h3(color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      Text(
                        'What are you\ntrying to achieve?',
                        style: AppTypography.h1(color: AppColors.textPrimary).copyWith(fontSize: 36),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Give your agent a clear directive.',
                        style: AppTypography.body(color: AppColors.textSecondary),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Conversational input using GlassCard
                      GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: TextField(
                          controller: _goalController,
                          focusNode: _focusNode,
                          maxLines: 5,
                          minLines: 2,
                          style: AppTypography.body(color: AppColors.textPrimary).copyWith(fontSize: 20, height: 1.4),
                          onChanged: (_) => setState(() {}),
                          enabled: !_isLoading,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _onStartAgent(),
                          decoration: InputDecoration(
                            hintText: 'e.g. Find paid remote Flutter internships suitable for a final-year student...',
                            hintStyle: AppTypography.body(color: AppColors.textSecondary.withValues(alpha: 0.5)).copyWith(fontSize: 20, height: 1.4),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Example chips
                      Text('Suggestions', style: AppTypography.label(color: AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _exampleChips.map((chip) {
                          return _SuggestionChip(
                            label: chip,
                            onTap: _isLoading ? null : () => _onChipTap(chip),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 100), // FAB padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        child: AppPrimaryButton(
          label: _isLoading ? 'Starting...' : 'Start Agent',
          icon: _isLoading ? Icons.hourglass_empty : Icons.auto_awesome,
          onPressed: _goalController.text.trim().isEmpty || _isLoading
              ? null
              : _onStartAgent,
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.8)),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

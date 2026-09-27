import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/network/api_exception.dart';
import '../domain/goal.dart';
import 'providers/goal_provider.dart';

/// Create Goal screen.
///
/// design.md § 6.5:
/// Hero copy: "What are you trying to achieve?"
/// Input: large text field.
/// Examples as chips.
/// CTA: "Start Agent"
class CreateGoalScreen extends ConsumerStatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _goalController = TextEditingController();
  bool _isLoading = false;

  static const List<String> _exampleChips = [
    'Find an internship',
    'Find research opportunities',
    'Prepare for hackathons',
    'Entry-level jobs',
  ];

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _onStartAgent() async {
    final text = _goalController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(goalRepositoryProvider);
      
      final request = CreateGoalRequest(
        title: text.length > 50 ? '${text.substring(0, 47)}...' : text,
        rawGoal: text,
      );

      await repository.createGoal(request);
      
      // Invalidate the active goal provider so it refetches the newly created active goal
      ref.invalidate(activeGoalProvider);

      if (mounted) {
        context.push(AppRoutes.agentActivity);
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
          SnackBar(content: Text('An unexpected error occurred.')),
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
        title: const Text('New Goal'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxl),

              Text(
                'What are you\ntrying to achieve?',
                style: AppTypography.h1(),
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                'Describe your goal in your own words.',
                style: AppTypography.bodySmall(),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Goal input
              TextField(
                controller: _goalController,
                maxLines: 4,
                style: AppTypography.body(),
                onChanged: (_) => setState(() {}),
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. Find paid remote Flutter internships suitable for a final-year CSE student.',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Example chips
              Text('Try an example', style: AppTypography.label()),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _exampleChips.map((chip) {
                  return ActionChip(
                    label: Text(chip),
                    onPressed: _isLoading ? null : () => _onChipTap(chip),
                  );
                }).toList(),
              ),

              const Spacer(),

              // CTA
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.section),
                child: AppPrimaryButton(
                  label: _isLoading ? 'Starting...' : 'Start Agent',
                  icon: _isLoading ? Icons.hourglass_empty : Icons.auto_awesome,
                  onPressed: _goalController.text.trim().isEmpty || _isLoading
                      ? null
                      : _onStartAgent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

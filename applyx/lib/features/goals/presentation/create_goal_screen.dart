import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';

/// Create Goal screen.
///
/// design.md § 6.5:
/// Hero copy: "What are you trying to achieve?"
/// Input: large text field.
/// Examples as chips.
/// CTA: "Start Agent"
class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _goalController = TextEditingController();

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

  void _onStartAgent() {
    context.push(AppRoutes.agentActivity);
  }

  void _onChipTap(String text) {
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
          onPressed: () => context.pop(),
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
                    onPressed: () => _onChipTap(chip),
                  );
                }).toList(),
              ),

              const Spacer(),

              // CTA
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.section),
                child: AppPrimaryButton(
                  label: 'Start Agent',
                  icon: Icons.auto_awesome,
                  onPressed:
                      _goalController.text.trim().isEmpty ? null : _onStartAgent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
import 'providers/application_provider.dart';
import 'providers/application_checklist_provider.dart';
import '../../documents/presentation/providers/application_document_provider.dart';

class ApplicationDetailScreen extends ConsumerStatefulWidget {
  const ApplicationDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends ConsumerState<ApplicationDetailScreen> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final applicationListAsync = ref.watch(applicationsProvider);
    final checklistAsync = ref.watch(applicationChecklistProvider(widget.id));
    final documentsAsync = ref.watch(applicationDocumentsProvider(widget.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Application Detail'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTypography.h3(color: AppColors.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: OrganicBackground(
        child: SafeArea(
          child: applicationListAsync.when(
            data: (applications) {
              final app = applications.firstWhere(
                (a) => a.id == widget.id,
                orElse: () => throw Exception('Application not found'),
              );
              
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.lg),
                          Text(app.title, style: AppTypography.h1(color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(app.organization, style: AppTypography.h3(color: AppColors.textSecondary)),
                          
                          const SizedBox(height: AppSpacing.xxl),

                          // Checklist
                          Text('Readiness Checklist', style: AppTypography.h3(color: AppColors.textPrimary)),
                          const SizedBox(height: AppSpacing.md),
                          checklistAsync.when(
                            data: (checklist) {
                              return GlassCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  children: checklist.map((item) {
                                    final isComplete = item['is_complete'] == true;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                      child: Row(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: isComplete ? AppColors.success : AppColors.surface,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isComplete ? AppColors.success : AppColors.border,
                                                width: 2,
                                              ),
                                            ),
                                            child: isComplete
                                                ? const Icon(Icons.check, size: 16, color: AppColors.white)
                                                : null,
                                          ),
                                          const SizedBox(width: AppSpacing.md),
                                          Expanded(
                                            child: Text(
                                              item['label'] ?? '',
                                              style: AppTypography.body(
                                                color: isComplete ? AppColors.textPrimary : AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (_, __) => const Text('Error loading checklist'),
                          ),

                          const SizedBox(height: AppSpacing.xxl),

                          // Documents
                          Text('Application Documents', style: AppTypography.h3(color: AppColors.textPrimary)),
                          const SizedBox(height: AppSpacing.md),
                          
                          documentsAsync.when(
                            data: (documents) {
                              if (documents.isEmpty) {
                                return GlassCard(
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  child: Center(
                                    child: Text(
                                      'No documents generated yet.',
                                      style: AppTypography.bodySmall(color: AppColors.textSecondary),
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: documents.map((doc) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                    child: GlassCard(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      onTap: () => context.push('${AppRoutes.applicationTracker}/document-editor/${doc.id}', extra: doc),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.aiAccent.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.description_outlined, color: AppColors.aiAccent, size: 24),
                                          ),
                                          const SizedBox(width: AppSpacing.md),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(doc.title, style: AppTypography.body(color: AppColors.textPrimary)),
                                                Text('Version ${doc.version} • ${doc.kind}', style: AppTypography.caption(color: AppColors.textSecondary)),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (_, __) => const Text('Error loading documents'),
                          ),

                          const SizedBox(height: AppSpacing.xxl),
                          
                          Row(
                            children: [
                              Expanded(
                                child: AppSecondaryButton(
                                  label: 'Draft Resume',
                                  icon: Icons.edit_document,
                                  onPressed: _isGenerating ? null : () => _generateDoc('resume_bullets', 'Focus on matching requirements.'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: AppSecondaryButton(
                                  label: 'Draft Letter',
                                  icon: Icons.email_outlined,
                                  onPressed: _isGenerating ? null : () => _generateDoc('cover_letter', 'Write a formal cover letter.'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 100), // padding for FAB
                        ],
                      ),
                    ),
                  ),

                  // Floating bottom CTA
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
                    child: AppPrimaryButton(
                      label: 'Verify & Submit',
                      icon: Icons.fact_check,
                      onPressed: () => context.push('${AppRoutes.approval}/${app.opportunityId}'),
                    ),
                  ),
                ],
              );
            },
            loading: () => const AppLoadingState(message: 'Loading details...'),
            error: (_, __) => const AppErrorState(message: 'Error'),
          ),
        ),
      ),
    );
  }

  Future<void> _generateDoc(String kind, String instruction) async {
    setState(() => _isGenerating = true);
    final repo = ref.read(applicationDocumentRepositoryProvider);
    final doc = await repo.generateDocument(widget.id, kind, instruction);
    setState(() => _isGenerating = false);
    
    if (doc != null && mounted) {
      ref.invalidate(applicationDocumentsProvider(widget.id));
      ref.invalidate(applicationChecklistProvider(widget.id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document generated!')));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate document')));
      }
    }
  }
}

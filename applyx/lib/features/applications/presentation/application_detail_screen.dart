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
    // we can use a provider to fetch a single application, but for now we might map from the list
    // or just assume we have it. Let's create an applicationByIdProvider.
    final applicationListAsync = ref.watch(applicationsProvider);
    final checklistAsync = ref.watch(applicationChecklistProvider(widget.id));
    final documentsAsync = ref.watch(applicationDocumentsProvider(widget.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Application Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: applicationListAsync.when(
          data: (applications) {
            final app = applications.firstWhere((a) => a.id == widget.id, orElse: () => throw Exception('Application not found'));
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.title, style: AppTypography.h2()),
                  const SizedBox(height: 4),
                  Text(app.organization, style: AppTypography.bodySmall(color: AppColors.textSecondary)),
                  
                  const SizedBox(height: AppSpacing.xxl),

                  Text('Checklist', style: AppTypography.h3()),
                  const SizedBox(height: AppSpacing.md),
                  checklistAsync.when(
                    data: (checklist) {
                      return SurfaceCard(
                        color: AppColors.surfaceElevated,
                        child: Column(
                          children: checklist.map((item) {
                            final isComplete = item['is_complete'] == true;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Row(
                                children: [
                                  Icon(
                                    isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: isComplete ? AppColors.success : AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(child: Text(item['label'] ?? '', style: AppTypography.body())),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error loading checklist'),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                  Text('Application Documents', style: AppTypography.h3()),
                  const SizedBox(height: AppSpacing.md),
                  
                  documentsAsync.when(
                    data: (documents) {
                      if (documents.isEmpty) {
                        return const Text('No documents generated yet.');
                      }
                      return Column(
                        children: documents.map((doc) {
                          return SurfaceCard(
                            color: AppColors.surfaceElevated,
                            onTap: () => context.push('${AppRoutes.applicationTracker}/document-editor/${doc.id}', extra: doc),
                            child: Row(
                              children: [
                                const Icon(Icons.description_outlined, color: AppColors.aiAccent),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(doc.title, style: AppTypography.body()),
                                      Text('Version ${doc.version} • ${doc.kind}', style: AppTypography.caption()),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error loading documents'),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                  
                  Row(
                    children: [
                      Expanded(
                        child: AppSecondaryButton(
                          label: 'Draft Resume',
                          onPressed: _isGenerating ? null : () => _generateDoc('resume_bullets', 'Focus on matching requirements.'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppSecondaryButton(
                          label: 'Draft Cover Letter',
                          onPressed: _isGenerating ? null : () => _generateDoc('cover_letter', 'Write a formal cover letter.'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppPrimaryButton(
                    label: 'Verify & Submit',
                    onPressed: () => context.push('${AppRoutes.approval}/${app.opportunityId}'),
                  )
                ],
              ),
            );
          },
          loading: () => const AppLoadingState(),
          error: (_, __) => const AppErrorState(message: 'Error'),
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

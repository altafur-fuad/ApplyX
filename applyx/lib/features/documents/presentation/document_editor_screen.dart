import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/application_document.dart';
import 'providers/application_document_provider.dart';

class DocumentEditorScreen extends ConsumerStatefulWidget {
  const DocumentEditorScreen({super.key, required this.document});

  final ApplicationDocument document;

  @override
  ConsumerState<DocumentEditorScreen> createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends ConsumerState<DocumentEditorScreen> {
  late TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.document.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit ${widget.document.title}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveDocument,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Version ${widget.document.version}', style: AppTypography.caption()),
                  TextButton(
                    onPressed: _showVersionHistory,
                    child: const Text('View History'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    style: AppTypography.body(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveDocument() async {
    setState(() => _isSaving = true);
    final repo = ref.read(applicationDocumentRepositoryProvider);
    final updated = await repo.updateDocument(widget.document.id, _controller.text);
    
    if (!mounted) return;
    setState(() => _isSaving = false);
    
    if (updated != null) {
      if (widget.document.applicationId != null) {
        ref.invalidate(applicationDocumentsProvider(widget.document.applicationId!));
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document saved!')));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save document')));
    }
  }

  void _showVersionHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final versionsAsync = ref.watch(documentVersionsProvider(widget.document.id));
            
            return versionsAsync.when(
              data: (versions) {
                if (versions.isEmpty) {
                  return const Center(child: Text('No version history.'));
                }
                return ListView.builder(
                  itemCount: versions.length,
                  itemBuilder: (context, index) {
                    final v = versions[index];
                    return ListTile(
                      title: Text('Version ${v.version}'),
                      subtitle: Text(v.createdAt.toLocal().toString()),
                      onTap: () {
                        setState(() {
                          _controller.text = v.content;
                        });
                        context.pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loaded version ${v.version}')));
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error loading history: $e')),
            );
          },
        );
      },
    );
  }
}

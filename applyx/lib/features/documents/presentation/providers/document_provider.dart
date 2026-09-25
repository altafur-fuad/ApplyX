import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/document_repository.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return SupabaseDocumentRepository(Supabase.instance.client);
});

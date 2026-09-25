import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class DocumentRepository {
  Future<String> uploadDocument({
    required String filePath,
    required String fileName,
  });

  Future<Uint8List> downloadDocument(String path);
  Future<void> deleteDocument(String path);
}

class SupabaseDocumentRepository implements DocumentRepository {
  final SupabaseClient _supabase;
  static const String _bucketName = 'documents';

  SupabaseDocumentRepository(this._supabase);

  @override
  Future<String> uploadDocument({
    required String filePath,
    required String fileName,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final file = File(filePath);
    final fileExt = fileName.split('.').last;
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    await _supabase.storage
        .from(_bucketName)
        .upload(
          path,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return path;
  }

  @override
  Future<Uint8List> downloadDocument(String path) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Ensure users can only download their own documents
    if (!path.startsWith('$userId/')) {
      throw Exception('Unauthorized to access this document');
    }

    return await _supabase.storage.from(_bucketName).download(path);
  }

  @override
  Future<void> deleteDocument(String path) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    if (!path.startsWith('$userId/')) {
      throw Exception('Unauthorized to access this document');
    }

    await _supabase.storage.from(_bucketName).remove([path]);
  }
}

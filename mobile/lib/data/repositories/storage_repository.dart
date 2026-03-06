import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';

class StorageRepository {
  /// Uploads a [file] to the given [bucket] at the specified [path].
  /// Returns the public URL of the uploaded file.
  Future<String> uploadFile(String bucket, String path, File file) async {
    try {
      await supabase.storage.from(bucket).upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      final publicUrl = supabase.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload file to $bucket/$path: $e');
    }
  }

  /// Deletes a file from the given [bucket] at the specified [path].
  Future<void> deleteFile(String bucket, String path) async {
    try {
      await supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception('Failed to delete file from $bucket/$path: $e');
    }
  }

  /// Returns the public URL for a file in the given [bucket] at [path].
  String getPublicUrl(String bucket, String path) {
    return supabase.storage.from(bucket).getPublicUrl(path);
  }
}

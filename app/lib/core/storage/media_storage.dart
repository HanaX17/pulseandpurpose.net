import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase.dart';

/// Abstraction over the object store so the backing service can change
/// (Supabase Storage today; Cloudflare R2 later for $0 egress) without
/// touching feature code.
abstract class MediaStorage {
  /// Uploads [file] and returns the stored object path/key.
  Future<String> upload({
    required String familyId,
    required String postId,
    required File file,
    required String contentType,
  });

  /// Returns a URL the app can load (signed for private buckets).
  Future<String> urlFor(String storagePath);

  Future<void> delete(String storagePath);
}

/// Supabase Storage implementation against the private `media` bucket.
class SupabaseMediaStorage implements MediaStorage {
  SupabaseMediaStorage(this._client);
  final SupabaseClient _client;
  static const _bucket = 'media';

  @override
  Future<String> upload({
    required String familyId,
    required String postId,
    required File file,
    required String contentType,
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    final key =
        '$familyId/$postId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage.from(_bucket).upload(
          key,
          file,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    return key;
  }

  @override
  Future<String> urlFor(String storagePath) {
    // Private bucket -> short-lived signed URL.
    return _client.storage.from(_bucket).createSignedUrl(storagePath, 3600);
  }

  @override
  Future<void> delete(String storagePath) async {
    await _client.storage.from(_bucket).remove([storagePath]);
  }
}

final mediaStorageProvider = Provider<MediaStorage>((ref) {
  return SupabaseMediaStorage(ref.watch(supabaseProvider));
});

/// Caches signed URLs per storage path for the widget tree's lifetime.
final mediaUrlProvider =
    FutureProvider.family<String, String>((ref, storagePath) {
  return ref.watch(mediaStorageProvider).urlFor(storagePath);
});

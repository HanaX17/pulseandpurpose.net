import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/storage/media_storage.dart';
import '../core/supabase.dart';
import 'models.dart';

/// All data access for the app. Reads rely on RLS to scope rows to the
/// caller's families; we never filter by family in a way that could leak.
class Repository {
  Repository(this._ref);
  final Ref _ref;

  SupabaseClient get _db => _ref.read(supabaseProvider);
  String get _uid => _db.auth.currentUser!.id;

  // ---- Families ----------------------------------------------------------
  Future<List<Family>> myFamilies() async {
    // family_members RLS lets a user see only their own memberships.
    final rows = await _db
        .from('family_members')
        .select('families(*)')
        .eq('user_id', _uid);
    return rows
        .map((r) => Family.fromMap(r['families'] as Map<String, dynamic>))
        .toList();
  }

  Future<Family> createFamily({
    required String name,
    String? babyName,
    DateTime? babyBirthday,
  }) async {
    final row = await _db
        .from('families')
        .insert({
          'name': name,
          'baby_name': babyName,
          'baby_birthday': babyBirthday?.toIso8601String().split('T').first,
          'created_by': _uid,
        })
        .select()
        .single();
    return Family.fromMap(row);
  }

  /// Redeems an invite code via the Edge Function; returns the joined family id.
  Future<String> redeemInvite(String code, {String? relation}) async {
    final res = await _db.functions.invoke('redeem-invite', body: {
      'code': code,
      'relation': relation,
    });
    final data = res.data as Map<String, dynamic>;
    if (data['error'] != null) throw Exception(data['error']);
    return data['family_id'] as String;
  }

  Future<List<FamilyMember>> members(String familyId) async {
    final rows = await _db
        .from('family_members')
        .select('user_id, role, relation, profiles(*)')
        .eq('family_id', familyId);
    return rows.map((r) => FamilyMember.fromMap(r)).toList();
  }

  Future<String> createInvite(String familyId, {String? relation}) async {
    final code = _randomCode();
    await _db.from('invitations').insert({
      'family_id': familyId,
      'code': code,
      'created_by': _uid,
      'relation': relation,
    });
    return code;
  }

  // ---- Feed --------------------------------------------------------------
  Future<List<Post>> feed(String familyId) async {
    final rows = await _db
        .from('posts')
        .select('*, profiles(*), media(*)')
        .eq('family_id', familyId)
        .order('recorded_at', ascending: false)
        .limit(50);
    return rows.map((r) => Post.fromMap(r)).toList();
  }

  Future<Post> createPost({
    required String familyId,
    String? content,
    required List<File> images,
    DateTime? recordedAt,
  }) async {
    final postRow = await _db
        .from('posts')
        .insert({
          'family_id': familyId,
          'author_id': _uid,
          'content': content,
          'recorded_at': (recordedAt ?? DateTime.now()).toIso8601String(),
        })
        .select()
        .single();
    final post = Post.fromMap(postRow);

    final storage = _ref.read(mediaStorageProvider);
    for (var i = 0; i < images.length; i++) {
      // TODO: compress + generate a thumbnail before upload to cut storage/egress.
      final path = await storage.upload(
        familyId: familyId,
        postId: post.id,
        file: images[i],
        contentType: 'image/jpeg',
      );
      await _db.from('media').insert({
        'post_id': post.id,
        'family_id': familyId,
        'storage_path': path,
        'type': 'image',
        'position': i,
      });
    }
    return post;
  }

  // ---- Comments & reactions ---------------------------------------------
  Future<List<Comment>> comments(String postId) async {
    final rows = await _db
        .from('comments')
        .select('*, profiles(*)')
        .eq('post_id', postId)
        .order('created_at');
    return rows.map((r) => Comment.fromMap(r)).toList();
  }

  Future<void> addComment(Post post, String content) async {
    await _db.from('comments').insert({
      'post_id': post.id,
      'family_id': post.familyId,
      'author_id': _uid,
      'content': content,
    });
  }

  Future<void> toggleReaction(Post post, {String emoji = '❤️'}) async {
    final existing = await _db
        .from('reactions')
        .select('post_id')
        .eq('post_id', post.id)
        .eq('user_id', _uid)
        .eq('emoji', emoji)
        .maybeSingle();
    if (existing == null) {
      await _db.from('reactions').insert({
        'post_id': post.id,
        'family_id': post.familyId,
        'user_id': _uid,
        'emoji': emoji,
      });
    } else {
      await _db
          .from('reactions')
          .delete()
          .eq('post_id', post.id)
          .eq('user_id', _uid)
          .eq('emoji', emoji);
    }
  }

  // ---- Growth ------------------------------------------------------------
  Future<List<GrowthRecord>> growth(String familyId) async {
    final rows = await _db
        .from('growth_records')
        .select()
        .eq('family_id', familyId)
        .order('recorded_at', ascending: false);
    return rows.map((r) => GrowthRecord.fromMap(r)).toList();
  }

  Future<void> addGrowth({
    required String familyId,
    required String metric,
    double? value,
    String? unit,
    String? note,
    required DateTime recordedAt,
  }) async {
    await _db.from('growth_records').insert({
      'family_id': familyId,
      'author_id': _uid,
      'metric': metric,
      'value': value,
      'unit': unit,
      'note': note,
      'recorded_at': recordedAt.toIso8601String().split('T').first,
    });
  }

  static String _randomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    final buf = StringBuffer();
    var seed = now;
    for (var i = 0; i < 8; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      buf.write(chars[seed % chars.length]);
    }
    return buf.toString();
  }
}

final repositoryProvider = Provider<Repository>((ref) => Repository(ref));

/// The user's families. MVP uses the first one as the "active" circle.
final myFamiliesProvider = FutureProvider<List<Family>>((ref) {
  ref.watch(currentUserProvider); // refresh on sign-in/out
  return ref.watch(repositoryProvider).myFamilies();
});

final currentFamilyProvider = Provider<Family?>((ref) {
  final families = ref.watch(myFamiliesProvider).valueOrNull;
  return (families == null || families.isEmpty) ? null : families.first;
});

final feedProvider =
    FutureProvider.family<List<Post>, String>((ref, familyId) {
  return ref.watch(repositoryProvider).feed(familyId);
});

final membersProvider =
    FutureProvider.family<List<FamilyMember>, String>((ref, familyId) {
  return ref.watch(repositoryProvider).members(familyId);
});

final commentsProvider =
    FutureProvider.family<List<Comment>, String>((ref, postId) {
  return ref.watch(repositoryProvider).comments(postId);
});

final growthProvider =
    FutureProvider.family<List<GrowthRecord>, String>((ref, familyId) {
  return ref.watch(repositoryProvider).growth(familyId);
});

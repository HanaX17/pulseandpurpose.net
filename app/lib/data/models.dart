/// Plain data models mirroring the Postgres tables. Each `fromMap` matches the
/// column names returned by Supabase/PostgREST.

class Family {
  Family({
    required this.id,
    required this.name,
    this.babyName,
    this.babyBirthday,
    this.babyAvatarUrl,
  });

  final String id;
  final String name;
  final String? babyName;
  final DateTime? babyBirthday;
  final String? babyAvatarUrl;

  factory Family.fromMap(Map<String, dynamic> m) => Family(
        id: m['id'] as String,
        name: m['name'] as String,
        babyName: m['baby_name'] as String?,
        babyBirthday: m['baby_birthday'] == null
            ? null
            : DateTime.parse(m['baby_birthday'] as String),
        babyAvatarUrl: m['baby_avatar_url'] as String?,
      );
}

class Profile {
  Profile({required this.id, this.displayName, this.avatarUrl});

  final String id;
  final String? displayName;
  final String? avatarUrl;

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        displayName: m['display_name'] as String?,
        avatarUrl: m['avatar_url'] as String?,
      );
}

class FamilyMember {
  FamilyMember({
    required this.userId,
    required this.role,
    this.relation,
    this.profile,
  });

  final String userId;
  final String role;
  final String? relation;
  final Profile? profile;

  factory FamilyMember.fromMap(Map<String, dynamic> m) => FamilyMember(
        userId: m['user_id'] as String,
        role: m['role'] as String,
        relation: m['relation'] as String?,
        profile: m['profiles'] == null
            ? null
            : Profile.fromMap(m['profiles'] as Map<String, dynamic>),
      );
}

class MediaItem {
  MediaItem({
    required this.id,
    required this.storagePath,
    required this.type,
    this.position = 0,
  });

  final String id;
  final String storagePath;
  final String type; // 'image' | 'video'
  final int position;

  bool get isVideo => type == 'video';

  factory MediaItem.fromMap(Map<String, dynamic> m) => MediaItem(
        id: m['id'] as String,
        storagePath: m['storage_path'] as String,
        type: m['type'] as String,
        position: (m['position'] as int?) ?? 0,
      );
}

class Post {
  Post({
    required this.id,
    required this.familyId,
    required this.authorId,
    this.content,
    required this.recordedAt,
    this.author,
    this.media = const [],
    this.commentCount = 0,
    this.reactionCount = 0,
  });

  final String id;
  final String familyId;
  final String authorId;
  final String? content;
  final DateTime recordedAt;
  final Profile? author;
  final List<MediaItem> media;
  final int commentCount;
  final int reactionCount;

  factory Post.fromMap(Map<String, dynamic> m) {
    final mediaList = (m['media'] as List?)
            ?.map((e) => MediaItem.fromMap(e as Map<String, dynamic>))
            .toList() ??
        const [];
    mediaList.sort((a, b) => a.position.compareTo(b.position));
    return Post(
      id: m['id'] as String,
      familyId: m['family_id'] as String,
      authorId: m['author_id'] as String,
      content: m['content'] as String?,
      recordedAt: DateTime.parse(m['recorded_at'] as String),
      author: m['profiles'] == null
          ? null
          : Profile.fromMap(m['profiles'] as Map<String, dynamic>),
      media: mediaList,
    );
  }
}

class Comment {
  Comment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.createdAt,
    this.author,
  });

  final String id;
  final String content;
  final String authorId;
  final DateTime createdAt;
  final Profile? author;

  factory Comment.fromMap(Map<String, dynamic> m) => Comment(
        id: m['id'] as String,
        content: m['content'] as String,
        authorId: m['author_id'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        author: m['profiles'] == null
            ? null
            : Profile.fromMap(m['profiles'] as Map<String, dynamic>),
      );
}

class GrowthRecord {
  GrowthRecord({
    required this.id,
    required this.metric,
    this.value,
    this.unit,
    this.note,
    required this.recordedAt,
  });

  final String id;
  final String metric; // 'height' | 'weight' | 'head' | 'milestone'
  final double? value;
  final String? unit;
  final String? note;
  final DateTime recordedAt;

  factory GrowthRecord.fromMap(Map<String, dynamic> m) => GrowthRecord(
        id: m['id'] as String,
        metric: m['metric'] as String,
        value: (m['value'] as num?)?.toDouble(),
        unit: m['unit'] as String?,
        note: m['note'] as String?,
        recordedAt: DateTime.parse(m['recorded_at'] as String),
      );
}

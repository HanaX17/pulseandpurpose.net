import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/env.dart';
import '../../core/premium/subscription.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../premium/ad_banner.dart';
import 'network_media.dart';

/// The baby's timeline: posts newest-first, with ads interleaved for free users.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = ref.watch(currentFamilyProvider);
    if (family == null) {
      return const Scaffold(body: Center(child: Text('No family selected')));
    }

    final feed = ref.watch(feedProvider(family.id));
    final isPremium =
        ref.watch(entitlementProvider).valueOrNull?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(family.babyName ?? family.name)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(feedProvider(family.id)),
        child: feed.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorList(message: '$e'),
          data: (posts) {
            if (posts.isEmpty) return const _EmptyFeed();
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: _itemCount(posts.length, isPremium),
              itemBuilder: (context, index) {
                final adSlot = !isPremium && _isAdSlot(index);
                if (adSlot) return const AdBanner();
                final postIndex = _postIndex(index, isPremium);
                return _PostCard(post: posts[postIndex]);
              },
            );
          },
        ),
      ),
    );
  }

  // ---- ad interleaving helpers ----
  bool _isAdSlot(int index) => (index + 1) % (Env.adFrequency + 1) == 0;

  int _postIndex(int index, bool isPremium) {
    if (isPremium) return index;
    return index - ((index + 1) ~/ (Env.adFrequency + 1));
  }

  int _itemCount(int posts, bool isPremium) {
    if (isPremium) return posts;
    return posts + (posts ~/ Env.adFrequency);
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateFormat.yMMMd().add_jm().format(post.recordedAt.toLocal());
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/post/${post.id}', extra: post),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(post.author?.displayName ?? 'Family'),
              subtitle: Text(date),
            ),
            if (post.media.isNotEmpty)
              AspectRatio(
                aspectRatio: 1,
                child: NetworkMedia(item: post.media.first),
              ),
            if (post.content != null && post.content!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(post.content!),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () async {
                      await ref
                          .read(repositoryProvider)
                          .toggleReaction(post);
                      ref.invalidate(feedProvider(post.familyId));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.mode_comment_outlined),
                    onPressed: () =>
                        context.push('/post/${post.id}', extra: post),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Icon(Icons.photo_camera_back_outlined, size: 64),
        SizedBox(height: 12),
        Center(child: Text('No memories yet. Tap + to add the first one!')),
      ],
    );
  }
}

class _ErrorList extends StatelessWidget {
  const _ErrorList({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return ListView(children: [const SizedBox(height: 120), Center(child: Text(message))]);
  }
}

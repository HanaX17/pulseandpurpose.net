import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models.dart';
import '../../data/repository.dart';
import 'network_media.dart';

/// Full post view: media carousel, caption, like, and comments.
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.post});
  final Post post;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _comment = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(repositoryProvider).addComment(widget.post, text);
      _comment.clear();
      ref.invalidate(commentsProvider(widget.post.id));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final comments = ref.watch(commentsProvider(post.id));

    return Scaffold(
      appBar: AppBar(title: Text(post.author?.displayName ?? 'Memory')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                if (post.media.isNotEmpty)
                  SizedBox(
                    height: 320,
                    child: PageView(
                      children: [
                        for (final m in post.media) NetworkMedia(item: m),
                      ],
                    ),
                  ),
                if (post.content != null && post.content!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(post.content!),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    DateFormat.yMMMd()
                        .add_jm()
                        .format(post.recordedAt.toLocal()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Divider(height: 32),
                comments.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('$e'),
                  ),
                  data: (list) => list.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('No comments yet')),
                        )
                      : Column(
                          children: [
                            for (final c in list)
                              ListTile(
                                leading: const CircleAvatar(
                                    child: Icon(Icons.person, size: 18)),
                                title:
                                    Text(c.author?.displayName ?? 'Family'),
                                subtitle: Text(c.content),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _comment,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment…',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: _sending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

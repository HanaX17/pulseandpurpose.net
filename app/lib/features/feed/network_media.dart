import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/media_storage.dart';
import '../../data/models.dart';

/// Resolves a media item's signed URL and renders it. Videos show a thumbnail
/// placeholder with a play badge (full playback is a TODO — wire video_player).
class NetworkMedia extends ConsumerWidget {
  const NetworkMedia({super.key, required this.item, this.fit = BoxFit.cover});

  final MediaItem item;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(mediaUrlProvider(item.storagePath));
    return url.when(
      loading: () => const ColoredBox(
        color: Color(0x11000000),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => const ColoredBox(
        color: Color(0x11000000),
        child: Icon(Icons.broken_image_outlined),
      ),
      data: (signedUrl) {
        final image = CachedNetworkImage(
          imageUrl: signedUrl,
          fit: fit,
          placeholder: (_, __) => const ColoredBox(color: Color(0x11000000)),
        );
        if (!item.isVideo) return image;
        return Stack(
          fit: StackFit.expand,
          children: [
            image,
            const Center(
              child: Icon(Icons.play_circle_fill,
                  size: 48, color: Colors.white70),
            ),
          ],
        );
      },
    );
  }
}

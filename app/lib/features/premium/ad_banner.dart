import 'package:flutter/material.dart';

/// Placeholder ad slot shown to free users in the feed.
///
/// TODO: integrate Google AdMob via `google_mobile_ads`:
///   1. add the dependency + AdMob app id to AndroidManifest / Info.plist,
///   2. load a `BannerAd` (use test ad unit ids in debug),
///   3. swap this Container for the rendered `AdWidget`.
/// Kept as a non-network placeholder so the scaffold runs without store config.
class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      height: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.ads_click, size: 18),
          const SizedBox(width: 8),
          Text('Ad placeholder · upgrade to remove',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

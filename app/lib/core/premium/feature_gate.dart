import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'subscription.dart';

/// Wraps premium-only UI. Premium users see [child]; free users see a locked
/// prompt that routes to the paywall.
///
/// Example:
///   FeatureGate(
///     feature: PremiumFeature.originalQuality,
///     child: DownloadOriginalButton(),
///   )
class FeatureGate extends ConsumerWidget {
  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.lockedLabel = 'Premium feature',
  });

  final PremiumFeature feature;
  final Widget child;
  final String lockedLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium =
        ref.watch(entitlementProvider).valueOrNull?.isPremium ?? false;
    if (isPremium) return child;
    return ListTile(
      leading: const Icon(Icons.lock_outline),
      title: Text(lockedLabel),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/paywall'),
    );
  }
}

/// Imperative check for call sites that need a boolean (e.g. before kicking
/// off an original-quality download).
bool canUseFeature(WidgetRef ref, PremiumFeature feature) =>
    ref.read(entitlementProvider).valueOrNull?.isPremium ?? false;

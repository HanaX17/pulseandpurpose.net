import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase.dart';

/// Premium entitlement for the current user, read from `subscriptions`.
/// Writes happen server-side (the `verify-purchase` Edge Function), never here.
class Entitlement {
  const Entitlement({required this.isPremium});
  final bool isPremium;
  static const free = Entitlement(isPremium: false);
}

final entitlementProvider = FutureProvider<Entitlement>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Entitlement.free;

  final row = await ref
      .watch(supabaseProvider)
      .from('subscriptions')
      .select('tier, status, expires_at')
      .eq('user_id', user.id)
      .maybeSingle();

  if (row == null) return Entitlement.free;
  final active = row['status'] == 'active' &&
      (row['expires_at'] == null ||
          DateTime.parse(row['expires_at'] as String).isAfter(DateTime.now()));
  return Entitlement(isPremium: row['tier'] == 'premium' && active);
});

/// Premium-only capabilities. Free users hitting one of these are sent to the
/// paywall via `FeatureGate`.
enum PremiumFeature { removeAds, originalQuality, growthReport, unlimitedStorage }

/// Calls the stubbed `verify-purchase` function after a store purchase.
class SubscriptionService {
  SubscriptionService(this._ref);
  final Ref _ref;

  Future<void> verifyPurchase({
    required String store, // 'apple' | 'google'
    required String receipt,
    String? productId,
  }) async {
    await _ref.read(supabaseProvider).functions.invoke('verify-purchase', body: {
      'store': store,
      'receipt': receipt,
      'productId': productId,
    });
    _ref.invalidate(entitlementProvider);
  }
}

final subscriptionServiceProvider =
    Provider<SubscriptionService>((ref) => SubscriptionService(ref));

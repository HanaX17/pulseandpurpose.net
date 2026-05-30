import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/premium/subscription.dart';

/// Subscription paywall. The purchase flow is stubbed: real In-App Purchase
/// wiring (`in_app_purchase` or RevenueCat) calls the store, then hands the
/// receipt to `SubscriptionService.verifyPurchase`.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _busy = false;

  static const _benefits = [
    ('Ad-free experience', Icons.block),
    ('Original-quality photos & video', Icons.high_quality),
    ('Unlimited storage', Icons.cloud_done),
    ('Growth reports & charts', Icons.insights),
  ];

  Future<void> _subscribe() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // TODO: trigger the platform purchase and pass the real receipt.
      await ref.read(subscriptionServiceProvider).verifyPurchase(
            store: 'apple',
            receipt: 'DEV_FAKE_RECEIPT',
            productId: 'premium_monthly',
          );
      if (mounted) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Premium activated (dev stub)')));
        context.pop();
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.workspace_premium, size: 64),
            const SizedBox(height: 16),
            Text('Pulse Family Premium',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            for (final (label, icon) in _benefits)
              ListTile(leading: Icon(icon), title: Text(label)),
            const Spacer(),
            FilledButton(
              onPressed: _busy ? null : _subscribe,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Subscribe · \$4.99 / month'),
            ),
            const SizedBox(height: 8),
            Text('Cancel anytime. Restore purchases in Settings.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

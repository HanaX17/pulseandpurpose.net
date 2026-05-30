import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/premium/subscription.dart';
import '../../core/supabase.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final entitlement = ref.watch(entitlementProvider);
    final isPremium = entitlement.valueOrNull?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user?.userMetadata?['display_name']?.toString() ??
                user?.email ??
                'Me'),
            subtitle: Text(user?.email ?? ''),
          ),
          const Divider(),
          ListTile(
            leading: Icon(isPremium ? Icons.workspace_premium : Icons.star),
            title: Text(isPremium ? 'Premium active' : 'Upgrade to Premium'),
            subtitle: Text(isPremium
                ? 'Ad-free, original quality, growth reports'
                : 'Remove ads and unlock everything'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/paywall'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => ref.read(supabaseProvider).auth.signOut(),
          ),
        ],
      ),
    );
  }
}

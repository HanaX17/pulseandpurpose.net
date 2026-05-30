import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository.dart';

/// Family roster + invite-code generation.
class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = ref.watch(currentFamilyProvider);
    if (family == null) {
      return const Scaffold(body: Center(child: Text('No family selected')));
    }
    final members = ref.watch(membersProvider(family.id));

    return Scaffold(
      appBar: AppBar(title: Text(family.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _invite(context, ref, family.id),
        icon: const Icon(Icons.person_add),
        label: const Text('Invite'),
      ),
      body: members.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => ListView(
          children: [
            for (final m in list)
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(m.profile?.displayName ?? 'Member'),
                subtitle: Text(m.relation ?? m.role),
                trailing: m.role == 'owner'
                    ? const Chip(label: Text('Owner'))
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _invite(
      BuildContext context, WidgetRef ref, String familyId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final code = await ref.read(repositoryProvider).createInvite(familyId);
      ref.invalidate(membersProvider(familyId));
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Invite a family member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share this code. They enter it when they sign up.'),
              const SizedBox(height: 16),
              SelectableText(
                code,
                style: Theme.of(ctx)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(letterSpacing: 4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                Navigator.pop(ctx);
              },
              child: const Text('Copy'),
            ),
          ],
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

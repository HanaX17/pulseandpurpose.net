import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository.dart';
import '../onboarding/onboarding_screen.dart';
import 'main_shell.dart';

/// Decides where a signed-in user lands: onboarding (no family yet) or the
/// main tabbed shell.
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final families = ref.watch(myFamiliesProvider);
    return families.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Failed to load: $e')),
      ),
      data: (list) =>
          list.isEmpty ? const OnboardingScreen() : const MainShell(),
    );
  }
}

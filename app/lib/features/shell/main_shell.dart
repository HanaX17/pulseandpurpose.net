import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../family/family_screen.dart';
import '../feed/feed_screen.dart';
import '../growth/growth_screen.dart';
import '../settings/settings_screen.dart';

/// Bottom-tab container for the four primary sections.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  static const _tabs = [
    FeedScreen(),
    GrowthScreen(),
    FamilyScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              onPressed: () => context.push('/create'),
              child: const Icon(Icons.add_a_photo),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.photo_library), label: 'Feed'),
          NavigationDestination(
              icon: Icon(Icons.show_chart), label: 'Growth'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Family'),
          NavigationDestination(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../features/auth/login_screen.dart';
import '../features/feed/create_post_screen.dart';
import '../features/feed/post_detail_screen.dart';
import '../features/premium/paywall_screen.dart';
import '../features/shell/root_gate.dart';
import 'supabase.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(supabaseProvider).auth;

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _GoRouterRefresh(auth.onAuthStateChange),
    redirect: (context, state) {
      final loggedIn = auth.currentUser != null;
      final onLogin = state.matchedLocation == '/login';
      if (!loggedIn) return onLogin ? null : '/login';
      if (onLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, __) => const RootGate()),
      GoRoute(path: '/create', builder: (_, __) => const CreatePostScreen()),
      GoRoute(
        path: '/post/:id',
        builder: (_, state) =>
            PostDetailScreen(post: state.extra as Post),
      ),
      GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
    ],
  );
});

/// Bridges a Stream into a Listenable so GoRouter re-evaluates `redirect`
/// whenever auth state changes.
class _GoRouterRefresh extends ChangeNotifier {
  _GoRouterRefresh(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

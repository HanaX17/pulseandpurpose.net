import 'package:flutter_test/flutter_test.dart';
import 'package:baby_moments/core/env.dart';

// Mirrors the ad-interleaving math in FeedScreen so the indexing logic is
// regression-tested without needing a Supabase backend.
int itemCount(int posts, bool isPremium) =>
    isPremium ? posts : posts + (posts ~/ Env.adFrequency);

bool isAdSlot(int index) => (index + 1) % (Env.adFrequency + 1) == 0;

void main() {
  test('premium users see no ad slots', () {
    expect(itemCount(20, true), 20);
  });

  test('free users get one ad per adFrequency posts', () {
    // 12 posts at frequency 6 => 2 ad slots interleaved.
    expect(itemCount(12, false), 14);
  });

  test('ad slots land at the expected positions', () {
    final slots = [for (var i = 0; i < 14; i++) i].where(isAdSlot).toList();
    expect(slots, [Env.adFrequency, (Env.adFrequency + 1) * 2 - 1]);
  });
}

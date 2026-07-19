import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina/features/profile/providers/profile_providers.dart';

/// Which experience is currently active for this account - Customer
/// (browse/book) or Business (manage a claimed/registered salon).
///
/// This is deliberately NOT the same thing as `profiles.role` (what
/// someone chose at signup). Role no longer gates anything - any
/// account can browse/book as a customer AND claim or register a
/// salon, per Aina's "one account, two hats" model. This just tracks
/// which of the two UIs to show, stored server-side on `profiles` so
/// it's consistent across devices - not a local-only preference.
enum ActiveView { customer, business }

ActiveView _fromString(String value) => value == 'business' ? ActiveView.business : ActiveView.customer;

/// Backed by `myProfileProvider` (source of truth: `profiles.active_view`).
/// Updates optimistically so the switch feels instant, then persists to
/// the server and refreshes the underlying profile cache; rolls back on
/// failure.
class ActiveViewNotifier extends AsyncNotifier<ActiveView> {
  @override
  Future<ActiveView> build() async {
    final profile = await ref.watch(myProfileProvider.future);
    return _fromString(profile.activeView);
  }

  Future<void> setView(ActiveView view) async {
    final previous = state;
    state = AsyncData(view);

    try {
      await ref.read(profileRepositoryProvider).updateActiveView(view.name);
      // Keeps the rest of the app (e.g. Profile screen showing
      // "Business"/"Customer") in sync with the same underlying value.
      ref.invalidate(myProfileProvider);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }
}

final activeViewProvider = AsyncNotifierProvider<ActiveViewNotifier, ActiveView>(
  ActiveViewNotifier.new,
);

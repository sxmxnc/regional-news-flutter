import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import 'account_queries.dart';
import 'user_profile.dart';

mixin AccountProfilePrefillState<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  bool _profilePrefillApplied = false;

  void watchAccountProfilePrefill(
    AppLanguage language,
    void Function(UserProfile profile) apply,
  ) {
    final AsyncValue<UserProfile?> state = ref.watch(
      currentUserProvider(CurrentUserKey(language)),
    );
    if (_profilePrefillApplied) return;
    if (!state.hasValue) return;
    final UserProfile? profile = state.requireValue;
    if (profile == null) return;
    _profilePrefillApplied = true;
    apply(profile);
  }
}

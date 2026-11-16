import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/constants.dart';
import '../../core/query.dart';
import '../../state/session.dart';
import 'account_repository.dart';
import 'user_profile.dart';

/// Abfrageschlüssel für das eigene Profil. Keine weitere Dimension als die
/// Sprache — welcher Nutzer gemeint ist, entscheidet allein das Token im
/// zugrundeliegenden [WbClient] (`account_repository.dart`); ändert es sich
/// (Anmeldung, Abmeldung), entwertet das die abhängigen Anbieter von selbst.
final class CurrentUserKey extends QueryKey {
  const CurrentUserKey(super.language);

  @override
  List<Object?> get parts => const <Object?>[];

  @override
  Duration get freshFor => CachePolicy.list;
}

final FutureProviderFamily<UserProfile?, CurrentUserKey> currentUserProvider =
    FutureProvider.family<UserProfile?, CurrentUserKey>((
      Ref ref,
      CurrentUserKey key,
    ) async {
      // Ohne Sitzung keine Anfrage: Endet die Sitzung während dieser Anbieter
      // beobachtet wird (401/403, `lib/api/wb_client.dart`), entwertet das
      // den zugrundeliegenden Client — ohne diese Schranke würde der zweite
      // Aufruf hier ein zweites, tokenloses `GET /user` auslösen, bevor die
      // Kontofläche auf die Anmeldefläche wechselt.
      final bool isAuthenticated = ref.watch(
        sessionProvider.select((SessionState s) => s.isAuthenticated),
      );
      if (!isAuthenticated) return null;

      ref.cacheFor(key.freshFor);
      final UserProfile? profile = await ref
          .watch(accountRepositoryProvider(key.language))
          .getUser();
      ref.markSynced();
      return profile;
    }, isAutoDispose: true);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/query.dart';
import '../../state/session.dart';
import 'subscription_plan.dart';
import 'subscription_repository.dart';

final class SubscriptionPlansKey extends QueryKey {
  const SubscriptionPlansKey(super.language);

  @override
  List<Object?> get parts => const <Object?>[];
}

final FutureProviderFamily<List<SubscriptionPlan>, SubscriptionPlansKey>
subscriptionPlansProvider =
    FutureProvider.family<List<SubscriptionPlan>, SubscriptionPlansKey>((
      Ref ref,
      SubscriptionPlansKey key,
    ) async {
      final bool isAuthenticated = ref.watch(
        sessionProvider.select((SessionState s) => s.isAuthenticated),
      );
      if (!isAuthenticated) return const <SubscriptionPlan>[];

      ref.cacheFor(key.freshFor);
      final List<SubscriptionPlan> plans = await ref
          .watch(subscriptionRepositoryProvider(key.language))
          .getPlans();
      ref.markSynced();
      return plans;
    }, isAutoDispose: true);

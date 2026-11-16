import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;

import '../../api/mapper/subscription_mapper.dart';
import '../../api/wb_client.dart';
import '../../config/app_config.dart';
import '../../core/app_language.dart';
import '../../core/failure.dart';
import 'payment.dart';
import 'subscription_plan.dart';

final class SubscriptionRepository {
  const SubscriptionRepository(this._client);

  final WbClient _client;

  Future<List<SubscriptionPlan>> getPlans() async {
    final WbResponse response = await _client.get('subscription/plans');
    return SubscriptionMapper.plansFromJson(response.asMap)
        .where((SubscriptionPlan plan) => plan.isPurchasableInApp)
        .toList();
  }

  Future<PaymentRegistration> registerPayment({required int planId}) async {
    final WbResponse response = await _client.post(
      'subscription/register-payment',
      body: <String, Object?>{
        'plan_id': planId,
        'provider': 'p24',
        'sdk_version': AppConfig.p24SdkVersion,
      },
    );
    final PaymentRegistration? registration =
        SubscriptionMapper.registrationFromJson(response.asMap);
    if (registration == null) {
      throw const ServerFailure(
        cause: 'register-payment: token oder payment_id fehlt',
      );
    }
    return registration;
  }

  Future<PaymentConfirmation> confirm({required Object paymentId}) async {
    final WbResponse response = await _client.post(
      'subscription/confirm',
      body: <String, Object?>{'payment_id': paymentId},
    );
    return SubscriptionMapper.confirmationFromJson(response.asMap);
  }
}

final ProviderFamily<SubscriptionRepository, AppLanguage>
subscriptionRepositoryProvider =
    Provider.family<SubscriptionRepository, AppLanguage>((
      Ref ref,
      AppLanguage language,
    ) {
      return SubscriptionRepository(ref.watch(wbClientProvider(language)));
    });

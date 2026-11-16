import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../core/app_language.dart';
import '../account/account_queries.dart';
import '../epaper/epaper_queries.dart';
import 'payment.dart';
import 'subscription_plan.dart';
import 'subscription_repository.dart';
import 'subscription_status.dart';

enum PaymentPhase {
  idle,

  /// `register-payment` läuft.
  registering,

  awaitingReturn,

  openFailed,

  /// `confirm` wird mit wachsendem Abstand abgefragt.
  checking,

  pending,

  /// `confirm` meldete `accepted`; das Abo im zweiten Format liegt vor.
  accepted,

  /// `register-payment` oder `confirm` scheiterten mit einem Fehler.
  failed,
}

final class PaymentState {
  const PaymentState({
    required this.phase,
    this.language,
    this.registration,
    this.subscription,
    this.error,
    this.attempt = 0,
  });

  const PaymentState.idle() : this(phase: PaymentPhase.idle);

  final PaymentPhase phase;

  /// Sprache, in der der Plan gewählt wurde — `currentUserProvider` dieser
  /// Sprache wird nach der Bestätigung entwertet.
  final AppLanguage? language;

  final PaymentRegistration? registration;

  final SubscriptionStatus? subscription;

  /// Nur zum Übersetzen in einen Text (`failureMessageKey`), nie zur Anzeige
  /// als solcher.
  final Object? error;

  /// Laufende Nummer des `confirm`-Versuchs (nur Anzeige).
  final int attempt;

  bool get canCheck =>
      registration != null &&
      phase != PaymentPhase.accepted &&
      phase != PaymentPhase.checking &&
      phase != PaymentPhase.registering;

  PaymentState _with({
    required PaymentPhase phase,
    SubscriptionStatus? subscription,
    Object? error,
    int attempt = 0,
  }) => PaymentState(
    phase: phase,
    language: language,
    registration: registration,
    subscription: subscription,
    error: error,
    attempt: attempt,
  );
}

typedef PaymentLauncher = Future<bool> Function(Uri url);

final Provider<PaymentLauncher> paymentLauncherProvider =
    Provider<PaymentLauncher>(
      (Ref ref) =>
          (Uri url) => launchUrl(url, mode: LaunchMode.inAppBrowserView),
    );

final Provider<List<Duration>> paymentConfirmDelaysProvider =
    Provider<List<Duration>>(
      (Ref ref) => const <Duration>[
        Duration(seconds: 2),
        Duration(seconds: 4),
        Duration(seconds: 8),
        Duration(seconds: 16),
        Duration(seconds: 30),
      ],
    );

final NotifierProvider<PaymentController, PaymentState>
paymentControllerProvider = NotifierProvider<PaymentController, PaymentState>(
  PaymentController.new,
);

final class PaymentController extends Notifier<PaymentState> {
  /// Zählt jede neue Abfragerunde — eine ältere Runde, die noch wartet,
  /// erkennt daran, dass sie nichts mehr schreiben darf.
  int _round = 0;

  @override
  PaymentState build() => const PaymentState.idle();

  Future<void> start({
    required AppLanguage language,
    required SubscriptionPlan plan,
  }) async {
    _round++;
    state = PaymentState(phase: PaymentPhase.registering, language: language);
    final PaymentRegistration registration;
    try {
      registration = await ref
          .read(subscriptionRepositoryProvider(language))
          .registerPayment(planId: plan.id);
    } catch (error) {
      state = PaymentState(
        phase: PaymentPhase.failed,
        language: language,
        error: error,
      );
      return;
    }
    state = PaymentState(
      phase: PaymentPhase.awaitingReturn,
      language: language,
      registration: registration,
    );
    await _open();
  }

  /// Öffnet die Zahlungsseite erneut, etwa nach [PaymentPhase.openFailed].
  Future<void> reopen() => _open();

  Future<void> _open() async {
    final PaymentRegistration? registration = state.registration;
    if (registration == null) return;
    final Uri url = AppConfig.paymentUrl(
      token: registration.token,
      isSandbox: registration.isSandbox,
    );
    bool opened;
    try {
      opened = await ref.read(paymentLauncherProvider)(url);
    } on Object catch (error) {
      developer.log(
        'Zahlungsseite nicht geöffnet: $error',
        name: 'PaymentController',
      );
      opened = false;
    }
    state = state._with(
      phase: opened ? PaymentPhase.awaitingReturn : PaymentPhase.openFailed,
    );
  }

  Future<void> checkStatus() async {
    final PaymentRegistration? registration = state.registration;
    final AppLanguage? language = state.language;
    if (registration == null || language == null) return;
    final int round = ++_round;
    final List<Duration> delays = ref.read(paymentConfirmDelaysProvider);
    final SubscriptionRepository repository = ref.read(
      subscriptionRepositoryProvider(language),
    );

    for (int attempt = 0; attempt <= delays.length; attempt++) {
      state = state._with(phase: PaymentPhase.checking, attempt: attempt + 1);
      final PaymentConfirmation confirmation;
      try {
        confirmation = await repository.confirm(
          paymentId: registration.paymentId,
        );
      } catch (error) {
        if (round != _round) return;
        _invalidateAccountData(language);
        state = state._with(phase: PaymentPhase.failed, error: error);
        return;
      }
      if (round != _round) return;
      if (confirmation.accepted) {
        _invalidateAccountData(language);
        state = state._with(
          phase: PaymentPhase.accepted,
          subscription: confirmation.subscription,
        );
        return;
      }
      if (attempt < delays.length) {
        await Future<void>.delayed(delays[attempt]);
        if (round != _round) return;
      }
    }
    _invalidateAccountData(language);
    state = state._with(phase: PaymentPhase.pending);
  }

  /// Zurück in den Ausgangszustand — nach „Zum Konto" oder wenn die Fläche
  /// verlassen wird, ohne dass eine Zahlung angemeldet wurde.
  void reset() {
    _round++;
    state = const PaymentState.idle();
  }

  void _invalidateAccountData(AppLanguage language) {
    ref.invalidate(currentUserProvider(CurrentUserKey(language)));
    ref.invalidate(epaperYearsProvider);
    ref.invalidate(epaperIssuesProvider);
  }
}

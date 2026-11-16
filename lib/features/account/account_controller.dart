import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;

import '../../core/app_language.dart';
import '../../core/local_user_data.dart';
import '../../core/secure_key_value_store.dart';
import '../../state/session.dart';
import 'account_queries.dart';
import 'account_repository.dart';

final class AccountController {
  const AccountController(this._ref, this._language);

  final Ref _ref;
  final AppLanguage _language;

  AccountRepository get _repository =>
      _ref.read(accountRepositoryProvider(_language));

  Future<void> login({required String email, required String password}) async {
    final String deviceToken = await _ref.currentDeviceToken();
    final String token = await _repository.login(
      email: email,
      password: password,
      deviceToken: deviceToken,
    );
    await _ref
        .read(sessionProvider.notifier)
        .begin(token: token, isGuest: false);
  }

  Future<void> ensureGuestSession({required String deviceToken}) async {
    if (_ref.read(sessionProvider).token != null) return;
    final String token = await _repository.guest(deviceToken: deviceToken);
    await _ref
        .read(sessionProvider.notifier)
        .begin(token: token, isGuest: true);
  }

  Future<void> renewGuestSession({required String deviceToken}) async {
    if (_ref.read(sessionProvider).isAuthenticated) return;
    final String token = await _repository.guest(deviceToken: deviceToken);
    await _ref
        .read(sessionProvider.notifier)
        .begin(token: token, isGuest: true);
  }

  Future<void> registerRequest({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) => _repository.registerRequest(
    username: username,
    firstName: firstName,
    lastName: lastName,
    email: email,
    password: password,
  );

  Future<void> registerConfirm({
    required String email,
    required String confirmationCode,
  }) async {
    final String deviceToken = await _ref.currentDeviceToken();
    await _repository.registerConfirm(
      email: email,
      confirmationCode: confirmationCode,
      deviceToken: deviceToken,
    );
  }

  Future<void> resetPasswordRequest({required String email}) =>
      _repository.resetPasswordRequest(email: email);

  Future<void> resetPasswordConfirm({
    required String email,
    required String confirmationCode,
    required String password,
  }) => _repository.resetPasswordConfirm(
    email: email,
    confirmationCode: confirmationCode,
    password: password,
  );

  Future<void> editProfile({
    required String firstName,
    required String lastName,
  }) async {
    await _repository.editProfile(firstName: firstName, lastName: lastName);
    _ref.invalidate(currentUserProvider(CurrentUserKey(_language)));
  }

  Future<void> changeEmailRequest({required String email}) =>
      _repository.changeEmailRequest(email: email);

  Future<void> changeEmailConfirm({
    required String email,
    required String confirmationCode,
  }) async {
    await _repository.changeEmailConfirm(
      email: email,
      confirmationCode: confirmationCode,
    );
    _ref.invalidate(currentUserProvider(CurrentUserKey(_language)));
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      await _ref.read(sessionProvider.notifier).end();
      await _ref
          .read(secureKeyValueStoreProvider)
          .remove(SecureStoreKeys.installationId);
    }
  }

  Future<void> deleteRequest() => _repository.deleteRequest();

  Future<void> deleteConfirm({required String confirmationCode}) async {
    await _repository.deleteConfirm(confirmationCode: confirmationCode);
    await _ref.read(sessionProvider.notifier).end();
    await _ref
        .read(secureKeyValueStoreProvider)
        .remove(SecureStoreKeys.installationId);
    await clearLocalUserData(_ref);
  }
}

final ProviderFamily<AccountController, AppLanguage> accountControllerProvider =
    Provider.family<AccountController, AppLanguage>((
      Ref ref,
      AppLanguage language,
    ) {
      return AccountController(ref, language);
    });

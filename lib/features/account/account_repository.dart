import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;

import '../../api/mapper/user_mapper.dart';
import '../../api/wb_client.dart';
import '../../core/app_language.dart';
import '../../core/failure.dart';
import 'user_profile.dart';

final class AccountRepository {
  const AccountRepository(this._client);

  final WbClient _client;

  Future<String> guest({required String deviceToken}) async {
    final WbResponse response = await _client.post(
      'auth/guest',
      body: <String, Object?>{'device_token': deviceToken},
    );
    final Object? token = response.asMap['token'];
    if (token is! String || token.isEmpty) {
      throw ServerFailure(cause: 'auth/guest: token fehlt in der Antwort');
    }
    return token;
  }

  Future<String> login({
    required String email,
    required String password,
    required String deviceToken,
  }) async {
    final WbResponse response = await _client.post(
      'auth/login',
      body: <String, Object?>{
        'email': email,
        'password': password,
        'device_token': deviceToken,
      },
    );
    final Object? token = response.asMap['token'];
    if (token is! String || token.isEmpty) {
      throw ServerFailure(cause: 'auth/login: token fehlt in der Antwort');
    }
    return token;
  }

  Future<void> logout() => _client.post('auth/logout');

  Future<void> registerRequest({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) => _client.post(
    'auth/register/request',
    body: <String, Object?>{
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
    },
  );

  Future<void> registerConfirm({
    required String email,
    required String confirmationCode,
    required String deviceToken,
  }) => _client.post(
    'auth/register/confirm',
    body: <String, Object?>{
      'email': email,
      'confirmation_code': confirmationCode,
      'device_token': deviceToken,
    },
  );

  Future<void> resetPasswordRequest({required String email}) => _client.post(
    'auth/reset-password/request',
    body: <String, Object?>{'email': email},
  );

  Future<void> resetPasswordConfirm({
    required String email,
    required String confirmationCode,
    required String password,
  }) => _client.post(
    'auth/reset-password/confirm',
    body: <String, Object?>{
      'email': email,
      'confirmation_code': confirmationCode,
      'password': password,
    },
  );

  Future<UserProfile?> getUser() async {
    final WbResponse response = await _client.get('user');
    return UserMapper.fromJson(response.asMap);
  }

  Future<void> editProfile({
    required String firstName,
    required String lastName,
  }) => _client.post(
    'user/edit',
    body: <String, Object?>{'first_name': firstName, 'last_name': lastName},
  );

  Future<void> changeEmailRequest({required String email}) => _client.post(
    'user/change-email/request',
    body: <String, Object?>{'email': email},
  );

  Future<void> changeEmailConfirm({
    required String email,
    required String confirmationCode,
  }) => _client.post(
    'user/change-email/confirm',
    body: <String, Object?>{
      'email': email,
      'confirmation_code': confirmationCode,
    },
  );

  Future<void> deleteRequest() => _client.post('user/delete/request');

  Future<void> deleteConfirm({required String confirmationCode}) =>
      _client.post(
        'user/delete/confirm',
        body: <String, Object?>{'confirmation_code': confirmationCode},
      );
}

final ProviderFamily<AccountRepository, AppLanguage> accountRepositoryProvider =
    Provider.family<AccountRepository, AppLanguage>((
      Ref ref,
      AppLanguage language,
    ) {
      return AccountRepository(ref.watch(wbClientProvider(language)));
    });

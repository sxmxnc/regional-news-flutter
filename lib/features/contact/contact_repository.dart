import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;

import '../../api/wb_client.dart';
import '../../core/app_language.dart';

final class ContactRepository {
  const ContactRepository(this._client);

  final WbClient _client;

  Future<void> send({required String message, String? email}) => _client.post(
    'contact',
    body: <String, Object?>{
      'message': message,
      if (email != null && email.isNotEmpty) 'email': email,
    },
  );
}

final ProviderFamily<ContactRepository, AppLanguage> contactRepositoryProvider =
    Provider.family<ContactRepository, AppLanguage>((
      Ref ref,
      AppLanguage language,
    ) {
      return ContactRepository(ref.watch(wbClientProvider(language)));
    });

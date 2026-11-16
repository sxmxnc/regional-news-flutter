import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../i18n/translations.dart';
import '../../state/language.dart';
import '../../state/notifications.dart';
import '../../state/session.dart';
import '../../state/settings.dart';
import '../../ui/nav/area_navigation_bar.dart';
import '../../ui/theme/app_theme.dart';
import '../account/account_controller.dart';
import '../account/account_queries.dart';
import '../account/change_email_screen.dart';
import '../account/delete_account_screen.dart';
import '../account/edit_profile_screen.dart';
import '../account/reset_password_screen.dart';
import '../account/user_profile.dart';
import 'legal_page_screen.dart';
import 'legal_pages_config.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref,
    Translations texts,
    AppLanguage language,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(texts['account_overview_logout_confirm_title']),
        content: Text(texts['account_overview_logout_confirm_message']),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(texts['account_cancel_action']),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(texts['account_overview_logout_action']),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(accountControllerProvider(language)).logout();
    } on Object catch (error) {
      // Absichtlich kein Fehlerhinweis: Token und Installationskennung sind
      // auch bei einem Fehler lokal verworfen (`AccountController.logout`
      // räumt in `finally`) — die Nutzerin hat sich entschieden, ein
      // Übertragungsfehler beim Server-Logout darf die Sitzung nicht
      // offenhalten. Protokolliert wird er trotzdem.
      developer.log(
        'Abmeldung am Server gescheitert: $error',
        name: 'SettingsScreen',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    final AppLanguage language = ref.watch(languageProvider);
    final NwbTextScale textScale = ref.watch(
      settingsProvider.select((SettingsState s) => s.textScale),
    );
    final bool notificationsEnabled = ref.watch(notificationsProvider);
    final bool isAuthenticated = ref.watch(
      sessionProvider.select((SessionState s) => s.isAuthenticated),
    );
    // Nur für die Vorbelegung von „Profil bearbeiten" und „Passwort ändern"
    // nötig — ohne Sitzung wird gar nicht erst abgefragt (Regel 2).
    final UserProfile? user = isAuthenticated
        ? ref.watch(currentUserProvider(CurrentUserKey(language))).value
        : null;

    return Scaffold(
      bottomNavigationBar: const AreaNavigationBar(),
      appBar: AppBar(title: Text(texts['settings_action'])),
      body: ListView(
        children: <Widget>[
          _SectionHeading(texts['settings_section_language']),
          for (final AppLanguage value in AppLanguage.values)
            ListTile(
              title: Text(
                texts[value == AppLanguage.de ? 'language_de' : 'language_pl'],
              ),
              trailing: value == language ? const Icon(Icons.check) : null,
              onTap: () => ref.read(languageProvider.notifier).select(value),
            ),
          const Divider(height: 1),
          _SectionHeading(texts['text_size_action']),
          for (final NwbTextScale scale in NwbTextScale.values)
            ListTile(
              title: Text(texts['text_size_${scale.code}']),
              trailing: scale == textScale ? const Icon(Icons.check) : null,
              onTap: () =>
                  ref.read(settingsProvider.notifier).selectTextScale(scale),
            ),
          const Divider(height: 1),
          _SectionHeading(texts['settings_section_notifications']),
          ListTile(
            title: Text(texts['settings_notifications_label']),
            subtitle: Text(texts['settings_notifications_hint']),
            trailing: Icon(
              notificationsEnabled
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationSettingsScreen(),
              ),
            ),
          ),
          if (isAuthenticated) ...<Widget>[
            const Divider(height: 1),
            _SectionHeading(texts['settings_section_account']),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(texts['account_overview_edit_action']),
              onTap: user == null
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EditProfileScreen(
                          firstName: user.firstName,
                          lastName: user.lastName,
                        ),
                      ),
                    ),
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: Text(texts['account_overview_change_email_action']),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ChangeEmailScreen(),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(texts['account_overview_change_password_action']),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ResetPasswordScreen(knownEmail: user?.email),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(texts['account_overview_logout_action']),
              onTap: () => _confirmLogout(context, ref, texts, language),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                texts['account_overview_delete_action'],
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DeleteAccountScreen(),
                ),
              ),
            ),
          ],
          const Divider(height: 1),
          _SectionHeading(texts['settings_section_about']),
          ListTile(
            title: Text(texts['legal_imprint_title']),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LegalPageScreen(
                  language: language,
                  slug: LegalPageSlugs.imprint(language),
                  titleKey: 'legal_imprint_title',
                ),
              ),
            ),
          ),
          ListTile(
            title: Text(texts['legal_privacy_title']),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LegalPageScreen(
                  language: language,
                  slug: LegalPageSlugs.privacy(language),
                  titleKey: 'legal_privacy_title',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: NwbColors.brand),
      ),
    );
  }
}

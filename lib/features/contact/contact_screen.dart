import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/translations.dart';
import 'contact_form_screen.dart';

class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          texts['nav_contact'],
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(texts['contact_overview_intro']),
        const SizedBox(height: 16),
        const Divider(height: 1),
        _ContactWayTile(
          icon: Icons.mail_outline,
          title: texts['contact_overview_message_title'],
          subtitle: texts['contact_overview_message_subtitle'],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ContactFormScreen(
                titleKey: 'contact_form_message_title',
                kindKey: 'contact_kind_message',
              ),
            ),
          ),
        ),
        _ContactWayTile(
          icon: Icons.report_gmailerrorred_outlined,
          title: texts['contact_overview_error_title'],
          subtitle: texts['contact_overview_error_subtitle'],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ContactFormScreen(
                titleKey: 'contact_form_error_title',
                kindKey: 'contact_kind_error',
                introKey: 'contact_form_error_intro',
                includeDeviceContext: true,
              ),
            ),
          ),
        ),
        _ContactWayTile(
          icon: Icons.lightbulb_outline,
          title: texts['contact_overview_topic_title'],
          subtitle: texts['contact_overview_topic_subtitle'],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ContactFormScreen(
                titleKey: 'contact_form_topic_title',
                kindKey: 'contact_kind_topic',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactWayTile extends StatelessWidget {
  const _ContactWayTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }
}

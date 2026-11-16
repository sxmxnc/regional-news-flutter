import 'dart:async' show unawaited;
import 'dart:developer' as developer;

import 'package:url_launcher/url_launcher.dart';

void openExternalHtmlLink(String? url, {required String source}) {
  final Uri? target = url == null ? null : Uri.tryParse(url);
  if (target == null) {
    developer.log('Verweis nicht lesbar: $url', name: source);
    return;
  }
  unawaited(
    launchUrl(target, mode: LaunchMode.externalApplication).catchError((
      Object error,
    ) {
      developer.log(
        'Verweis konnte nicht geöffnet werden: $error',
        name: source,
      );
      return false;
    }),
  );
}

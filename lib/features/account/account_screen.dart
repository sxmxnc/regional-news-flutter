import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/session.dart';
import 'account_overview_screen.dart';
import 'login_screen.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isAuthenticated = ref.watch(
      sessionProvider.select((SessionState s) => s.isAuthenticated),
    );
    return isAuthenticated
        ? const AccountOverviewScreen()
        : const LoginScreen();
  }
}

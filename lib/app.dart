import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/phone_frame.dart';
import 'features/admin/admin_home_screen.dart';
import 'features/shell/customer_shell.dart';

class GncApp extends ConsumerWidget {
  const GncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(appRoleProvider);
    return MaterialApp(
      title: 'G&C',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) =>
          PhoneFrame(child: child ?? const SizedBox.shrink()),
      // Switching role swaps the whole navigation stack.
      home: switch (role) {
        AppRole.customer => const CustomerShell(key: ValueKey('customer')),
        AppRole.admin => const AdminHomeScreen(key: ValueKey('admin')),
      },
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class AppConfig {
  /// Shows the developer panel (customer/admin switch, offline simulation).
  /// On by default until Firebase roles arrive in Phase 4. Turn off with
  /// `--dart-define=GNC_DEV_TOOLS=false`.
  static const devToolsEnabled = bool.fromEnvironment(
    'GNC_DEV_TOOLS',
    defaultValue: true,
  );
}

enum AppRole { customer, admin }

/// Which side of the app is shown. Before Phase 4 this is switched by hand in
/// the developer panel; from Phase 4 it comes from the signed-in account.
class AppRoleNotifier extends Notifier<AppRole> {
  @override
  AppRole build() => AppRole.customer;

  void set(AppRole role) => state = role;
}

final appRoleProvider = NotifierProvider<AppRoleNotifier, AppRole>(
  AppRoleNotifier.new,
);

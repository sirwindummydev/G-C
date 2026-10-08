import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_config.dart';
import '../../data/repositories/local/local_menu_repository.dart';
import '../../data/repositories/providers.dart';
import '../menu/menu_providers.dart';

/// Opens the developer panel (long-press the logo in the app bar). Does nothing when
/// dev tools are switched off.
void showDevPanel(BuildContext context) {
  if (!AppConfig.devToolsEnabled) return;
  showModalBottomSheet<void>(
    context: context,
    builder: (_) => const DevPanel(),
  );
}

class DevPanel extends ConsumerStatefulWidget {
  const DevPanel({super.key});

  @override
  ConsumerState<DevPanel> createState() => _DevPanelState();
}

class _DevPanelState extends ConsumerState<DevPanel> {
  @override
  Widget build(BuildContext context) {
    final role = ref.watch(appRoleProvider);
    final repository = ref.watch(menuRepositoryProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Developer options', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'For testing only. Real roles arrive with sign-in in Phase 4.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('View as', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<AppRole>(
              segments: const [
                ButtonSegment(
                  value: AppRole.customer,
                  label: Text('Customer'),
                  icon: Icon(Icons.person_rounded),
                ),
                ButtonSegment(
                  value: AppRole.admin,
                  label: Text('Admin'),
                  icon: Icon(Icons.storefront_rounded),
                ),
              ],
              selected: {role},
              onSelectionChanged: (selection) {
                ref.read(appRoleProvider.notifier).set(selection.first);
                Navigator.of(context).pop();
              },
            ),
            if (repository is LocalMenuRepository) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Simulate no connection'),
                subtitle: const Text(
                  'Data calls fail so you can check error and retry screens.',
                ),
                value: repository.simulateOffline,
                onChanged: (value) {
                  setState(() => repository.simulateOffline = value);
                  retryMenu(ref);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

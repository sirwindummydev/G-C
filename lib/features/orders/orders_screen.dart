import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/empty_state.dart';
import '../shell/customer_shell.dart';

/// Order history and live tracking arrive in Phase 3. Until then the tab
/// shows the empty state customers see before their first order.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.peachTop,
      body: PeachSheetLayout(
        topBar: const AppTopBar(title: 'My Orders'),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom,
          ),
          child: EmptyState(
            title: 'No orders yet',
            message:
                'When you order, you can follow it here, from Placed to '
                'Ready for pickup, and reorder your favourites.',
            actionLabel: 'Browse menu',
            onAction: () => goToTab(context, ShellTab.home),
          ),
        ),
      ),
    );
  }
}

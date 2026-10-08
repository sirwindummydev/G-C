import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_logo.dart';
import '../cart/cart_providers.dart';
import '../cart/cart_screen.dart';
import '../dev/dev_panel.dart';
import '../menu/menu_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';

enum ShellTab { home, cart, orders, profile }

class ShellTabNotifier extends Notifier<ShellTab> {
  @override
  ShellTab build() => ShellTab.home;

  void select(ShellTab tab) => state = tab;
}

final shellTabProvider = NotifierProvider<ShellTabNotifier, ShellTab>(
  ShellTabNotifier.new,
);

/// Shows a tab, closing any screens pushed on top of the shell (e.g. an
/// item detail screen's cart icon goes back to the Cart tab).
void goToTab(BuildContext context, ShellTab tab) {
  ProviderScope.containerOf(
    context,
    listen: false,
  ).read(shellTabProvider.notifier).select(tab);
  Navigator.of(context).popUntil((route) => route.isFirst);
}

/// Customer side of the app: four tabs under a floating navigation bar.
///
/// The body extends behind the bar, and Flutter reports the bar's height
/// as bottom padding (MediaQuery), so every tab pads its scrolling content
/// with `MediaQuery.paddingOf(context).bottom` and nothing hides behind it.
class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(shellTabProvider);
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: tab.index,
        children: const [
          MenuScreen(),
          CartScreen(),
          OrdersScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: const FloatingNavBar(),
    );
  }
}

/// White pill-shaped bar 16px from the screen edges and bottom (above the
/// system safe area). Icons sit in light grey circles; the active one is a
/// solid orange circle with a dark icon.
class FloatingNavBar extends ConsumerWidget {
  const FloatingNavBar({super.key});

  static const double barHeight = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(shellTabProvider);
    final count = ref.watch(cartSummaryProvider.select((s) => s.itemCount));
    final notifier = ref.read(shellTabProvider.notifier);

    Widget item(
      ShellTab tab,
      IconData icon,
      IconData activeIcon,
      String label, {
      int badge = 0,
    }) {
      return _NavItem(
        icon: icon,
        activeIcon: activeIcon,
        label: badge > 0
            ? '$label, $badge ${badge == 1 ? 'item' : 'items'}'
            : label,
        tooltip: label,
        active: active == tab,
        badge: badge,
        onTap: () => notifier.select(tab),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.l),
        child: Container(
          height: barHeight,
          padding: const EdgeInsets.symmetric(horizontal: Gap.s),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              item(
                ShellTab.home,
                Icons.home_outlined,
                Icons.home_rounded,
                'Home',
              ),
              item(
                ShellTab.cart,
                Icons.shopping_bag_outlined,
                Icons.shopping_bag_rounded,
                'Cart',
                badge: count,
              ),
              item(
                ShellTab.orders,
                Icons.receipt_long_outlined,
                Icons.receipt_long_rounded,
                'Orders',
              ),
              item(
                ShellTab.profile,
                Icons.person_outline_rounded,
                Icons.person_rounded,
                'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.tooltip,
    required this.active,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String tooltip;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      inMutuallyExclusiveGroup: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: Badge(
                isLabelVisible: badge > 0,
                label: Text('$badge'),
                offset: const Offset(2, -2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? AppColors.primary : AppColors.chip,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      active ? activeIcon : icon,
                      key: ValueKey(active),
                      size: 22,
                      color: active ? AppColors.text : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The G&C logo for headers and app bars. Long-press opens developer
/// options (Phases 1–3 only); there is deliberately no visible button.
class Wordmark extends StatelessWidget {
  const Wordmark({
    super.key,
    required this.text,
    this.suffix,
    this.height = 40,
  });

  /// Spoken name of the shop for screen readers, e.g. "G&C".
  final String text;

  /// Optional label after the logo, e.g. "Admin".
  final String? suffix;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => showDevPanel(context),
      child: Semantics(
        header: true,
        label: suffix == null ? text : '$text $suffix',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(height: height, semanticLabel: null),
            if (suffix != null) ...[
              const SizedBox(width: Gap.m),
              Text(
                suffix!,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

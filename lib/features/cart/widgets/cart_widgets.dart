import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../cart_providers.dart';
import '../../shell/customer_shell.dart';

/// Shows the Cart tab (closing any screen pushed on top of the shell).
void openCart(BuildContext context) => goToTab(context, ShellTab.cart);

/// Short confirmation after adding to the cart.
void showAddedToCart(BuildContext context, String text) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: Gap.s),
            Expanded(child: Text(text)),
          ],
        ),
        duration: const Duration(milliseconds: 1800),
      ),
    );
}

/// App-bar cart icon with an orange count badge.
class CartIconButton extends ConsumerWidget {
  const CartIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartSummaryProvider.select((s) => s.itemCount));
    return IconButton(
      tooltip: count == 0
          ? 'Cart, empty'
          : 'Cart, $count ${count == 1 ? 'item' : 'items'}',
      onPressed: () => openCart(context),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Badge(
          key: ValueKey(count),
          isLabelVisible: count > 0,
          label: Text('$count'),
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800),
          child: const Icon(Icons.shopping_bag_outlined, size: 26),
        ),
      ),
    );
  }
}

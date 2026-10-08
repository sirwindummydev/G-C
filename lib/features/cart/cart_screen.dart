import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/money.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/menu_image.dart';
import '../../data/models/menu_item.dart';
import '../../data/models/menu_visual.dart';
import '../../data/models/selections.dart';
import '../../domain/item_pricing.dart';
import '../../domain/menu_catalog.dart';
import '../../domain/promo_rules.dart';
import '../../domain/shop_hours.dart';
import '../menu/flavour_palette.dart';
import '../menu/item_detail_screen.dart';
import '../menu/menu_providers.dart';
import '../menu/widgets/order_bar.dart';
import '../menu/widgets/shop_status_banner.dart';
import '../shell/customer_shell.dart';
import 'cart_providers.dart';

/// My Cart: items, smart upsell, recommendations, promo code, summary and
/// the checkout button, on a white sheet over the peach header.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  void _back(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      goToTab(context, ShellTab.home);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(cartSummaryProvider);
    final catalog = ref.watch(menuCatalogProvider).value;

    return Scaffold(
      backgroundColor: AppColors.peachTop,
      body: PeachSheetLayout(
        topBar: AppTopBar(
          title: 'My Cart',
          onBack: () => _back(context),
          backTooltip: 'Back to menu',
          trailing: _CartMenu(enabled: !summary.isEmpty),
        ),
        bottom: summary.isEmpty ? null : _CheckoutArea(summary: summary),
        child: summary.isEmpty
            ? Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom,
                ),
                child: EmptyState(
                  title: 'Your cart is empty',
                  message: 'Hungry? Add some takoyaki or a fruit soda.',
                  actionLabel: 'Browse menu',
                  onAction: () => goToTab(context, ShellTab.home),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(0, Gap.section, 0, Gap.l),
                children: [
                  for (final (i, view) in summary.lines.indexed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Gap.screen,
                        0,
                        Gap.screen,
                        Gap.m,
                      ),
                      child: _DismissibleLine(
                        index: i,
                        view: view,
                        catalog: catalog,
                      ),
                    ),
                  if (catalog != null) ...[
                    _Upsell(summary: summary),
                    _Recommended(summary: summary, catalog: catalog),
                  ],
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                      Gap.screen,
                      Gap.section,
                      Gap.screen,
                      0,
                    ),
                    child: _PromoCodeRow(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Gap.screen,
                      Gap.l,
                      Gap.screen,
                      0,
                    ),
                    child: _Summary(summary: summary),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CartMenu extends ConsumerWidget {
  const _CartMenu({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: PopupMenuButton<String>(
        tooltip: 'Cart options',
        icon: const Icon(Icons.more_vert_rounded, color: AppColors.text),
        onSelected: (value) {
          if (value == 'clear') {
            // Keep the notifier, not `ref`: the undo can run after this
            // widget is gone.
            final cart = ref.read(cartProvider.notifier);
            final previous = ref.read(cartProvider);
            cart.clear();
            showUndoSnack(
              context,
              'Cart cleared',
              () => cart.restore(previous),
            );
          } else if (value == 'menu') {
            goToTab(context, ShellTab.home);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'clear',
            enabled: enabled,
            child: const Text('Clear cart'),
          ),
          const PopupMenuItem(value: 'menu', child: Text('Browse menu')),
        ],
      ),
    );
  }
}

/// A snackbar with an "Undo" action.
void showUndoSnack(BuildContext context, String text, VoidCallback onUndo) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: 'Undo', onPressed: onUndo),
      ),
    );
}

class _DismissibleLine extends ConsumerWidget {
  const _DismissibleLine({
    required this.index,
    required this.view,
    required this.catalog,
  });

  final int index;
  final CartLineView view;
  final MenuCatalog? catalog;

  void _remove(BuildContext context, WidgetRef ref) {
    final line = view.line;
    final cart = ref.read(cartProvider.notifier);
    final position = ref.read(cartProvider).indexWhere((l) => l.id == line.id);
    cart.remove(line.id);
    showUndoSnack(
      context,
      'Removed ${view.title}',
      () => cart.insertAt(position, line),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey('cart-line-${view.line.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _remove(context, ref),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Gap.xl),
        decoration: BoxDecoration(
          color: AppColors.notice,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.text),
            SizedBox(width: Gap.s),
            Text('Remove'),
          ],
        ),
      ),
      child: _CartLineCard(
        view: view,
        catalog: catalog,
        onRemove: () => _remove(context, ref),
      ),
    );
  }
}

class _CartLineCard extends ConsumerWidget {
  const _CartLineCard({
    required this.view,
    required this.catalog,
    required this.onRemove,
  });

  final CartLineView view;
  final MenuCatalog? catalog;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final line = view.line;
    final item = line.item == null
        ? null
        : catalog?.itemById(line.item!.itemId);
    final combo = line.combo == null
        ? null
        : catalog?.comboById(line.combo!.comboId);
    final visual = item?.visual ?? combo?.visual;
    final image = item != null
        ? catalog?.imageForItem(item)
        : (combo == null ? null : catalog?.imageForCombo(combo));
    final drinkColour = item == null
        ? null
        : FlavourPalette.chosenColour(item, line.item!);

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MenuImage(
            visual: visual ?? const MenuVisual(),
            image: image,
            drinkColor: drinkColour,
            size: 72,
            borderRadius: AppRadii.image,
          ),
          const SizedBox(width: Gap.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(view.title, style: AppText.itemName()),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        tooltip: 'Remove ${view.title}',
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        onPressed: onRemove,
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (view.summary.isNotEmpty)
                  Text(
                    view.summary,
                    style: AppText.description(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (view.issues.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: Gap.xs),
                    child: Text(
                      view.issues.first,
                      style: AppText.description().copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                const SizedBox(height: Gap.s),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Money.format(view.lineTotal),
                        style: AppText.price(),
                      ),
                    ),
                    QuantityStepper(
                      value: line.quantity,
                      compact: true,
                      itemName: view.title,
                      onChanged: (q) => ref
                          .read(cartProvider.notifier)
                          .setQuantity(line.id, q),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Smart upsell: switch to a cheaper combo, or add what's missing (e.g. a
/// drink with the takoyaki).
class _Upsell extends ConsumerWidget {
  const _Upsell({required this.summary});

  final CartSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestion = summary.comboSuggestion;
    final upsell = summary.upsell;
    if (suggestion == null && upsell == null) return const SizedBox.shrink();

    final String headline;
    final String body;
    Widget? action;
    if (suggestion != null) {
      headline =
          'Make it a ${suggestion.combo.name} and save '
          '${Money.format(suggestion.savings)}';
      body =
          'Same flavours, combo price: '
          '${Money.format(suggestion.comboPrice)} instead of '
          '${Money.format(suggestion.separatePrice)}.';
      action = FilledButton(
        key: const ValueKey('switch-to-combo'),
        style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
        onPressed: () {
          final cart = ref.read(cartProvider.notifier);
          final previous = ref.read(cartProvider);
          cart.applySuggestion(suggestion);
          showUndoSnack(
            context,
            'Switched to ${suggestion.combo.name}. '
            'You save ${Money.format(suggestion.savings)}.',
            () => cart.restore(previous),
          );
        },
        child: const Text('Switch'),
      );
    } else {
      final (:category, :item) = upsell!;
      final article = RegExp('^[AEIOUaeiou]').hasMatch(item.name) ? 'an' : 'a';
      headline = 'Add $article ${item.name}?';
      body = category.description.isEmpty
          ? 'It goes great with your order.'
          : category.description;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.screen, Gap.m, Gap.screen, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline, style: AppText.promoHeadline()),
          const SizedBox(height: Gap.xs),
          Text(body, style: AppText.description(size: 14)),
          if (action != null) ...[const SizedBox(height: Gap.m), action],
        ],
      ),
    );
  }
}

/// "Recommended": small cards with a compact stepper (items without
/// options) or "+" that opens the builder (items with options).
class _Recommended extends ConsumerWidget {
  const _Recommended({required this.summary, required this.catalog});

  final CartSummary summary;
  final MenuCatalog catalog;

  static const _limit = 8;
  static const _cardWidth = 168.0;
  static const _imageAspect = 1.3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upsellItem = summary.upsell?.item;
    final items = <MenuItem>[
      ?upsellItem,
      for (final c in catalog.visibleCategories)
        for (final item in catalog.itemsIn(c.id))
          if (item.isOrderable && item.id != upsellItem?.id) item,
    ].take(_limit).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    final lines = ref.watch(cartProvider);
    final scaler = MediaQuery.textScalerOf(context);
    // Photo + gap + name + price/stepper row + padding.
    final height =
        (_cardWidth - 20) / _imageAspect + 10 + scaler.scale(20) + 8 + 34 + 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Recommended'),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Gap.screen),
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: Gap.m),
            itemBuilder: (context, i) {
              final item = items[i];
              final plain = ItemSelection(itemId: item.id);
              final line = item.hasOptions
                  ? null
                  : lines.where((l) => l.item == plain).firstOrNull;
              return SizedBox(
                width: _cardWidth,
                child: AppCard(
                  key: ValueKey('recommended-${item.id}'),
                  padding: const EdgeInsets.all(10),
                  onTap: () => _openItem(context, item),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: _imageAspect,
                        child: MenuImage(
                          visual: item.visual,
                          image: catalog.imageForItem(item),
                          borderRadius: AppRadii.image,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.name,
                        style: AppText.itemName(size: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              Money.format(ItemPricing.fromPrice(item)),
                              style: AppText.price(size: 14),
                              maxLines: 1,
                            ),
                          ),
                          if (item.hasOptions)
                            RoundAddButton(
                              semanticLabel: 'Choose options for ${item.name}',
                              onPressed: () => _openItem(context, item),
                              size: 28,
                              outlined: true,
                            )
                          else
                            QuantityStepper(
                              value: line?.quantity ?? 0,
                              min: 0,
                              compact: true,
                              itemName: item.name,
                              onChanged: (q) {
                                final cart = ref.read(cartProvider.notifier);
                                if (line == null) {
                                  cart.addItem(plain, quantity: q);
                                } else {
                                  cart.setQuantity(line.id, q);
                                }
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openItem(BuildContext context, MenuItem item) => Navigator.of(context)
      .push(
        MaterialPageRoute<void>(
          builder: (_) => ItemDetailScreen(itemId: item.id),
        ),
      );
}

/// "Have a promo code?" pill that opens a field, checks the code against
/// the admin's codes, and shows a clear success or error message.
class _PromoCodeRow extends ConsumerStatefulWidget {
  const _PromoCodeRow();

  @override
  ConsumerState<_PromoCodeRow> createState() => _PromoCodeRowState();
}

class _PromoCodeRowState extends ConsumerState<_PromoCodeRow> {
  final _controller = TextEditingController();
  bool _editing = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final codes = ref.read(promoCodesProvider);
    if (!codes.hasValue) {
      setState(
        () => _error = codes.hasError
            ? "Couldn't check promo codes right now. Please try again."
            : 'Checking promo codes… please try again in a moment.',
      );
      return;
    }
    final summary = ref.read(cartSummaryProvider);
    final now =
        ref.read(manilaNowProvider).value ??
        ref.read(clockProvider).nowInManila();
    final result = PromoRules.check(
      input: _controller.text,
      codes: codes.requireValue,
      orderTotal: summary.itemsTotal,
      manilaNow: now,
    );
    switch (result) {
      case PromoAccepted(:final promo):
        ref.read(appliedPromoProvider.notifier).apply(promo.code);
        _controller.clear();
        setState(() {
          _editing = false;
          _error = null;
        });
      case PromoRejected(:final message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Start loading the codes now, so "Apply" can check straight away.
    ref.watch(promoCodesProvider);
    final applied = ref.watch(cartSummaryProvider.select((s) => s.promo));
    final textTheme = Theme.of(context).textTheme;

    if (applied != null && !_editing) {
      final check = applied.check;
      final ok = check is PromoAccepted;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PromoPill(
            icon: ok ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            iconColor: ok ? AppColors.open : AppColors.primaryDark,
            label: ok
                ? '${applied.code} applied'
                : '${applied.code} not applied',
            detail: ok ? 'You save ${Money.format(applied.discount)}' : null,
            action: TextButton(
              onPressed: () => ref.read(appliedPromoProvider.notifier).remove(),
              child: const Text('Remove'),
            ),
          ),
          if (check is PromoRejected)
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, 0),
              child: Text(
                check.message,
                style: textTheme.bodySmall?.copyWith(color: AppColors.text),
              ),
            ),
        ],
      );
    }

    if (!_editing) {
      return _PromoPill(
        icon: Icons.local_offer_outlined,
        iconColor: AppColors.priceOrange,
        label: 'Have a promo code?',
        action: FilledButton(
          key: const ValueKey('promo-open'),
          style: FilledButton.styleFrom(minimumSize: const Size(84, 40)),
          onPressed: () => setState(() => _editing = true),
          child: const Text('Apply'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PromoPill(
          icon: Icons.local_offer_outlined,
          iconColor: AppColors.priceOrange,
          field: TextField(
            key: const ValueKey('promo-field'),
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            style: poppins(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration.collapsed(
              hintText: 'Enter promo code',
              hintStyle: poppins(fontSize: 14, color: AppColors.textMuted),
            ).copyWith(filled: false),
          ),
          action: FilledButton(
            key: const ValueKey('promo-apply'),
            style: FilledButton.styleFrom(minimumSize: const Size(84, 40)),
            onPressed: _submit,
            child: const Text('Apply'),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, 0),
            child: Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: Gap.xs),
                  Expanded(
                    child: Text(
                      _error!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() {
              _editing = false;
              _error = null;
              _controller.clear();
            }),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }
}

class _PromoPill extends StatelessWidget {
  const _PromoPill({
    required this.icon,
    required this.iconColor,
    required this.action,
    this.label,
    this.detail,
    this.field,
  });

  final IconData icon;
  final Color iconColor;
  final String? label;

  /// Second, smaller line under [label], e.g. "You save ₱12.50".
  final String? detail;
  final Widget? field;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.only(left: Gap.l, right: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: Gap.m),
          Expanded(
            child:
                field ??
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label!,
                      style: poppins(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    if (detail != null)
                      Text(
                        detail!,
                        style: poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.open,
                        ),
                      ),
                  ],
                ),
          ),
          const SizedBox(width: Gap.s),
          action,
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary});

  final CartSummary summary;

  @override
  Widget build(BuildContext context) {
    final promo = summary.promo;
    return SummaryCard(
      rows: [
        SummaryRow('Subtotal', Money.format(summary.subtotal)),
        if (summary.comboSavings > 0)
          SummaryRow(
            'Combo savings',
            '−${Money.format(summary.comboSavings)}',
            emphasis: true,
          ),
        if (promo != null && summary.promoDiscount > 0)
          SummaryRow(
            'Promo (${promo.code})',
            '−${Money.format(summary.promoDiscount)}',
            emphasis: true,
          ),
      ],
      totalLabel: 'Total',
      totalValue: Money.format(summary.total),
      footer: Row(
        children: [
          const Icon(
            Icons.storefront_outlined,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: Gap.s),
          Expanded(
            child: Text(
              'Pickup only · pay at pickup · prices include everything',
              style: AppText.description(size: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutArea extends ConsumerWidget {
  const _CheckoutArea({required this.summary});

  final CartSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(shopStatusProvider).value;
    final now =
        ref.watch(manilaNowProvider).value ??
        ref.watch(clockProvider).nowInManila();

    final String label;
    VoidCallback? onPressed;
    if (summary.hasIssues) {
      label = 'Remove unavailable items';
    } else if (status == null) {
      label = 'Checking opening hours…';
    } else if (status.state == ShopState.paused) {
      label = 'Ordering paused';
    } else if (status.state == ShopState.closed) {
      final next = status.nextOpening;
      label = next == null
          ? 'Closed'
          : 'Closed · opens ${_shortWhen(next, now)}';
    } else {
      label = 'Proceed to Checkout · ${Money.format(summary.total)}';
      onPressed = () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checkout arrives in Phase 3.')),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Gap.screen,
        Gap.m,
        Gap.screen,
        // Above the floating navigation bar (reported as bottom padding).
        MediaQuery.paddingOf(context).bottom + Gap.m,
      ),
      child: PillButton(
        key: const ValueKey('checkout'),
        label: label,
        onPressed: onPressed,
      ),
    );
  }

  /// "10:00 AM" for today/tomorrow, "Mon 10:00 AM" further out.
  static String _shortWhen(DateTime next, DateTime now) {
    final when = openingWhen(next, now);
    return when.startsWith('today ') || when.startsWith('tomorrow ')
        ? ShopHours.formatTime(next)
        : when;
  }
}

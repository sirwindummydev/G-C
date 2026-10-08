import 'package:flutter/material.dart';

import '../../core/widgets/components.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/menu_image.dart';
import '../../data/models/menu_item.dart';
import '../../data/models/option_group.dart';
import '../../data/models/selections.dart';
import '../../domain/item_pricing.dart';
import '../../domain/menu_catalog.dart';
import '../cart/cart_providers.dart';
import '../cart/widgets/cart_widgets.dart';
import 'flavour_palette.dart';
import 'menu_providers.dart';
import 'widgets/option_group_selector.dart';
import 'widgets/order_bar.dart';

/// Item detail. For items with options (e.g. Fruit Soda) this is the
/// builder: flavour swatches, size tiles, quantity and add to cart.
class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.itemId, this.heroTag});

  final String itemId;

  /// Hero tag of the card that was tapped, so its picture flies here.
  final Object? heroTag;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  late ItemSelection _selection = ItemSelection(itemId: widget.itemId);
  int _quantity = 1;

  void _onChoiceTap(OptionGroup group, OptionChoice choice) {
    setState(() {
      if (group.isSingleChoice) {
        final alreadyChosen = _selection.isChosen(group.id, choice.id);
        _selection = alreadyChosen && !group.isRequired
            ? _selection.toggle(group.id, choice.id, maxSelect: 1)
            : _selection.choose(group.id, choice.id);
      } else {
        _selection = _selection.toggle(
          group.id,
          choice.id,
          maxSelect: group.maxSelect,
        );
      }
    });
  }

  void _addToCart(MenuItem item) {
    ref.read(cartProvider.notifier).addItem(_selection, quantity: _quantity);
    final summary = ItemPricing.describe(item, _selection);
    showAddedToCart(
      context,
      'Added $_quantity × ${item.name}${summary.isEmpty ? '' : ' ($summary)'}',
    );
    Navigator.of(context).maybePop();
  }

  Color? _chosenColour(MenuItem item) =>
      FlavourPalette.chosenColour(item, _selection);

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(menuCatalogProvider);
    return AsyncValueView<MenuCatalog>(
      value: catalog,
      onRetry: () => retryMenu(ref),
      data: (catalog) {
        final item = catalog.itemById(widget.itemId);
        if (item == null) {
          return const MissingMenuEntry(
            message: 'This item is no longer on the menu.',
          );
        }
        return _buildItem(context, item, catalog.imageForItem(item));
      },
    );
  }

  Widget _buildItem(BuildContext context, MenuItem item, String? image) {
    final theme = Theme.of(context);
    final issues = ItemPricing.validate(item, _selection);
    final total = ItemPricing.unitPrice(item, _selection) * _quantity;
    final price = ItemPricing.hasVariablePrice(item)
        ? 'from ${Money.format(ItemPricing.fromPrice(item))}'
        : Money.format(ItemPricing.fromPrice(item));

    return Scaffold(
      appBar: AppTopBar.auto(context, trailing: const CartIconButton()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.screen, 0, Gap.screen, Gap.xl),
        children: [
          SizedBox(
            height: detailHeroHeight(context),
            // Drinks start neutral and blend into the chosen flavour colour.
            // Photos ignore the tint.
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                end: _chosenColour(item) ?? AppColors.neutralDrink,
              ),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              builder: (context, colour, _) => MenuImage(
                visual: item.visual,
                image: image,
                heroTag: widget.heroTag,
                borderRadius: AppRadii.card,
                dimmed: !item.isOrderable,
                drinkColor: colour,
              ),
            ),
          ),
          const SizedBox(height: Gap.l),
          Semantics(
            header: true,
            child: Text(item.name, style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: Gap.xs),
          Wrap(
            spacing: Gap.s,
            runSpacing: Gap.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(price, style: AppText.price(size: 18)),
              if (item.servingLabel != null)
                Text(
                  '· ${item.servingLabel}',
                  style: AppText.description(size: 15),
                ),
              if (!item.isOrderable)
                const Pill(text: 'Sold out', tone: PillTone.muted),
            ],
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: Gap.s),
            Text(item.description, style: AppText.description(size: 15)),
          ],
          for (final group in item.sortedOptionGroups) ...[
            const SizedBox(height: Gap.xl),
            OptionGroupSelector(
              group: group,
              choices: group.sortedChoices,
              selectedIds: _selection.choicesFor(group.id),
              onTap: (choice) => _onChoiceTap(group, choice),
              priceLabel: (choice) =>
                  switch (ItemPricing.choiceLabelPrice(item, group, choice)) {
                    null => null,
                    final p when group.showAbsolutePrice => Money.format(p),
                    final p => Money.formatDelta(p),
                  },
              unitPrice: (choice) => item.basePrice + choice.priceDelta,
            ),
          ],
        ],
      ),
      bottomNavigationBar: OrderBar(
        leading: QuantityStepper(
          value: _quantity,
          onChanged: (q) => setState(() => _quantity = q),
        ),
        hint: issues.isEmpty ? null : issues.first,
        buttonText: !item.isOrderable
            ? 'Sold out'
            : issues.isEmpty
            ? 'Add to cart · ${Money.format(total)}'
            : 'Add to cart',
        onPressed: issues.isEmpty ? () => _addToCart(item) : null,
      ),
    );
  }
}

/// Shown when a menu entry was removed while the customer was viewing it.
class MissingMenuEntry extends StatelessWidget {
  const MissingMenuEntry({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar.auto(context),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Gap.xl),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

/// Hero picture height on detail screens: about 40% of the screen.
double detailHeroHeight(BuildContext context) =>
    MediaQuery.sizeOf(context).height * 0.4;

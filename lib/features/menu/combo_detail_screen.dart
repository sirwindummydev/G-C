import 'package:flutter/material.dart';

import '../../core/widgets/components.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/capsule_chip.dart';
import '../../core/widgets/menu_image.dart';
import '../../data/models/combo.dart';
import '../../data/models/option_group.dart';
import '../../data/models/selections.dart';
import '../../domain/combo_pricing.dart';
import '../../domain/menu_catalog.dart';
import '../cart/cart_providers.dart';
import '../cart/widgets/cart_widgets.dart';
import 'item_detail_screen.dart';
import 'menu_providers.dart';
import 'widgets/option_group_selector.dart';
import 'widgets/order_bar.dart';

class ComboDetailScreen extends ConsumerStatefulWidget {
  const ComboDetailScreen({super.key, required this.comboId, this.heroTag});

  final String comboId;

  /// Hero tag of the card that was tapped, so its picture flies here.
  final Object? heroTag;

  @override
  ConsumerState<ComboDetailScreen> createState() => _ComboDetailScreenState();
}

class _ComboDetailScreenState extends ConsumerState<ComboDetailScreen> {
  late ComboSelection _selection = ComboSelection(comboId: widget.comboId);
  int _quantity = 1;
  bool _defaultsApplied = false;

  /// Fills slots that have only one possible item (e.g. the Fruit Soda in
  /// the Merienda Combo), so the customer only picks what matters.
  void _applyDefaults(Combo combo, ComboPricing pricing) {
    if (_defaultsApplied) return;
    _defaultsApplied = true;
    for (final slot in combo.slots) {
      final pickable = pricing
          .optionsFor(slot)
          .where((o) => o.isPickable)
          .toList();
      if (pickable.length != 1) continue;
      for (var i = 0; i < slot.picks; i++) {
        _selection = _selection.setPick(
          slot.id,
          i,
          slot.picks,
          ItemSelection(itemId: pickable.single.item.id),
        );
      }
    }
  }

  void _update(ComboSelection next) => setState(() => _selection = next);

  void _addToCart(Combo combo) {
    ref.read(cartProvider.notifier).addCombo(_selection, quantity: _quantity);
    showAddedToCart(context, 'Added $_quantity × ${combo.name} to your cart');
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(menuCatalogProvider);
    return AsyncValueView<MenuCatalog>(
      value: catalog,
      onRetry: () => retryMenu(ref),
      data: (catalog) {
        final combo = catalog.comboById(widget.comboId);
        if (combo == null) {
          return const MissingMenuEntry(
            message: 'This combo is no longer on the menu.',
          );
        }
        final pricing = ComboPricing(catalog);
        _applyDefaults(combo, pricing);
        return _buildCombo(
          context,
          combo,
          pricing,
          catalog.imageForCombo(combo),
        );
      },
    );
  }

  Widget _buildCombo(
    BuildContext context,
    Combo combo,
    ComboPricing pricing,
    String? image,
  ) {
    final theme = Theme.of(context);
    final orderable = pricing.isOrderable(combo);
    final issues = pricing.validate(combo, _selection);
    final total = pricing.total(combo, _selection) * _quantity;
    final saved = pricing.savings(combo, _selection);
    final guaranteed = pricing.guaranteedSavings(combo);

    return Scaffold(
      appBar: AppTopBar.auto(context, trailing: const CartIconButton()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.screen, 0, Gap.screen, Gap.xl),
        children: [
          SizedBox(
            height: detailHeroHeight(context),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MenuImage(
                  visual: combo.visual,
                  image: image,
                  heroTag: widget.heroTag,
                  borderRadius: AppRadii.card,
                  dimmed: !orderable,
                ),
                if (orderable && guaranteed != null)
                  Positioned(
                    left: Gap.m,
                    top: Gap.m,
                    child: Pill(
                      text: 'Save ${Money.format(guaranteed)}',
                      tone: PillTone.accent,
                      elevated: true,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Gap.l),
          Semantics(
            header: true,
            child: Text(combo.name, style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: Gap.xs),
          Wrap(
            spacing: Gap.s,
            runSpacing: Gap.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(Money.format(combo.price), style: AppText.price(size: 18)),
              if (combo.servingLabel != null)
                Text(
                  '· ${combo.servingLabel}',
                  style: AppText.description(size: 15),
                ),
              if (!orderable)
                const Pill(text: 'Sold out', tone: PillTone.muted),
            ],
          ),
          if (combo.description.isNotEmpty) ...[
            const SizedBox(height: Gap.s),
            Text(combo.description, style: AppText.description(size: 15)),
          ],
          for (final slot in combo.sortedSlots) ...[
            const SizedBox(height: Gap.xl),
            _SlotSection(
              slot: slot,
              options: pricing.optionsFor(slot),
              pricing: pricing,
              selection: _selection,
              onChanged: _update,
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
        savingsText: saved == null
            ? null
            : 'You save ${Money.format(saved * _quantity)}',
        buttonText: !orderable
            ? 'Sold out'
            : issues.isEmpty
            ? 'Add to cart · ${Money.format(total)}'
            : 'Add to cart',
        onPressed: issues.isEmpty ? () => _addToCart(combo) : null,
      ),
    );
  }
}

class _SlotSection extends StatelessWidget {
  const _SlotSection({
    required this.slot,
    required this.options,
    required this.pricing,
    required this.selection,
    required this.onChanged,
  });

  final ComboSlot slot;
  final List<SlotOption> options;
  final ComboPricing pricing;
  final ComboSelection selection;
  final ValueChanged<ComboSelection> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picks = selection.picksFor(slot.id, slot.picks);
    final filled = picks.nonNulls.length;
    final simpleItems = options.every((o) => !o.item.hasOptions);
    final done = filled == slot.picks;

    // Slots of items with options (e.g. the drink) are tracked by their own
    // option groups, so only plain-item slots get a tag here.
    HeaderTag? tag;
    if (simpleItems && options.isNotEmpty) {
      if (slot.picks > 1) {
        tag = HeaderTag(
          text: '$filled of ${slot.picks} selected',
          tone: done ? TagTone.done : TagTone.required,
        );
      } else if (done) {
        final name = pricing.optionFor(slot, picks.first!.itemId)?.item.name;
        tag = HeaderTag(text: name ?? 'Chosen', tone: TagTone.done);
      } else {
        tag = const HeaderTag(text: 'Required', tone: TagTone.required);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  slot.name,
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                ),
              ),
            ),
            if (tag != null) ...[const SizedBox(width: Gap.s), tag],
          ],
        ),
        if (slot.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(slot.description, style: AppText.description(size: 14)),
          ),
        const SizedBox(height: Gap.s),
        if (options.isEmpty)
          Text(
            'Nothing available for this part right now.',
            style: AppText.description(size: 14),
          )
        else if (simpleItems)
          _ChipPicker(
            slot: slot,
            options: options,
            selection: selection,
            onChanged: onChanged,
          )
        else
          for (var i = 0; i < slot.picks; i++)
            _ConfigurablePick(
              slot: slot,
              index: i,
              options: options,
              pricing: pricing,
              selection: selection,
              onChanged: onChanged,
            ),
      ],
    );
  }
}

/// For slots of plain items (e.g. takoyaki flavours): capsule chips.
///
/// - One pick: radio buttons.
/// - Several picks, no repeats: tap to select or deselect; the rest fade
///   once the slot is full.
/// - Several picks, repeats allowed: tap adds one ("×2" when picked twice),
///   and the "−" inside a selected chip removes one.
class _ChipPicker extends StatelessWidget {
  const _ChipPicker({
    required this.slot,
    required this.options,
    required this.selection,
    required this.onChanged,
  });

  final ComboSlot slot;
  final List<SlotOption> options;
  final ComboSelection selection;
  final ValueChanged<ComboSelection> onChanged;

  @override
  Widget build(BuildContext context) {
    final picks = selection.picksFor(slot.id, slot.picks);
    final full = picks.every((p) => p != null);
    final single = slot.picks == 1;
    final repeats = !single && slot.allowDuplicates;

    int countOf(String itemId) =>
        picks.where((p) => p?.itemId == itemId).length;

    void add(String itemId) {
      final index = picks.indexOf(null);
      if (index < 0) return;
      onChanged(
        selection.setPick(
          slot.id,
          index,
          slot.picks,
          ItemSelection(itemId: itemId),
        ),
      );
    }

    void remove(String itemId) {
      final index = picks.lastIndexWhere((p) => p?.itemId == itemId);
      if (index < 0) return;
      onChanged(selection.setPick(slot.id, index, slot.picks, null));
    }

    void choose(String itemId) => onChanged(
      selection.setPick(slot.id, 0, 1, ItemSelection(itemId: itemId)),
    );

    CapsuleChip chipFor(SlotOption option) {
      final id = option.item.id;
      final name = option.item.name;
      final count = countOf(id);
      final selected = count > 0;
      final upcharge = option.rule.upcharge;

      VoidCallback? onTap;
      if (!option.isPickable) {
        onTap = null;
      } else if (single) {
        onTap = () => choose(id);
      } else if (!slot.allowDuplicates) {
        onTap = selected ? () => remove(id) : (full ? null : () => add(id));
      } else {
        onTap = full ? null : () => add(id);
      }

      return CapsuleChip(
        key: ValueKey('pick-${slot.id}-$id'),
        label: name,
        detail: upcharge > 0 ? Money.formatDelta(upcharge) : null,
        dotColor: MenuImage.parseColor(option.item.visual.colorHex),
        selected: selected,
        soldOut: !option.isPickable,
        count: count,
        radioStyle: single,
        onTap: onTap,
        onRemove: repeats && selected ? () => remove(id) : null,
        removeTooltip: 'Remove one $name',
        semanticLabel: !option.isPickable
            ? '$name, sold out'
            : [
                name,
                if (upcharge > 0) Money.formatDelta(upcharge),
                if (count > 1)
                  'selected $count times'
                else if (selected)
                  'selected',
              ].join(', '),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (repeats)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.xs),
            child: Text(
              'Tap to add · tap again for more · − to remove',
              style: AppText.description(size: 12),
            ),
          ),
        Wrap(
          spacing: Gap.s,
          children: [for (final option in options) chipFor(option)],
        ),
      ],
    );
  }
}

/// For slots whose items have options (e.g. Fruit Soda): choose the item,
/// then its options, once per pick.
class _ConfigurablePick extends StatelessWidget {
  const _ConfigurablePick({
    required this.slot,
    required this.index,
    required this.options,
    required this.pricing,
    required this.selection,
    required this.onChanged,
  });

  final ComboSlot slot;
  final int index;
  final List<SlotOption> options;
  final ComboPricing pricing;
  final ComboSelection selection;
  final ValueChanged<ComboSelection> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picks = selection.picksFor(slot.id, slot.picks);
    final pick = picks[index];
    final chosen = pick == null ? null : pricing.optionFor(slot, pick.itemId);
    final takenElsewhere = {
      for (var i = 0; i < picks.length; i++)
        if (i != index && picks[i] != null) picks[i]!.itemId,
    };

    void setPick(ItemSelection? next) =>
        onChanged(selection.setPick(slot.id, index, slot.picks, next));

    void onChoiceTap(OptionGroup group, OptionChoice choice) {
      final current = pick!;
      if (group.isSingleChoice) {
        final already = current.isChosen(group.id, choice.id);
        setPick(
          already && !group.isRequired
              ? current.toggle(group.id, choice.id, maxSelect: 1)
              : current.choose(group.id, choice.id),
        );
      } else {
        setPick(
          current.toggle(group.id, choice.id, maxSelect: group.maxSelect),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.l),
      child: AppCard(
        padding: const EdgeInsets.all(Gap.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (slot.picks > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.s),
                child: Text(
                  'Pick ${index + 1}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            if (options.length > 1)
              Wrap(
                spacing: Gap.s,
                children: [
                  for (final option in options)
                    CapsuleChip(
                      label: option.item.name,
                      detail: option.rule.upcharge > 0
                          ? Money.formatDelta(option.rule.upcharge)
                          : null,
                      dotColor: MenuImage.parseColor(
                        option.item.visual.colorHex,
                      ),
                      selected: pick?.itemId == option.item.id,
                      soldOut: !option.isPickable,
                      onTap:
                          !option.isPickable ||
                              (!slot.allowDuplicates &&
                                  takenElsewhere.contains(option.item.id))
                          ? null
                          : () =>
                                setPick(ItemSelection(itemId: option.item.id)),
                      semanticLabel: !option.isPickable
                          ? '${option.item.name}, sold out'
                          : [
                              option.item.name,
                              if (pick?.itemId == option.item.id) 'selected',
                            ].join(', '),
                    ),
                ],
              ),
            if (chosen != null) ...[
              if (options.length == 1)
                Row(
                  children: [
                    MenuImage(
                      visual: chosen.item.visual,
                      size: 40,
                      borderRadius: AppRadii.image,
                    ),
                    const SizedBox(width: Gap.m),
                    Text(chosen.item.name, style: AppText.itemName()),
                  ],
                ),
              for (final group in chosen.item.sortedOptionGroups) ...[
                const SizedBox(height: Gap.l),
                OptionGroupSelector(
                  group: group,
                  choices: chosen.allowedChoices(group),
                  selectedIds: pick!.choicesFor(group.id),
                  onTap: (choice) => onChoiceTap(group, choice),
                  priceLabel: (choice) {
                    final upcharge = chosen.choiceUpcharge(group, choice);
                    if (upcharge != 0) return Money.formatDelta(upcharge);
                    return choice.hasMeasure ? 'Included' : null;
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

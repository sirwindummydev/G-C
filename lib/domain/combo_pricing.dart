import '../data/models/combo.dart';
import '../data/models/menu_item.dart';
import '../data/models/option_group.dart';
import '../data/models/selections.dart';
import 'item_pricing.dart';
import 'menu_catalog.dart';

/// An item that may fill a combo slot, with the combo's rules for it.
class SlotOption {
  const SlotOption(this.item, this.rule);

  final MenuItem item;
  final ComboSlotChoice rule;

  /// Choices of [group] the customer may pick inside the combo (sold-out
  /// ones included, so the UI can show them disabled).
  List<OptionChoice> allowedChoices(OptionGroup group) {
    final groupRule = rule.ruleFor(group.id);
    return group.sortedChoices
        .where((c) => groupRule == null || groupRule.allows(c.id))
        .toList();
  }

  /// Extra charge for picking [choice] inside the combo.
  int choiceUpcharge(OptionGroup group, OptionChoice choice) {
    final groupRule = rule.ruleFor(group.id);
    return groupRule == null
        ? choice.priceDelta
        : groupRule.upchargeFor(choice.id);
  }

  /// Whether this item can currently be picked in the combo.
  bool get isPickable =>
      item.isOrderable &&
      item.optionGroups.every((g) {
        if (!g.isRequired) return true;
        final available = allowedChoices(g).where((c) => c.isAvailable).length;
        return available >= g.minSelect;
      });
}

/// Prices and rules for combos. All amounts are centavos.
class ComboPricing {
  const ComboPricing(this.catalog);

  final MenuCatalog catalog;

  /// Items that may fill [slot]: everything in its eligible categories plus
  /// its explicit choices, in menu order, without duplicates. Includes
  /// sold-out items so they can be shown disabled.
  List<SlotOption> optionsFor(ComboSlot slot) {
    final result = <String, SlotOption>{};
    for (final item in catalog.items) {
      final explicit = slot.explicitChoiceFor(item.id);
      if (explicit != null) {
        result[item.id] = SlotOption(item, explicit);
      } else if (slot.eligibleCategoryIds.contains(item.categoryId)) {
        result[item.id] = SlotOption(item, ComboSlotChoice(itemId: item.id));
      }
    }
    return result.values.toList();
  }

  SlotOption? optionFor(ComboSlot slot, String itemId) {
    for (final option in optionsFor(slot)) {
      if (option.item.id == itemId) return option;
    }
    return null;
  }

  /// Whether a customer can order [combo] right now.
  bool isOrderable(Combo combo) {
    if (!combo.isAvailable || combo.slots.isEmpty) return false;
    for (final slot in combo.slots) {
      final pickable = optionsFor(slot).where((o) => o.isPickable).length;
      if (pickable == 0) return false;
      if (!slot.allowDuplicates && pickable < slot.picks) return false;
    }
    return true;
  }

  /// Extra charge for one pick (item upcharge + option upgrade charges).
  int pickUpcharge(SlotOption option, ItemSelection pick) {
    var total = option.rule.upcharge;
    for (final group in option.item.optionGroups) {
      for (final id in pick.choicesFor(group.id)) {
        final choice = group.choiceById(id);
        if (choice != null) total += option.choiceUpcharge(group, choice);
      }
    }
    return total;
  }

  /// Price of the combo with the picks made so far.
  int total(Combo combo, ComboSelection selection) {
    var sum = combo.price;
    for (final slot in combo.slots) {
      for (final pick in selection.picksFor(slot.id, slot.picks).nonNulls) {
        final option = optionFor(slot, pick.itemId);
        if (option != null) sum += pickUpcharge(option, pick);
      }
    }
    return sum;
  }

  /// What the picks made so far would cost if bought separately.
  int separatePrice(Combo combo, ComboSelection selection) {
    var sum = 0;
    for (final slot in combo.slots) {
      for (final pick in selection.picksFor(slot.id, slot.picks).nonNulls) {
        final item = catalog.itemById(pick.itemId);
        if (item != null) sum += ItemPricing.unitPrice(item, pick);
      }
    }
    return sum;
  }

  /// "You save ₱X" for a complete selection. Null when the selection is not
  /// complete or there is no saving.
  int? savings(Combo combo, ComboSelection selection) {
    if (validate(combo, selection).isNotEmpty) return null;
    final saved = separatePrice(combo, selection) - total(combo, selection);
    return saved > 0 ? saved : null;
  }

  /// The smallest saving any valid selection gets, for menu cards
  /// ("Save ₱10"). Null when there is no guaranteed saving or the combo
  /// cannot be ordered.
  int? guaranteedSavings(Combo combo) {
    if (!isOrderable(combo)) return null;
    var sum = 0;
    for (final slot in combo.slots) {
      int? best;
      for (final option in optionsFor(slot).where((o) => o.isPickable)) {
        final value = _minPickSaving(option);
        if (best == null || value < best) best = value;
      }
      if (best == null) return null;
      sum += best * slot.picks;
    }
    final saved = sum - combo.price;
    return saved > 0 ? saved : null;
  }

  /// Lowest price the combo can be ordered for (the combo price plus the
  /// cheapest unavoidable upcharges).
  int fromPrice(Combo combo) {
    var sum = combo.price;
    for (final slot in combo.slots) {
      int? cheapest;
      for (final option in optionsFor(slot).where((o) => o.isPickable)) {
        var value = option.rule.upcharge;
        for (final group in option.item.optionGroups.where(
          (g) => g.isRequired,
        )) {
          final charges =
              option
                  .allowedChoices(group)
                  .where((c) => c.isAvailable)
                  .map((c) => option.choiceUpcharge(group, c))
                  .toList()
                ..sort();
          value += charges.take(group.minSelect).fold(0, (a, b) => a + b);
        }
        if (cheapest == null || value < cheapest) cheapest = value;
      }
      sum += (cheapest ?? 0) * slot.picks;
    }
    return sum;
  }

  /// Standalone price minus combo upcharge for the least favourable choices.
  int _minPickSaving(SlotOption option) {
    var value = option.item.basePrice - option.rule.upcharge;
    for (final group in option.item.optionGroups.where((g) => g.isRequired)) {
      final perChoice =
          option
              .allowedChoices(group)
              .where((c) => c.isAvailable)
              .map((c) => c.priceDelta - option.choiceUpcharge(group, c))
              .toList()
            ..sort();
      value += perChoice.take(group.minSelect).fold(0, (a, b) => a + b);
    }
    return value;
  }

  /// Problems that stop [selection] from being ordered. Empty means valid.
  List<String> validate(Combo combo, ComboSelection selection) {
    if (!isOrderable(combo)) {
      return ['${combo.name} is not available right now.'];
    }
    final issues = <String>[];
    for (final slot in combo.sortedSlots) {
      final picks = selection.picksFor(slot.id, slot.picks);
      final missing = picks.where((p) => p == null).length;
      if (missing > 0) {
        issues.add(
          slot.picks == 1
              ? 'Choose your ${slot.name.toLowerCase()}.'
              : 'Choose $missing more for ${slot.name}.',
        );
      }
      final seen = <String>{};
      for (final pick in picks.nonNulls) {
        if (!slot.allowDuplicates && !seen.add(pick.itemId)) {
          issues.add('Pick different items for ${slot.name}.');
        }
        issues.addAll(validatePick(slot, pick));
      }
    }
    return issues;
  }

  /// Problems with a single pick inside [slot].
  List<String> validatePick(ComboSlot slot, ItemSelection pick) {
    final option = optionFor(slot, pick.itemId);
    if (option == null) return ['That item is not part of this combo.'];
    if (!option.isPickable) return ['${option.item.name} is sold out.'];
    final issues = <String>[];
    for (final group in option.item.sortedOptionGroups) {
      final rule = option.rule.ruleFor(group.id);
      issues.addAll(
        ItemPricing.validateGroup(
          group,
          pick.choicesFor(group.id),
          isAllowed: rule?.allows,
        ),
      );
    }
    return issues;
  }
}

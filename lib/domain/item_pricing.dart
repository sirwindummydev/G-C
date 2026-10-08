import '../data/models/menu_item.dart';
import '../data/models/option_group.dart';
import '../data/models/selections.dart';

/// Prices and rules for ordering a single menu item. All amounts are
/// centavos.
abstract final class ItemPricing {
  /// Price of one unit of [item] with the chosen options.
  /// Unknown choice ids are ignored here; [validate] reports them.
  static int unitPrice(MenuItem item, ItemSelection selection) {
    var total = item.basePrice;
    for (final group in item.optionGroups) {
      for (final choiceId in selection.choicesFor(group.id)) {
        total += group.choiceById(choiceId)?.priceDelta ?? 0;
      }
    }
    return total;
  }

  /// Lowest price a customer can pay for one unit, using the cheapest
  /// available choices in each required group. Shown as "From ₱35".
  static int fromPrice(MenuItem item) {
    var total = item.basePrice;
    for (final group in item.optionGroups.where((g) => g.isRequired)) {
      final pool = group.availableChoices.isEmpty
          ? group.choices
          : group.availableChoices;
      final deltas = pool.map((c) => c.priceDelta).toList()..sort();
      total += deltas.take(group.minSelect).fold(0, (a, b) => a + b);
    }
    return total;
  }

  /// Short text of the chosen options in menu order, e.g. "Mango, 20oz".
  static String describe(MenuItem item, ItemSelection selection) => [
    for (final group in item.sortedOptionGroups)
      for (final choice in group.sortedChoices)
        if (selection.isChosen(group.id, choice.id)) choice.name,
  ].join(', ');

  /// True when the price depends on the options chosen.
  static bool hasVariablePrice(MenuItem item) => item.optionGroups.any(
    (g) => g.choices.map((c) => c.priceDelta).toSet().length > 1,
  );

  /// Price shown on a choice chip: the full item price for groups that show
  /// absolute prices (sizes), otherwise the extra charge, or null for ₱0.
  static int? choiceLabelPrice(
    MenuItem item,
    OptionGroup group,
    OptionChoice choice,
  ) {
    if (group.showAbsolutePrice) return item.basePrice + choice.priceDelta;
    return choice.priceDelta == 0 ? null : choice.priceDelta;
  }

  /// Problems that stop [selection] from being ordered. Empty means valid.
  static List<String> validate(MenuItem item, ItemSelection selection) {
    final issues = <String>[];
    if (!item.isAvailable) {
      issues.add('${item.name} is sold out.');
      return issues;
    }
    for (final group in item.sortedOptionGroups) {
      issues.addAll(validateGroup(group, selection.choicesFor(group.id)));
    }
    return issues;
  }

  /// Validates the choices for one group. [isAllowed] lets combos restrict
  /// choices further.
  static List<String> validateGroup(
    OptionGroup group,
    List<String> chosenIds, {
    bool Function(String choiceId)? isAllowed,
  }) {
    final issues = <String>[];
    final count = chosenIds.toSet().length;
    if (count < group.minSelect) {
      issues.add(
        group.minSelect == 1
            ? 'Choose a ${group.name.toLowerCase()}.'
            : 'Choose at least ${group.minSelect} for ${group.name}.',
      );
    }
    if (count > group.maxSelect) {
      issues.add('Choose at most ${group.maxSelect} for ${group.name}.');
    }
    for (final id in chosenIds) {
      final choice = group.choiceById(id);
      if (choice == null || (isAllowed != null && !isAllowed(id))) {
        issues.add(
          'A ${group.name.toLowerCase()} choice is no longer offered.',
        );
      } else if (!choice.isAvailable) {
        issues.add('${choice.name} is sold out.');
      }
    }
    return issues;
  }
}

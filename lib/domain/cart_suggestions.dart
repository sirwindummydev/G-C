import '../data/models/category.dart';
import '../data/models/combo.dart';
import '../data/models/menu_item.dart';
import '../data/models/selections.dart';
import 'cart_line.dart';
import 'combo_pricing.dart';
import 'item_pricing.dart';
import 'menu_catalog.dart';

/// "Make it a Merienda Combo and save ₱10": items already in the cart that
/// fill a cheaper combo's slots.
class ComboSuggestion {
  const ComboSuggestion({
    required this.combo,
    required this.selection,
    required this.consumed,
    required this.separatePrice,
    required this.comboPrice,
  });

  final Combo combo;

  /// The combo built from the customer's own choices (flavours, sizes).
  final ComboSelection selection;

  /// Units taken from each cart line, by line id.
  final Map<String, int> consumed;

  /// What the consumed units cost now, in centavos.
  final int separatePrice;

  /// What the combo costs, in centavos (price + any upgrade charges).
  final int comboPrice;

  int get savings => separatePrice - comboPrice;
}

/// Finds combo swaps and simple upsells for a cart. Pure Dart.
class CartSuggestions {
  CartSuggestions(this.catalog) : _pricing = ComboPricing(catalog);

  final MenuCatalog catalog;
  final ComboPricing _pricing;

  /// The combo swap that saves the most, or null when none saves money.
  ///
  /// Only plain item lines are used (combos already in the cart stay as
  /// they are). Each pick must pass the combo's own rules, e.g. Merienda
  /// only accepts a 16oz or 20oz soda.
  ComboSuggestion? bestCombo(List<CartLine> lines) {
    final itemLines = [
      for (final line in lines)
        if (line.item != null &&
            line.quantity > 0 &&
            catalog.itemById(line.item!.itemId) != null)
          line,
    ];
    if (itemLines.isEmpty) return null;

    ComboSuggestion? best;
    for (final combo in catalog.combos) {
      if (!_pricing.isOrderable(combo)) continue;
      final found = _bestFor(combo, itemLines);
      if (found != null && (best == null || found.savings > best.savings)) {
        best = found;
      }
    }
    return best;
  }

  ComboSuggestion? _bestFor(Combo combo, List<CartLine> lines) {
    final slots = combo.sortedSlots;
    final positions = [
      for (final slot in slots)
        for (var i = 0; i < slot.picks; i++) (slot: slot, index: i),
    ];
    final remaining = {for (final l in lines) l.id: l.quantity};
    final chosen = List<int?>.filled(positions.length, null);
    ComboSuggestion? best;

    void search(int k) {
      if (k == positions.length) {
        var selection = ComboSelection(comboId: combo.id);
        var separate = 0;
        final consumed = <String, int>{};
        for (var p = 0; p < positions.length; p++) {
          final line = lines[chosen[p]!];
          final (:slot, :index) = positions[p];
          selection = selection.setPick(slot.id, index, slot.picks, line.item);
          separate += ItemPricing.unitPrice(
            catalog.itemById(line.item!.itemId)!,
            line.item!,
          );
          consumed.update(line.id, (n) => n + 1, ifAbsent: () => 1);
        }
        if (_pricing.validate(combo, selection).isNotEmpty) return;
        final price = _pricing.total(combo, selection);
        if (price >= separate) return;
        final candidate = ComboSuggestion(
          combo: combo,
          selection: selection,
          consumed: consumed,
          separatePrice: separate,
          comboPrice: price,
        );
        if (best == null || candidate.savings > best!.savings) best = candidate;
        return;
      }

      final (:slot, :index) = positions[k];
      // Picks within a slot are interchangeable: only try lines in
      // non-decreasing order to skip duplicate permutations.
      final start = index > 0 ? chosen[k - 1]! : 0;
      for (var i = start; i < lines.length; i++) {
        final line = lines[i];
        if (remaining[line.id]! <= 0) continue;
        if (_pricing.validatePick(slot, line.item!).isNotEmpty) continue;
        if (!slot.allowDuplicates) {
          final sameItem = [
            for (var p = k - index; p < k; p++) lines[chosen[p]!].item!.itemId,
          ].contains(line.item!.itemId);
          if (sameItem) continue;
        }
        remaining[line.id] = remaining[line.id]! - 1;
        chosen[k] = i;
        search(k + 1);
        chosen[k] = null;
        remaining[line.id] = remaining[line.id]! + 1;
      }
    }

    search(0);
    return best;
  }

  /// Categories represented in the cart, including items inside combos.
  Set<String> categoriesIn(List<CartLine> lines) => {
    for (final line in lines)
      if (line.item case final pick?)
        ?catalog.itemById(pick.itemId)?.categoryId
      else
        for (final pick in line.combo!.filledPicks)
          ?catalog.itemById(pick.itemId)?.categoryId,
  };

  /// An item from a menu category the cart doesn't have yet (e.g. a
  /// Fruit Soda when there is takoyaki but no drink), in menu order.
  ({Category category, MenuItem item})? missingCategoryPick(
    List<CartLine> lines,
  ) {
    if (lines.isEmpty) return null;
    final present = categoriesIn(lines);
    for (final category in catalog.visibleCategories) {
      if (present.contains(category.id)) continue;
      for (final item in catalog.itemsIn(category.id)) {
        if (item.isOrderable) return (category: category, item: item);
      }
    }
    return null;
  }
}

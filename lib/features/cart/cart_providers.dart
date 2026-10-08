import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../data/models/category.dart';
import '../../data/models/menu_item.dart';
import '../../data/models/promo_code.dart';
import '../../data/models/selections.dart';
import '../../data/repositories/providers.dart';
import '../../domain/cart_line.dart';
import '../../domain/cart_suggestions.dart';
import '../../domain/combo_pricing.dart';
import '../../domain/item_pricing.dart';
import '../../domain/menu_catalog.dart';
import '../../domain/promo_rules.dart';
import '../menu/menu_providers.dart';

export '../../domain/cart_line.dart';

/// A cart line resolved against the menu, for display.
class CartLineView {
  const CartLineView({
    required this.line,
    required this.title,
    required this.summary,
    required this.unitPrice,
    required this.regularUnitPrice,
    required this.issues,
  });

  final CartLine line;
  final String title;

  /// Chosen options, e.g. "Lemon · 20oz" or "4 pcs".
  final String summary;

  /// What one unit costs, in centavos.
  final int unitPrice;

  /// What one unit would cost bought separately (differs for combos).
  final int regularUnitPrice;

  /// Why the line can't be ordered now (e.g. sold out). Empty when fine.
  final List<String> issues;

  int get lineTotal => unitPrice * line.quantity;
  int get regularTotal => regularUnitPrice * line.quantity;
}

/// In-memory cart. Phase 3 adds notes, checkout and persistence.
class CartNotifier extends Notifier<List<CartLine>> {
  int _nextId = 0;

  @override
  List<CartLine> build() => const [];

  /// Adds an item; the same item with the same options merges into one line.
  void addItem(ItemSelection selection, {int quantity = 1}) {
    final index = state.indexWhere((l) => l.item == selection);
    if (index >= 0) {
      final line = state[index];
      state = [...state]..[index] = line.withQuantity(line.quantity + quantity);
    } else {
      state = [
        ...state,
        CartLine.item(id: '${_nextId++}', item: selection, quantity: quantity),
      ];
    }
  }

  void addCombo(ComboSelection selection, {int quantity = 1}) {
    state = [
      ...state,
      CartLine.combo(id: '${_nextId++}', combo: selection, quantity: quantity),
    ];
  }

  /// Sets a line's quantity; 0 or less removes it.
  void setQuantity(String lineId, int quantity) {
    state = [
      for (final line in state)
        if (line.id != lineId)
          line
        else if (quantity > 0)
          line.withQuantity(quantity),
    ];
  }

  void remove(String lineId) => setQuantity(lineId, 0);

  /// Puts back a removed line at its old position (for "Undo").
  void insertAt(int index, CartLine line) {
    state = [...state]..insert(index.clamp(0, state.length), line);
  }

  /// Replaces the whole cart (for "Undo" after a combo switch).
  void restore(List<CartLine> lines) => state = List.unmodifiable(lines);

  /// Swaps the suggested items for the combo, keeping their flavours.
  void applySuggestion(ComboSuggestion suggestion) {
    state = [
      for (final line in state)
        if (!suggestion.consumed.containsKey(line.id))
          line
        else if (line.quantity > suggestion.consumed[line.id]!)
          line.withQuantity(line.quantity - suggestion.consumed[line.id]!),
    ];
    addCombo(suggestion.selection);
  }

  void clear() => state = const [];
}

final cartProvider = NotifierProvider<CartNotifier, List<CartLine>>(
  CartNotifier.new,
);

/// The promo code the customer applied (normalised), or null.
class AppliedPromoNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void apply(String code) => state = PromoCode.normalise(code);

  void remove() => state = null;
}

final appliedPromoProvider = NotifierProvider<AppliedPromoNotifier, String?>(
  AppliedPromoNotifier.new,
);

final promoCodesProvider = StreamProvider<List<PromoCode>>(
  (ref) => ref.watch(promoRepositoryProvider).watchPromoCodes(),
);

/// Resolves a [CartLine] against the menu. Null if the item or combo was
/// removed from the menu.
CartLineView? resolveCartLine(CartLine line, MenuCatalog catalog) {
  String options(MenuItem item, ItemSelection pick) => [
    for (final group in item.sortedOptionGroups)
      for (final choice in group.sortedChoices)
        if (pick.isChosen(group.id, choice.id)) choice.name,
  ].join(' · ');

  if (line.item case final selection?) {
    final item = catalog.itemById(selection.itemId);
    if (item == null) return null;
    final chosen = options(item, selection);
    final price = ItemPricing.unitPrice(item, selection);
    return CartLineView(
      line: line,
      title: item.name,
      summary: chosen.isEmpty ? (item.servingLabel ?? '') : chosen,
      unitPrice: price,
      regularUnitPrice: price,
      issues: ItemPricing.validate(item, selection),
    );
  }
  final selection = line.combo!;
  final combo = catalog.comboById(selection.comboId);
  if (combo == null) return null;
  final pricing = ComboPricing(catalog);
  final parts = <String>[];
  for (final slot in combo.sortedSlots) {
    for (final pick in selection.picksFor(slot.id, slot.picks).nonNulls) {
      final item = catalog.itemById(pick.itemId);
      if (item == null) continue;
      final chosen = options(item, pick);
      parts.add(chosen.isEmpty ? item.name : '${item.name} ($chosen)');
    }
  }
  final price = pricing.total(combo, selection);
  final separate = pricing.separatePrice(combo, selection);
  return CartLineView(
    line: line,
    title: combo.name,
    summary: parts.join(', '),
    unitPrice: price,
    regularUnitPrice: separate > price ? separate : price,
    issues: pricing.validate(combo, selection),
  );
}

/// The applied promo code and what it does to this order.
class AppliedPromo {
  const AppliedPromo({required this.code, required this.check});

  final String code;

  /// Null while promo codes are still loading.
  final PromoCheck? check;

  int get discount => switch (check) {
    PromoAccepted(:final discount) => discount,
    _ => 0,
  };

  bool get isValid => check is PromoAccepted;
}

/// Everything the cart screen shows. All money is centavos.
class CartSummary {
  const CartSummary({
    required this.itemCount,
    required this.lines,
    this.subtotal = 0,
    this.comboSavings = 0,
    this.promo,
    this.comboSuggestion,
    this.upsell,
  });

  /// Total servings/combos, counting quantities.
  final int itemCount;
  final List<CartLineView> lines;

  /// Everything at regular prices.
  final int subtotal;

  /// What the combos in the cart save versus buying separately.
  final int comboSavings;
  final AppliedPromo? promo;

  /// A cheaper combo the cart's items could become.
  final ComboSuggestion? comboSuggestion;

  /// An item from a menu category the cart is missing (e.g. a drink).
  final ({Category category, MenuItem item})? upsell;

  /// After combo savings, before the promo code. Promo minimums use this.
  int get itemsTotal => subtotal - comboSavings;
  int get promoDiscount => promo?.discount ?? 0;
  int get total => itemsTotal - promoDiscount;

  bool get isEmpty => itemCount == 0;
  bool get hasIssues => lines.any((l) => l.issues.isNotEmpty);
}

final cartSummaryProvider = Provider<CartSummary>((ref) {
  final lines = ref.watch(cartProvider);
  final catalog = ref.watch(menuCatalogProvider).value;
  final itemCount = lines.fold(0, (sum, l) => sum + l.quantity);
  if (catalog == null) {
    return CartSummary(itemCount: itemCount, lines: const []);
  }
  final views = [for (final line in lines) ?resolveCartLine(line, catalog)];
  final subtotal = views.fold(0, (sum, v) => sum + v.regularTotal);
  final savings = views.fold(0, (sum, v) => sum + v.regularTotal - v.lineTotal);

  final code = ref.watch(appliedPromoProvider);
  AppliedPromo? promo;
  if (code != null) {
    final codes = ref.watch(promoCodesProvider).value;
    final now =
        ref.watch(manilaNowProvider).value ??
        ref.watch(clockProvider).nowInManila();
    promo = AppliedPromo(
      code: code,
      check: codes == null
          ? null
          : PromoRules.check(
              input: code,
              codes: codes,
              orderTotal: subtotal - savings,
              manilaNow: now,
            ),
    );
  }

  final suggestions = CartSuggestions(catalog);
  return CartSummary(
    itemCount: itemCount,
    lines: views,
    subtotal: subtotal,
    comboSavings: savings,
    promo: promo,
    comboSuggestion: suggestions.bestCombo(lines),
    upsell: suggestions.missingCategoryPick(lines),
  );
});

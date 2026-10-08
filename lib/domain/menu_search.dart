import '../data/models/combo.dart';
import '../data/models/menu_item.dart';

/// Menu search: case-insensitive "contains" matching.
abstract final class MenuSearch {
  static String normalise(String query) => query.trim().toLowerCase();

  /// An item matches on its name or any of its option names, so "mango"
  /// finds Fruit Soda.
  static bool matchesItem(MenuItem item, String query) {
    final q = normalise(query);
    if (q.isEmpty) return true;
    if (item.name.toLowerCase().contains(q)) return true;
    return item.optionGroups.any(
      (g) => g.choices.any((c) => c.name.toLowerCase().contains(q)),
    );
  }

  /// A combo matches on its name.
  static bool matchesCombo(Combo combo, String query) {
    final q = normalise(query);
    return q.isEmpty || combo.name.toLowerCase().contains(q);
  }
}

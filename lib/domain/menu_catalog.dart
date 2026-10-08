import '../data/models/category.dart';
import '../data/models/combo.dart';
import '../data/models/menu_item.dart';

/// A consistent snapshot of the whole menu, used for display and pricing.
class MenuCatalog {
  MenuCatalog({
    required List<Category> categories,
    required List<MenuItem> items,
    required List<Combo> combos,
  }) : categories = [...categories]
         ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
       items = [...items]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
       combos = [...combos]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
       _categoriesById = {for (final c in categories) c.id: c},
       _itemsById = {for (final item in items) item.id: item},
       _combosById = {for (final combo in combos) combo.id: combo};

  final List<Category> categories;
  final List<MenuItem> items;
  final List<Combo> combos;
  final Map<String, Category> _categoriesById;
  final Map<String, MenuItem> _itemsById;
  final Map<String, Combo> _combosById;

  List<Category> get visibleCategories =>
      categories.where((c) => c.isVisible).toList();

  Category? categoryById(String id) => _categoriesById[id];
  MenuItem? itemById(String id) => _itemsById[id];
  Combo? comboById(String id) => _combosById[id];

  List<MenuItem> itemsIn(String categoryId) =>
      items.where((i) => i.categoryId == categoryId).toList();

  List<Combo> combosIn(String categoryId) =>
      combos.where((c) => c.categoryId == categoryId).toList();

  bool isEmpty(String categoryId) =>
      itemsIn(categoryId).isEmpty && combosIn(categoryId).isEmpty;

  /// The photo to show for [item]: its own, else its category's default.
  /// Null means "use the illustration".
  String? imageForItem(MenuItem item) =>
      item.image ?? categoryById(item.categoryId)?.defaultImage;

  /// The photo to show for [combo]: its own, else the first photo among
  /// the items it can contain, in slot order (so takoyaki combos, including
  /// takoyaki + drink, use the takoyaki photo). Null = illustration.
  String? imageForCombo(Combo combo) {
    if (combo.image != null) return combo.image;
    final slots = [...combo.slots]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final slot in slots) {
      for (final item in items) {
        final eligible =
            slot.eligibleCategoryIds.contains(item.categoryId) ||
            slot.choices.any((c) => c.itemId == item.id);
        final image = eligible ? imageForItem(item) : null;
        if (image != null) return image;
      }
    }
    return null;
  }
}

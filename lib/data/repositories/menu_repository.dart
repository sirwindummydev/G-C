import '../models/category.dart';
import '../models/combo.dart';
import '../models/menu_item.dart';
import '../models/shop_settings.dart';

/// Source of the menu and shop settings.
///
/// The local sample-data repository (Phases 1–3) and the Firebase repository
/// (Phase 4+) both implement this, so the app switches between them in one
/// place: `menuRepositoryProvider` in `lib/data/repositories/providers.dart`.
///
/// Watch methods emit the current data first and then every change. On
/// failure they emit a [RepositoryException].
abstract interface class MenuRepository {
  Stream<List<Category>> watchCategories();
  Stream<List<MenuItem>> watchItems();
  Stream<List<Combo>> watchCombos();
  Stream<ShopSettings> watchShopSettings();

  Future<void> saveCategory(Category category);
  Future<void> deleteCategory(String categoryId);
  Future<void> saveItem(MenuItem item);
  Future<void> deleteItem(String itemId);
  Future<void> saveCombo(Combo combo);
  Future<void> deleteCombo(String comboId);
  Future<void> saveShopSettings(ShopSettings settings);
}

/// A data failure with a message that is safe to show to customers.
class RepositoryException implements Exception {
  const RepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'RepositoryException: $message${cause == null ? '' : ' ($cause)'}';
}

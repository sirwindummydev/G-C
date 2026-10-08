import '../data/models/selections.dart';

/// One line in the cart: an item or a combo with the customer's choices.
///
/// Prices are never stored here; they are worked out from the current menu
/// every time, so admin price changes and sold-out flags apply immediately.
class CartLine {
  const CartLine._({
    required this.id,
    required this.quantity,
    this.item,
    this.combo,
  });

  CartLine.item({
    required this.id,
    required ItemSelection this.item,
    this.quantity = 1,
  }) : combo = null;

  CartLine.combo({
    required this.id,
    required ComboSelection this.combo,
    this.quantity = 1,
  }) : item = null;

  final String id;
  final int quantity;
  final ItemSelection? item;
  final ComboSelection? combo;

  CartLine withQuantity(int quantity) =>
      CartLine._(id: id, quantity: quantity, item: item, combo: combo);
}

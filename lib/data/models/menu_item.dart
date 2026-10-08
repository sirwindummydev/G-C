import 'map_reader.dart';
import 'menu_visual.dart';
import 'option_group.dart';

/// Something a customer can order on its own, e.g. "Octopus Takoyaki" or
/// "Fruit Soda" (with Flavour and Size option groups).
class MenuItem {
  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.basePrice,
    this.description = '',
    this.servingLabel,
    this.isAvailable = true,
    this.sortOrder = 0,
    this.visual = const MenuVisual(),
    this.image,
    this.optionGroups = const [],
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;

  /// Price in centavos before options. Items priced purely by a required
  /// option (like drink sizes) use 0 here and put the price on the options.
  final int basePrice;

  /// Short portion text, e.g. "4 pcs".
  final String? servingLabel;

  /// False when the whole item is sold out.
  final bool isAvailable;
  final int sortOrder;
  final MenuVisual visual;

  /// Photo for this entry: an asset path (e.g.
  /// `assets/images/optimized/takoyaki.jpg`) or an `https://` URL. Null
  /// uses the category's default photo, or else the illustration.
  final String? image;
  final List<OptionGroup> optionGroups;

  List<OptionGroup> get sortedOptionGroups =>
      [...optionGroups]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  bool get hasOptions => optionGroups.isNotEmpty;

  /// Whether a customer can order it right now: the item is in stock and
  /// every required group still has enough available choices.
  bool get isOrderable =>
      isAvailable &&
      optionGroups.every(
        (g) => !g.isRequired || g.availableChoices.length >= g.minSelect,
      );

  OptionGroup? groupById(String id) {
    for (final group in optionGroups) {
      if (group.id == id) return group;
    }
    return null;
  }

  factory MenuItem.fromMap(String id, Map<String, dynamic> map) => MenuItem(
    id: id,
    categoryId: map.str('categoryId'),
    name: map.str('name'),
    description: map.str('description'),
    basePrice: map.integer('basePrice'),
    servingLabel: map.strOrNull('servingLabel'),
    isAvailable: map.boolean('isAvailable', true),
    sortOrder: map.integer('sortOrder'),
    visual: MenuVisual.fromMap(map.mapOrNull('visual')),
    image: map.strOrNull('image'),
    optionGroups: map.maps('optionGroups').map(OptionGroup.fromMap).toList(),
  );

  Map<String, dynamic> toMap() => {
    'categoryId': categoryId,
    'name': name,
    'description': description,
    'basePrice': basePrice,
    if (servingLabel != null) 'servingLabel': servingLabel,
    'isAvailable': isAvailable,
    'sortOrder': sortOrder,
    'visual': visual.toMap(),
    if (image != null) 'image': image,
    'optionGroups': optionGroups.map((g) => g.toMap()).toList(),
  };

  MenuItem copyWith({
    String? categoryId,
    String? name,
    String? description,
    int? basePrice,
    String? Function()? servingLabel,
    bool? isAvailable,
    int? sortOrder,
    MenuVisual? visual,
    String? Function()? image,
    List<OptionGroup>? optionGroups,
  }) => MenuItem(
    id: id,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    description: description ?? this.description,
    basePrice: basePrice ?? this.basePrice,
    servingLabel: servingLabel != null ? servingLabel() : this.servingLabel,
    isAvailable: isAvailable ?? this.isAvailable,
    sortOrder: sortOrder ?? this.sortOrder,
    visual: visual ?? this.visual,
    image: image != null ? image() : this.image,
    optionGroups: optionGroups ?? this.optionGroups,
  );
}

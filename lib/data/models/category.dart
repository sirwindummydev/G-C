import 'map_reader.dart';
import 'menu_visual.dart';

/// A menu section such as "Takoyaki", "Combos" or "Drinks".
class Category {
  const Category({
    required this.id,
    required this.name,
    this.description = '',
    this.sortOrder = 0,
    this.isVisible = true,
    this.visual = const MenuVisual(),
    this.defaultImage,
  });

  final String id;
  final String name;
  final String description;
  final int sortOrder;

  /// Hidden categories are kept in the data but not shown to customers.
  final bool isVisible;
  final MenuVisual visual;

  /// Photo used by this category's items (and combos made only of them)
  /// that have no photo of their own. Same format as `MenuItem.image`.
  final String? defaultImage;

  factory Category.fromMap(String id, Map<String, dynamic> map) => Category(
    id: id,
    name: map.str('name'),
    description: map.str('description'),
    sortOrder: map.integer('sortOrder'),
    isVisible: map.boolean('isVisible', true),
    visual: MenuVisual.fromMap(map.mapOrNull('visual')),
    defaultImage: map.strOrNull('defaultImage'),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'sortOrder': sortOrder,
    'isVisible': isVisible,
    'visual': visual.toMap(),
    if (defaultImage != null) 'defaultImage': defaultImage,
  };

  Category copyWith({
    String? name,
    String? description,
    int? sortOrder,
    bool? isVisible,
    MenuVisual? visual,
    String? Function()? defaultImage,
  }) => Category(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    sortOrder: sortOrder ?? this.sortOrder,
    isVisible: isVisible ?? this.isVisible,
    visual: visual ?? this.visual,
    defaultImage: defaultImage != null ? defaultImage() : this.defaultImage,
  );
}

import 'map_reader.dart';

/// The drawn illustration for a category, item or combo: which drawing
/// ([iconKey]) and its accent colour ([colorHex]). Used when there is no
/// photo, and as the fallback if a photo fails to load.
class MenuVisual {
  const MenuVisual({this.iconKey = 'food', this.colorHex = '#E4572E'});

  final String iconKey;
  final String colorHex;

  factory MenuVisual.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const MenuVisual();
    return MenuVisual(
      iconKey: map.str('iconKey', 'food'),
      colorHex: map.str('colorHex', '#E4572E'),
    );
  }

  Map<String, dynamic> toMap() => {'iconKey': iconKey, 'colorHex': colorHex};

  MenuVisual copyWith({String? iconKey, String? colorHex}) => MenuVisual(
    iconKey: iconKey ?? this.iconKey,
    colorHex: colorHex ?? this.colorHex,
  );
}

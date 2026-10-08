import 'package:flutter/material.dart';

import '../../data/models/menu_item.dart';
import '../../data/models/option_group.dart';
import '../../data/models/selections.dart';

/// Swatch colours for option choices such as soda flavours.
///
/// Presentation only: colours are matched from the choice name, so a flavour
/// the admin adds later ("Lychee", "Calamansi"...) still gets a stable colour
/// from the fallback palette without any code change.
abstract final class FlavourPalette {
  // Longer names first so "watermelon" wins over "melon", etc.
  static const _byKeyword = <(String, Color)>[
    ('watermelon', Color(0xFFF25C78)),
    ('green apple', Color(0xFF9BCB3B)),
    ('tiger', Color(0xFFD7263D)),
    ('blueberry', Color(0xFF4A4FB5)),
    ('strawberry', Color(0xFFE8476A)),
    ('pineapple', Color(0xFFF2B415)),
    ('lemon', Color(0xFFF7DA45)),
    ('mango', Color(0xFFFFA930)),
    ('melon', Color(0xFFA8D97F)),
    ('grape', Color(0xFF7B3FA0)),
    ('kiwi', Color(0xFF6FA83A)),
    ('orange', Color(0xFFFF8C2B)),
    ('lychee', Color(0xFFF3C6CF)),
    ('calamansi', Color(0xFFC6D93A)),
    ('apple', Color(0xFFD94A3D)),
    ('cherry', Color(0xFFB0203A)),
    ('lime', Color(0xFF7CC242)),
    ('peach', Color(0xFFFFB38A)),
    ('cola', Color(0xFF5B3A29)),
  ];

  static const _fallback = [
    Color(0xFF43A2FE),
    Color(0xFFFE9F43),
    Color(0xFF8E6CC9),
    Color(0xFF3FB59E),
    Color(0xFFE96A9A),
    Color(0xFFC9A227),
  ];

  static Color forChoice(OptionChoice choice) =>
      forName(choice.name, seed: choice.id);

  static Color forName(String name, {String? seed}) {
    final lower = name.toLowerCase();
    for (final (keyword, color) in _byKeyword) {
      if (lower.contains(keyword)) return color;
    }
    final key = seed ?? name;
    final hash = key.codeUnits.fold(0, (h, c) => (h * 31 + c) & 0x7fffffff);
    return _fallback[hash % _fallback.length];
  }

  /// Colour of the first chosen swatch-style option (e.g. the soda
  /// flavour), used to tint drink pictures. Null when none is chosen.
  static Color? chosenColour(MenuItem item, ItemSelection selection) {
    for (final group in item.sortedOptionGroups) {
      if (group.choices.any((c) => c.hasMeasure)) continue;
      for (final id in selection.choicesFor(group.id)) {
        final choice = group.choiceById(id);
        if (choice != null) return forChoice(choice);
      }
    }
    return null;
  }
}

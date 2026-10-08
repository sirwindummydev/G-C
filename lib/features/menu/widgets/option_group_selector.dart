import 'package:flutter/material.dart';

import '../../../core/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/capsule_chip.dart';
import '../../../data/models/option_group.dart';
import '../flavour_palette.dart';

/// Lets the customer pick from one [OptionGroup] using capsule chips.
///
/// - Single-choice groups behave like radio buttons; the header tag shows
///   "Required" until something is chosen, then "✓ Lemon".
/// - Multi-choice groups show "2 of 4 selected" and fade the other chips
///   once the maximum is reached.
/// - Choices with a measure (sizes) read "16oz · ₱50" with no colour dot,
///   and a "Price per oz" line underneath.
class OptionGroupSelector extends StatelessWidget {
  const OptionGroupSelector({
    super.key,
    required this.group,
    required this.choices,
    required this.selectedIds,
    required this.onTap,
    required this.priceLabel,
    this.unitPrice,
  });

  final OptionGroup group;

  /// The choices to show (an item's own, or those a combo allows).
  final List<OptionChoice> choices;
  final List<String> selectedIds;
  final ValueChanged<OptionChoice> onTap;

  /// Price text after the name, e.g. "₱50" or "+₱5", or null for none.
  final String? Function(OptionChoice choice) priceLabel;

  /// Full price used for the "Price per oz" line; null hides it.
  final int Function(OptionChoice choice)? unitPrice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMeasured = choices.any((c) => c.hasMeasure);
    final selected = choices.where((c) => selectedIds.contains(c.id)).toList();
    final full = !group.isSingleChoice && selected.length >= group.maxSelect;
    final groupNoun = group.name.toLowerCase();

    final HeaderTag tag;
    if (!group.isSingleChoice) {
      final enough = selected.length >= group.minSelect && selected.isNotEmpty;
      tag = HeaderTag(
        text: '${selected.length} of ${group.maxSelect} selected',
        tone: enough
            ? TagTone.done
            : (group.isRequired ? TagTone.required : TagTone.neutral),
      );
    } else if (selected.isNotEmpty) {
      tag = HeaderTag(text: selected.first.name, tone: TagTone.done);
    } else {
      tag = HeaderTag(
        text: group.isRequired ? 'Required' : 'Optional',
        tone: group.isRequired ? TagTone.required : TagTone.neutral,
      );
    }

    final perUnit = <String>[
      if (isMeasured && unitPrice != null)
        for (final c in choices.where((c) => c.hasMeasure && c.isAvailable))
          '${c.name} ${Money.format(Money.perUnit(unitPrice!(c), c.measure!))}',
    ];
    final unit = choices
        .firstWhere((c) => c.hasMeasure, orElse: () => choices.first)
        .measureUnit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  group.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: Gap.s),
            tag,
          ],
        ),
        const SizedBox(height: Gap.s),
        Wrap(
          spacing: Gap.s,
          children: [
            for (final choice in choices)
              _chip(
                choice,
                isMeasured: isMeasured,
                full: full,
                groupNoun: groupNoun,
              ),
          ],
        ),
        if (perUnit.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Gap.xs),
            child: Text(
              'Price per $unit: ${perUnit.join(' · ')}',
              style: AppText.description(size: 12),
            ),
          ),
      ],
    );
  }

  Widget _chip(
    OptionChoice choice, {
    required bool isMeasured,
    required bool full,
    required String groupNoun,
  }) {
    final isSelected = selectedIds.contains(choice.id);
    final soldOut = !choice.isAvailable;
    final price = priceLabel(choice);
    final blocked = !isSelected && full;
    return CapsuleChip(
      key: ValueKey('choice-${group.id}-${choice.id}'),
      label: choice.name,
      detail: price,
      badge: choice.badge,
      dotColor: isMeasured ? null : FlavourPalette.forChoice(choice),
      selected: isSelected,
      soldOut: soldOut,
      radioStyle: group.isSingleChoice,
      onTap: soldOut || blocked ? null : () => onTap(choice),
      semanticLabel: soldOut
          ? '${choice.name}, sold out'
          : [
              choice.name,
              groupNoun,
              ?price,
              ?choice.badge,
              if (isSelected) 'selected',
            ].join(', '),
    );
  }
}

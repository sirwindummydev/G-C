import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/clock.dart';
import '../../core/money.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/components.dart';
import '../../data/models/promo_code.dart';
import '../../data/repositories/menu_repository.dart';
import '../../data/repositories/providers.dart';
import '../../domain/promo_rules.dart';
import '../cart/cart_providers.dart';

/// Admin list of promo codes: create, edit, switch on/off.
class PromoCodesSection extends ConsumerWidget {
  const PromoCodesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codes = ref.watch(promoCodesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Promo codes',
          padding: const EdgeInsets.only(bottom: Gap.m),
          trailing: TextButton.icon(
            key: const ValueKey('promo-new'),
            onPressed: () => showPromoEditor(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New code'),
          ),
        ),
        AsyncValueView<List<PromoCode>>(
          value: codes,
          onRetry: () => ref.invalidate(promoCodesProvider),
          data: (codes) {
            if (codes.isEmpty) {
              return Text(
                'No promo codes yet.',
                style: AppText.description(size: 14),
              );
            }
            final sorted = [...codes]..sort((a, b) => a.code.compareTo(b.code));
            return AppCard(
              child: Column(
                children: [
                  for (final (i, promo) in sorted.indexed) ...[
                    if (i > 0) const Divider(indent: Gap.l, endIndent: Gap.l),
                    _PromoRow(promo: promo),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PromoRow extends ConsumerStatefulWidget {
  const _PromoRow({required this.promo});

  final PromoCode promo;

  @override
  ConsumerState<_PromoRow> createState() => _PromoRowState();
}

class _PromoRowState extends ConsumerState<_PromoRow> {
  bool _saving = false;

  Future<void> _toggle(bool active) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(promoRepositoryProvider)
          .savePromoCode(widget.promo.copyWith(isActive: active));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error is RepositoryException ? error.message : friendlyError(error),
          ),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _toggle(active),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final promo = widget.promo;
    final now = ref.watch(clockProvider).nowInManila();
    final expired = promo.expiresAt != null && !now.isBefore(promo.expiresAt!);
    final status = !promo.isActive
        ? 'Off'
        : expired
        ? 'Expired'
        : 'Active';

    return ListTile(
      key: ValueKey('promo-row-${promo.code}'),
      contentPadding: const EdgeInsets.fromLTRB(Gap.l, Gap.xs, Gap.s, Gap.xs),
      onTap: () => showPromoEditor(context, existing: promo),
      title: Row(
        children: [
          Flexible(child: Text(promo.code)),
          const SizedBox(width: Gap.s),
          Pill(
            text: status,
            tone: status == 'Active' ? PillTone.brand : PillTone.muted,
          ),
        ],
      ),
      subtitle: Text(
        [
          PromoRules.describe(promo),
          if (promo.expiresAt != null)
            'until ${DateFormat('d MMM yyyy').format(promo.expiresAt!.subtract(const Duration(seconds: 1)))}',
        ].join(' · '),
      ),
      trailing: _saving
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Switch(value: promo.isActive, onChanged: _toggle),
    );
  }
}

/// Opens the create/edit form for a promo code.
Future<void> showPromoEditor(BuildContext context, {PromoCode? existing}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PromoEditor(existing: existing),
    );

/// Form to create or edit a promo code, with validation.
class PromoEditor extends ConsumerStatefulWidget {
  const PromoEditor({super.key, this.existing});

  final PromoCode? existing;

  @override
  ConsumerState<PromoEditor> createState() => _PromoEditorState();
}

class _PromoEditorState extends ConsumerState<PromoEditor> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.existing?.code);
  late final _description = TextEditingController(
    text: widget.existing?.description,
  );
  late final _value = TextEditingController(
    text: switch (widget.existing) {
      null => '',
      PromoCode(type: PromoType.percent, :final value) => '$value',
      PromoCode(:final value) => _pesos(value),
    },
  );
  late final _minimum = TextEditingController(
    text: widget.existing?.minOrder == null
        ? ''
        : _pesos(widget.existing!.minOrder!),
  );
  late PromoType _type = widget.existing?.type ?? PromoType.percent;
  late bool _active = widget.existing?.isActive ?? true;

  /// Last day the code works (inclusive), or null for no expiry.
  late DateTime? _lastDay = widget.existing?.expiresAt?.subtract(
    const Duration(seconds: 1),
  );
  bool _saving = false;
  String? _error;

  static String _pesos(int centavos) =>
      Money.format(centavos).replaceAll('₱', '').replaceAll(',', '');

  @override
  void dispose() {
    for (final c in [_code, _description, _value, _minimum]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validateCode(String? input) {
    final code = PromoCode.normalise(input ?? '');
    if (!RegExp(r'^[A-Z0-9]{3,20}$').hasMatch(code)) {
      return 'Use 3–20 letters or numbers, no spaces.';
    }
    if (widget.existing == null) {
      final taken = (ref.read(promoCodesProvider).value ?? const []).any(
        (p) => p.code == code,
      );
      if (taken) return 'That code already exists.';
    }
    return null;
  }

  String? _validateValue(String? input) {
    final text = (input ?? '').trim();
    if (_type == PromoType.percent) {
      final n = int.tryParse(text);
      if (n == null || n < 1 || n > 100) return 'Enter a whole number, 1–100.';
      return null;
    }
    final centavos = Money.tryParsePesos(text);
    if (centavos == null || centavos <= 0) {
      return 'Enter an amount in pesos, e.g. 20 or 12.50.';
    }
    return null;
  }

  String? _validateMinimum(String? input) {
    final text = (input ?? '').trim();
    if (text.isEmpty) return null;
    return Money.tryParsePesos(text) == null
        ? 'Enter an amount in pesos, or leave empty.'
        : null;
  }

  Future<void> _pickDate() async {
    final today = ref.read(clockProvider).nowInManila();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastDay ?? today,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 5),
      helpText: 'Last day the code works',
    );
    if (picked != null) {
      setState(
        () => _lastDay = DateTime.utc(picked.year, picked.month, picked.day),
      );
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final valueText = _value.text.trim();
    final minText = _minimum.text.trim();
    final promo = PromoCode(
      code: PromoCode.normalise(_code.text),
      type: _type,
      value: _type == PromoType.percent
          ? int.parse(valueText)
          : Money.tryParsePesos(valueText)!,
      description: _description.text.trim(),
      minOrder: minText.isEmpty ? null : Money.tryParsePesos(minText),
      // Works through the whole last day (Manila time).
      expiresAt: _lastDay == null
          ? null
          : DateTime.utc(
              _lastDay!.year,
              _lastDay!.month,
              _lastDay!.day,
            ).add(const Duration(days: 1)),
      isActive: _active,
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(promoRepositoryProvider).savePromoCode(promo);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text('Saved ${promo.code}.')));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is RepositoryException
            ? error.message
            : friendlyError(error);
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Gap.screen,
            0,
            Gap.screen,
            Gap.screen,
          ),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  editing ? 'Edit ${widget.existing!.code}' : 'New promo code',
                  style: AppText.sectionTitle(),
                ),
                const SizedBox(height: Gap.l),
                _Field(
                  label: 'Code',
                  child: TextFormField(
                    key: const ValueKey('promo-code-field'),
                    controller: _code,
                    enabled: !editing,
                    textCapitalization: TextCapitalization.characters,
                    validator: _validateCode,
                    decoration: _decoration('e.g. WELCOME10'),
                  ),
                ),
                _Field(
                  label: 'Label (optional)',
                  child: TextFormField(
                    controller: _description,
                    maxLength: 40,
                    decoration: _decoration('e.g. Welcome treat'),
                  ),
                ),
                _Field(
                  label: 'Discount',
                  child: SegmentedButton<PromoType>(
                    segments: const [
                      ButtonSegment(
                        value: PromoType.percent,
                        label: Text('Percent %'),
                      ),
                      ButtonSegment(
                        value: PromoType.fixed,
                        label: Text('Fixed ₱'),
                      ),
                    ],
                    selected: {_type},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() {
                      _type = s.first;
                      _value.clear();
                    }),
                  ),
                ),
                _Field(
                  label: _type == PromoType.percent
                      ? 'Percent off'
                      : 'Amount off (₱)',
                  child: TextFormField(
                    key: const ValueKey('promo-value-field'),
                    controller: _value,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateValue,
                    decoration: _decoration(
                      _type == PromoType.percent ? 'e.g. 10' : 'e.g. 20',
                    ),
                  ),
                ),
                _Field(
                  label: 'Minimum order (₱, optional)',
                  child: TextFormField(
                    controller: _minimum,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateMinimum,
                    decoration: _decoration('No minimum'),
                  ),
                ),
                _Field(
                  label: 'Expiry (optional)',
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.event_outlined),
                          label: Text(
                            _lastDay == null
                                ? 'No expiry'
                                : 'Until ${DateFormat('d MMM yyyy').format(_lastDay!)}',
                          ),
                        ),
                      ),
                      if (_lastDay != null)
                        IconButton(
                          tooltip: 'Remove expiry',
                          onPressed: () => setState(() => _lastDay = null),
                          icon: const Icon(Icons.close_rounded),
                        ),
                    ],
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: const Text('Customers can use this code'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.s),
                    child: Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.error),
                    ),
                  ),
                const SizedBox(height: Gap.s),
                PillButton(
                  key: const ValueKey('promo-save'),
                  label: _saving ? 'Saving…' : 'Save code',
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.chip,
    counterText: '',
    contentPadding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.button),
      borderSide: BorderSide.none,
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: Gap.s),
          child,
        ],
      ),
    );
  }
}

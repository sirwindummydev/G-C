import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/menu_image.dart';
import '../../data/models/combo.dart';
import '../../data/models/menu_item.dart';
import '../../data/models/menu_visual.dart';
import '../../data/repositories/menu_repository.dart';
import '../../data/repositories/providers.dart';
import '../../domain/menu_catalog.dart';

/// Folder of bundled menu photos admins can pick from (made by
/// tool/images/optimize_photos.py). Uploaded photos arrive with Firebase.
const menuPhotoFolder = 'assets/images/optimized/';

/// Every bundled menu photo, from the app's asset manifest.
final menuPhotoAssetsProvider = FutureProvider<List<String>>((ref) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  return manifest
      .listAssets()
      .where((path) => path.startsWith(menuPhotoFolder))
      .toList()
    ..sort();
});

/// Admin list for setting each item's and combo's photo.
class MenuPhotosSection extends StatelessWidget {
  const MenuPhotosSection({super.key, required this.catalog});

  final MenuCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final entries = <_Entry>[
      for (final item in catalog.items) _Entry.item(item, catalog),
      for (final combo in catalog.combos) _Entry.combo(combo, catalog),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Menu photos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: Gap.xs),
        Text(
          'Tap an item to change its photo.',
          style: AppText.description(size: 14),
        ),
        const SizedBox(height: Gap.m),
        AppCard(
          child: Column(
            children: [
              for (final (i, entry) in entries.indexed) ...[
                if (i > 0) const Divider(indent: 76),
                _PhotoRow(key: ValueKey('photo-row-${entry.id}'), entry: entry),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// An item or combo, with what its photo currently resolves to.
class _Entry {
  _Entry.item(MenuItem this.item, MenuCatalog catalog)
    : combo = null,
      ownImage = item.image,
      shownImage = catalog.imageForItem(item),
      defaultImage = catalog.categoryById(item.categoryId)?.defaultImage;

  _Entry.combo(Combo this.combo, MenuCatalog catalog)
    : item = null,
      ownImage = combo.image,
      shownImage = catalog.imageForCombo(combo),
      defaultImage = catalog.imageForCombo(combo.copyWith(image: () => null));

  final MenuItem? item;
  final Combo? combo;
  final String? ownImage;
  final String? shownImage;

  /// What it shows with no photo of its own (null = illustration).
  final String? defaultImage;

  String get id => item?.id ?? combo!.id;
  String get name => item?.name ?? combo!.name;
  MenuVisual get visual => item?.visual ?? combo!.visual;

  String get description {
    if (ownImage != null) return 'Own photo · ${fileName(ownImage!)}';
    if (defaultImage != null) {
      return 'Default photo · ${fileName(defaultImage!)}';
    }
    return 'Illustration';
  }

  static String fileName(String source) => source.split('/').last;
}

class _PhotoRow extends ConsumerStatefulWidget {
  const _PhotoRow({super.key, required this.entry});

  final _Entry entry;

  @override
  ConsumerState<_PhotoRow> createState() => _PhotoRowState();
}

class _PhotoRowState extends ConsumerState<_PhotoRow> {
  bool _saving = false;

  Future<void> _pick() async {
    final choice = await showModalBottomSheet<_PhotoChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PhotoPicker(entry: widget.entry),
    );
    if (choice == null || !mounted) return;
    await _save(choice.image);
  }

  Future<void> _save(String? image) async {
    final entry = widget.entry;
    final repository = ref.read(menuRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      if (entry.item != null) {
        await repository.saveItem(entry.item!.copyWith(image: () => image));
      } else {
        await repository.saveCombo(entry.combo!.copyWith(image: () => image));
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Photo updated for ${entry.name}.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error is RepositoryException ? error.message : friendlyError(error),
          ),
          action: SnackBarAction(label: 'Retry', onPressed: () => _save(image)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Gap.m,
        vertical: Gap.xs,
      ),
      leading: MenuImage(
        visual: entry.visual,
        image: entry.shownImage,
        size: 48,
        borderRadius: AppRadii.image,
      ),
      title: Text(entry.name),
      subtitle: Text(entry.description),
      trailing: _saving
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : const Icon(Icons.edit_outlined, color: AppColors.textMuted),
      onTap: _saving ? null : _pick,
    );
  }
}

/// The admin's pick: a photo path, or null for "use the default".
class _PhotoChoice {
  const _PhotoChoice(this.image);

  final String? image;
}

class _PhotoPicker extends ConsumerWidget {
  const _PhotoPicker({required this.entry});

  final _Entry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(menuPhotoAssetsProvider);
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.screen, 0, Gap.screen, Gap.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Photo for ${entry.name}',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: Gap.xs),
              Text(
                'Pick from the app photos. Uploading your own arrives with '
                'Firebase.',
                style: AppText.description(size: 14),
              ),
              const SizedBox(height: Gap.m),
              Flexible(
                child: AsyncValueView<List<String>>(
                  value: photos,
                  onRetry: () => ref.invalidate(menuPhotoAssetsProvider),
                  data: (paths) => ListView(
                    shrinkWrap: true,
                    children: [
                      _PickerTile(
                        title: 'Use default',
                        subtitle: entry.defaultImage == null
                            ? 'Illustration'
                            : 'Category photo · ${_Entry.fileName(entry.defaultImage!)}',
                        selected: entry.ownImage == null,
                        thumbnail: MenuImage(
                          visual: entry.visual,
                          image: entry.defaultImage,
                          size: 56,
                          borderRadius: AppRadii.image,
                        ),
                        onTap: () =>
                            Navigator.of(context).pop(const _PhotoChoice(null)),
                      ),
                      for (final path in paths)
                        _PickerTile(
                          title: _Entry.fileName(path),
                          subtitle: 'App photo',
                          selected: entry.ownImage == path,
                          thumbnail: MenuImage(
                            visual: entry.visual,
                            image: path,
                            size: 56,
                            borderRadius: AppRadii.image,
                          ),
                          onTap: () =>
                              Navigator.of(context).pop(_PhotoChoice(path)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.thumbnail,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final Widget thumbnail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: thumbnail,
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: selected
            ? const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryDark,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}

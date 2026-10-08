import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/menu_visual.dart';
import '../theme/app_theme.dart';
import 'illustrations.dart';

/// Pictures a menu entry.
///
/// With an [image] it shows that photo; without one, the drawn
/// illustration from [visual]. Photos:
/// - can be an asset path or an `http(s)://` URL (uploaded photos from
///   Firebase Storage will arrive as URLs, so screens never change);
/// - fill the area with [BoxFit.cover], centred, never stretched;
/// - are decoded at display size (not full size) to save memory;
/// - fade in over a cream placeholder, and fall back to the illustration
///   if they fail to load.
class MenuImage extends StatelessWidget {
  const MenuImage({
    super.key,
    required this.visual,
    this.image,
    this.size,
    this.borderRadius = 16,
    this.dimmed = false,
    this.drinkColor,
    this.heroTag,
  });

  final MenuVisual visual;

  /// Photo source (asset path or URL). Null shows the illustration.
  final String? image;

  /// Square size. Null fills the parent.
  final double? size;
  final double borderRadius;

  /// Greys the picture out, e.g. for sold-out items.
  final bool dimmed;

  /// Overrides the drink liquid colour in the illustration.
  final Color? drinkColor;

  /// Wraps the picture in a [Hero] so it flies to the detail screen.
  final Object? heroTag;

  static const fadeDuration = Duration(milliseconds: 200);

  static Color parseColor(String hex, {Color fallback = AppColors.primary}) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(
      cleaned.length == 6 ? 'FF$cleaned' : cleaned,
      radix: 16,
    );
    return value == null ? fallback : Color(value);
  }

  /// The image provider for a photo source string.
  static ImageProvider providerFor(String source) {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return NetworkImage(source);
    }
    return AssetImage(source);
  }

  @override
  Widget build(BuildContext context) {
    final illustration = FoodIllustration(
      kind: IllustrationKind.fromKey(visual.iconKey),
      accent: parseColor(visual.colorHex),
      drinkColor: drinkColor,
    );

    Widget child = image == null
        ? illustration
        : _Photo(source: image!, fallback: illustration);
    if (dimmed) {
      child = Opacity(
        opacity: 0.55,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.33, 0.33, 0.33, 0, 0, //
            0.33, 0.33, 0.33, 0, 0, //
            0.33, 0.33, 0.33, 0, 0, //
            0, 0, 0, 1, 0,
          ]),
          child: child,
        ),
      );
    }
    Widget result = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
    );
    if (heroTag != null) {
      result = Hero(tag: heroTag!, child: result);
    }
    return ExcludeSemantics(
      child: size == null
          ? SizedBox.expand(child: result)
          : SizedBox.square(dimension: size, child: result),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.source, required this.fallback});

  final String source;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        // With BoxFit.cover the photo must be at least as big as the box in
        // both directions; decoding the longer side at display size covers
        // any aspect ratio without decoding the full-size file.
        final longest = math.max(
          constraints.hasBoundedWidth ? constraints.maxWidth : 0.0,
          constraints.hasBoundedHeight ? constraints.maxHeight : 0.0,
        );
        final cacheWidth = longest > 0 ? (longest * dpr).ceil() : null;
        final provider = ResizeImage.resizeIfNeeded(
          cacheWidth,
          null,
          MenuImage.providerFor(source),
        );
        return ColoredBox(
          color: AppColors.illustrationBg,
          child: Image(
            image: provider,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: MenuImage.fadeDuration,
                curve: Curves.easeOut,
                child: child,
              );
            },
            errorBuilder: (_, _, _) => fallback,
          ),
        );
      },
    );
  }
}

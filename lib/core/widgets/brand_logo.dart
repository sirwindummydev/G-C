import 'package:flutter/material.dart';

/// The G&C ("grab & chill") logo, exactly as provided: never recoloured,
/// cropped or stretched. Only [height] is set; width follows the original
/// aspect ratio.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.height = 40,
    this.opacity = 1,
    this.semanticLabel = 'G&C',
  });

  static const asset = 'assets/images/logo_icon.png';

  /// The file's own proportions (500 × 499 px). Used to reserve the right
  /// width before the image has loaded, so layout doesn't jump and the
  /// long-press target exists straight away.
  static const aspectRatio = 500 / 499;

  final double height;

  /// Below 1 for subtle placements such as empty states.
  final double opacity;

  /// Null hides the logo from screen readers (when it is decorative).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      height: height,
      width: height * aspectRatio,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
    return opacity >= 1 ? image : Opacity(opacity: opacity, child: image);
  }
}

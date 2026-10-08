import 'package:flutter/material.dart';

/// On wide screens (e.g. Chrome on a laptop), shows the app in a centred
/// phone-sized frame. On phones it does nothing.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  static const double phoneWidth = 412;
  static const double maxPhoneHeight = 915;
  static const double _wideBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width < _wideBreakpoint) return child;

    final scheme = Theme.of(context).colorScheme;
    final height = (media.size.height - 32).clamp(480.0, maxPhoneHeight);
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Container(
          width: phoneWidth,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                blurRadius: 32,
                color: Color(0x33000000),
                offset: Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: MediaQuery(
            data: media.copyWith(
              size: Size(phoneWidth, height),
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
              viewInsets: EdgeInsets.zero,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

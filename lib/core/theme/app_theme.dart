import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The G&C palette. Every colour in the app comes from here; nothing is
/// generated automatically. Orange is an accent only (selected states,
/// prices, small buttons); on any orange fill, text and icons are [text].
abstract final class AppColors {
  static const primary = Color(0xFFFE9F43);
  static const primaryDark = Color(0xFFC2650A);

  /// Orange for text on white: prices and the greeting (readable contrast).
  static const priceOrange = Color(0xFFE07B22);
  static const accent = Color(0xFF43A2FE); // use sparingly
  static const accentDark = Color(0xFF0B5CAD);

  /// Main screens are white; peach is only for the home header.
  static const background = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);
  static const peachTop = Color(0xFFFFF1E3);
  static const peachBottom = Color(0xFFFFF8F1);
  static const text = Color(0xFF2B2118);
  static const textMuted = Color(0xFF8A7F76);

  /// Light grey fill for unselected chips and nav icon circles.
  static const chip = Color(0xFFF3F0ED);

  /// Supporting neutrals derived by hand from the palette above.
  /// Dividers and hairlines.
  static const border = Color(0xFFEEE7E1);
  static const borderStrong = Color(0xFFDCD2C8);
  static const illustrationBg = Color(0xFFFFF1E3);
  static const primarySoft = Color(0xFFFFF1E3);
  static const notice = Color(0xFFFFEFCF); // amber-cream info notice
  static const disabled = Color(0xFFEFEAE5);
  static const open = Color(0xFF2E9E5B); // "Open now" dot
  static const error = Color(0xFFB3261E); // real errors only

  /// Drink picture colour before a flavour is chosen.
  static const neutralDrink = Color(0xFFE6DDD3);

  /// The one card shadow: black at 6%, blur 20, offset y 6.
  static const cardShadow = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 6)),
  ];

  /// Soft orange glow under the main call-to-action button.
  static const orangeShadow = [
    BoxShadow(color: Color(0x40FE9F43), blurRadius: 20, offset: Offset(0, 8)),
  ];
}

/// Corner radii.
abstract final class AppRadii {
  static const double card = 20;
  static const double image = 14;
  static const double button = 16;
  static const double header = 28;
  static const double pill = 999;
}

/// Poppins, the app's main font. Poppins has no peso sign (₱), so Nunito of
/// the same weight is set as the fallback for that glyph.
TextStyle poppins({
  TextStyle? textStyle,
  double? fontSize,
  FontWeight fontWeight = FontWeight.w400,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  final fallback = GoogleFonts.nunito(fontWeight: fontWeight).fontFamily!;
  return GoogleFonts.poppins(
    textStyle: textStyle,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  ).copyWith(fontFamilyFallback: [fallback]);
}

/// DM Serif Display, for the greeting, titles and promo headlines.
TextStyle serif({
  double fontSize = 22,
  Color color = AppColors.text,
  bool italic = false,
}) {
  final fallback = GoogleFonts.nunito().fontFamily!;
  return GoogleFonts.dmSerifDisplay(
    fontSize: fontSize,
    color: color,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    height: 1.2,
  ).copyWith(fontFamilyFallback: [fallback]);
}

/// Text styles beyond the theme's text roles.
abstract final class AppText {
  /// Prices: 15 semibold, orange.
  static TextStyle price({double size = 15}) => poppins(
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: AppColors.priceOrange,
    height: 1.3,
  );

  /// Item names: 15 semibold.
  static TextStyle itemName({double size = 15}) => poppins(
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    height: 1.35,
  );

  /// Descriptions: regular, muted.
  static TextStyle description({double size = 13}) =>
      poppins(fontSize: size, color: AppColors.textMuted, height: 1.45);

  /// Section titles such as "Combo deals" and "Popular".
  static TextStyle sectionTitle() => serif(fontSize: 22);

  /// Upsell headlines in the cart, e.g. "Add a Fruit Soda?".
  static TextStyle promoHeadline() =>
      serif(fontSize: 24, color: AppColors.priceOrange, italic: true);

  /// The home greeting ("Good Morning").
  static TextStyle greeting() =>
      serif(fontSize: 28, color: AppColors.priceOrange);
}

/// Spacing.
abstract final class Gap {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Screen edge padding.
  static const double screen = 20;

  /// Space between sections.
  static const double section = 24;
}

/// The single source of the app's look.
abstract final class AppTheme {
  static const double radius = AppRadii.card;

  static const ColorScheme _scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.text,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.text,
    primaryFixedDim: AppColors.primaryDark,
    secondary: AppColors.accent,
    onSecondary: AppColors.text,
    secondaryContainer: Color(0xFFDDEEFF),
    onSecondaryContainer: AppColors.accentDark,
    tertiary: AppColors.primaryDark,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.notice,
    onTertiaryContainer: AppColors.text,
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: Color(0xFFFCE4E2),
    onErrorContainer: AppColors.error,
    surface: AppColors.background,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textMuted,
    surfaceDim: Color(0xFFF5F1ED),
    surfaceBright: AppColors.card,
    surfaceContainerLowest: AppColors.card,
    surfaceContainerLow: AppColors.card,
    surfaceContainer: AppColors.card,
    surfaceContainerHigh: AppColors.chip,
    surfaceContainerHighest: AppColors.chip,
    outline: AppColors.borderStrong,
    outlineVariant: AppColors.border,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.text,
    onInverseSurface: AppColors.background,
    inversePrimary: AppColors.primary,
    surfaceTint: Colors.transparent,
  );

  static ThemeData light() {
    // Built role by role (google_fonts' TextTheme helpers target a newer
    // Material package than this Flutter version).
    final text = TextTheme(
      displayLarge: serif(fontSize: 48),
      displayMedium: serif(fontSize: 40),
      displaySmall: serif(fontSize: 34),
      headlineLarge: serif(fontSize: 30),
      headlineMedium: serif(fontSize: 28),
      headlineSmall: serif(fontSize: 26),
      titleLarge: serif(fontSize: 22),
      titleMedium: poppins(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: poppins(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: poppins(fontSize: 15, height: 1.5),
      bodyMedium: poppins(fontSize: 14, height: 1.45),
      bodySmall: poppins(
        fontSize: 12.5,
        color: AppColors.textMuted,
        height: 1.4,
      ),
      labelLarge: poppins(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: poppins(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: poppins(fontSize: 11, fontWeight: FontWeight.w500),
    ).apply(bodyColor: AppColors.text, displayColor: AppColors.text);

    // Chips and buttons are fully rounded.
    const rounded = StadiumBorder();
    final buttonText = poppins(fontSize: 15, fontWeight: FontWeight.w600);

    return ThemeData(
      useMaterial3: true,
      colorScheme: _scheme,
      textTheme: text,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.card,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.header),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chip,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.disabled,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: text.labelLarge?.copyWith(color: AppColors.text),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.text,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size.fromHeight(52),
          shape: rounded,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.borderStrong),
          minimumSize: const Size(48, 48),
          shape: rounded,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          textStyle: buttonText.copyWith(fontSize: 14),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: poppins(fontSize: 14, color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: BorderSide.none,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: AppColors.primary,
          selectedForegroundColor: AppColors.text,
          backgroundColor: AppColors.chip,
          side: BorderSide.none,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.text
              : AppColors.borderStrong,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.chip,
        ),
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.primary,
        textColor: AppColors.text,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryDark,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        contentTextStyle: poppins(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: AppColors.primary,
        shape: rounded,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: AppText.itemName(),
        subtitleTextStyle: AppText.description(),
      ),
    );
  }
}

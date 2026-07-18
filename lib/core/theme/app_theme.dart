import 'package:flutter/material.dart';

import 'package:baka/core/fonts/font_theme.dart';

/// Tokens extracted directly from design mockups:
///   Light _ Aged Paper.html  /  Dark _ Midnight Ink.html
abstract final class AppColors {
  // ── Light — Aged Paper ────────────────────────────────────────────────────
  static const lightBackground      = Color(0xFFF5F0E8); // --background
  static const lightSurface         = Color(0xFFEDE8DC); // --surface
  static const lightSurfaceElev     = Color(0xFFF8F4EC); // --surface-elev
  static const lightCard            = Color(0xFFF8F4EC);
  static const lightPrimary         = Color(0xFFC4622D); // --primary  (terracotta)
  static const lightPrimaryContainer= Color(0xFFF0D5C0); // --primary-container
  static const lightSecondary       = Color(0xFF8A9E7E); // --secondary (sage green)
  static const lightOnPrimaryContainer   = Color(0xFF8A4419); // status chip text
  static const lightSecondaryContainer   = Color(0xFFDDE4D3); // "Ready" chip bg
  static const lightOnSecondaryContainer = Color(0xFF4A5A3C); // "Ready" chip text
  static const lightOnBackground    = Color(0xFF2C1A0E); // --on-background
  static const lightOnSurface       = Color(0xFF3D2314); // --on-surface
  static const lightOnPrimary       = Color(0xFFFFFFFF); // --on-primary
  static const lightOutline         = Color(0xFFC8BAA6); // --outline
  // outline-soft as Color (opacity applied at use site)
  static const lightOutlineSoftBase = Color(0xFFC8BAA6);
  static const lightOutlineSoft     = Color(0x8CC8BAA6); // ~55% opacity
  static const lightRule            = Color(0xB3C8BAA6); // ~70% opacity — lined paper
  static const lightMuted           = Color(0x9E3D2314); // on-surface-muted ~62%
  static const lightError           = Color(0xFFC0392B);
  // Scrim
  static const lightScrim           = Color(0x592C1A0E); // ~35%

  // ── Dark — Midnight Ink ───────────────────────────────────────────────────
  static const darkBackground       = Color(0xFF1A1208); // --background
  static const darkSurface          = Color(0xFF251A0F); // --surface
  static const darkSurfaceElev      = Color(0xFF2E2114); // --surface-elev
  static const darkCard             = Color(0xFF2E2114);
  static const darkPrimary          = Color(0xFFD4784A); // --primary (warm terracotta)
  static const darkPrimaryContainer = Color(0xFF3D2010); // --primary-container
  static const darkSecondary        = Color(0xFF7A9170); // --secondary (sage)
  static const darkOnPrimaryContainer   = Color(0xFFE7B48C); // status chip text
  static const darkSecondaryContainer   = Color(0xFF2A3226); // "Ready" chip bg
  static const darkOnSecondaryContainer = Color(0xFFAEC29C); // "Ready" chip text
  static const darkOnBackground     = Color(0xFFE8DDD0); // --on-background
  static const darkOnSurface        = Color(0xFFD4C4B0); // --on-surface
  static const darkOnPrimary        = Color(0xFFFFFFFF); // --on-primary
  static const darkOutline          = Color(0xFF3A2A1A); // --outline
  static const darkOutlineSoftBase  = Color(0xFF3A2A1A);
  static const darkOutlineSoft      = Color(0xB23A2A1A); // ~70% opacity
  static const darkRule             = Color(0x2ED4C4B0); // ~18% opacity — lined paper
  static const darkMuted            = Color(0x8CD4C4B0); // on-surface-muted ~55%
  static const darkError            = Color(0xFFE57373);
  static const darkScrim            = Color(0x8C000000); // ~55%

  // ── Mood chip colours (theme-independent) ─────────────────────────────────
  static const moodHappy      = Color(0xFFFFF3B0);
  static const moodSad        = Color(0xFFCFE8FF);
  static const moodAngry      = Color(0xFFFFCDD2);
  static const moodTired      = Color(0xFFE8D5F5);
  static const moodAnxious    = Color(0xFFFFE0B2);
  static const moodExcited    = Color(0xFFFCE4EC);
  static const moodCalm       = Color(0xFFDCEFDC);
  static const moodCrying     = Color(0xFFE3F2FD);
  static const moodThoughtful = Color(0xFFF3E5F5);
  static const moodLoved      = Color(0xFFFFEBEE);
}

/// Theme extension — reach via `context.tokens` anywhere.
@immutable
class BakaTokens extends ThemeExtension<BakaTokens> {
  final Color background;
  final Color surface;
  final Color surfaceElev;
  final Color onBackground;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color primary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color outline;
  final Color outlineSoft;
  final Color rule;
  final List<Color> heatmap;

  const BakaTokens({
    required this.background,
    required this.surface,
    required this.surfaceElev,
    required this.onBackground,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.primary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.outline,
    required this.outlineSoft,
    required this.rule,
    required this.heatmap,
  });

  static final light = BakaTokens(
    background:      AppColors.lightBackground,
    surface:         AppColors.lightSurface,
    surfaceElev:     AppColors.lightSurfaceElev,
    onBackground:    AppColors.lightOnBackground,
    onSurface:       AppColors.lightOnSurface,
    onSurfaceMuted:  AppColors.lightMuted,
    primary:         AppColors.lightPrimary,
    primaryContainer:AppColors.lightPrimaryContainer,
    onPrimaryContainer:   AppColors.lightOnPrimaryContainer,
    secondary:       AppColors.lightSecondary,
    secondaryContainer:   AppColors.lightSecondaryContainer,
    onSecondaryContainer: AppColors.lightOnSecondaryContainer,
    outline:         AppColors.lightOutline,
    outlineSoft:     AppColors.lightOutlineSoft,
    rule:            AppColors.lightRule,
    heatmap: [
      AppColors.lightPrimary.withValues(alpha:0.07),
      AppColors.lightPrimary.withValues(alpha:0.22),
      AppColors.lightPrimary.withValues(alpha:0.45),
      AppColors.lightPrimary.withValues(alpha:0.72),
      AppColors.lightPrimary,
    ],
  );

  static final dark = BakaTokens(
    background:      AppColors.darkBackground,
    surface:         AppColors.darkSurface,
    surfaceElev:     AppColors.darkSurfaceElev,
    onBackground:    AppColors.darkOnBackground,
    onSurface:       AppColors.darkOnSurface,
    onSurfaceMuted:  AppColors.darkMuted,
    primary:         AppColors.darkPrimary,
    primaryContainer:AppColors.darkPrimaryContainer,
    onPrimaryContainer:   AppColors.darkOnPrimaryContainer,
    secondary:       AppColors.darkSecondary,
    secondaryContainer:   AppColors.darkSecondaryContainer,
    onSecondaryContainer: AppColors.darkOnSecondaryContainer,
    outline:         AppColors.darkOutline,
    outlineSoft:     AppColors.darkOutlineSoft,
    rule:            AppColors.darkRule,
    heatmap: [
      AppColors.darkPrimary.withValues(alpha:0.09),
      AppColors.darkPrimary.withValues(alpha:0.25),
      AppColors.darkPrimary.withValues(alpha:0.50),
      AppColors.darkPrimary.withValues(alpha:0.78),
      AppColors.darkPrimary,
    ],
  );

  @override
  BakaTokens copyWith({
    Color? background, Color? surface, Color? surfaceElev,
    Color? onBackground, Color? onSurface, Color? onSurfaceMuted,
    Color? primary, Color? primaryContainer, Color? onPrimaryContainer,
    Color? secondary, Color? secondaryContainer, Color? onSecondaryContainer,
    Color? outline, Color? outlineSoft, Color? rule, List<Color>? heatmap,
  }) => BakaTokens(
    background:       background       ?? this.background,
    surface:          surface          ?? this.surface,
    surfaceElev:      surfaceElev      ?? this.surfaceElev,
    onBackground:     onBackground     ?? this.onBackground,
    onSurface:        onSurface        ?? this.onSurface,
    onSurfaceMuted:   onSurfaceMuted   ?? this.onSurfaceMuted,
    primary:          primary          ?? this.primary,
    primaryContainer: primaryContainer ?? this.primaryContainer,
    onPrimaryContainer:   onPrimaryContainer   ?? this.onPrimaryContainer,
    secondary:        secondary        ?? this.secondary,
    secondaryContainer:   secondaryContainer   ?? this.secondaryContainer,
    onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
    outline:          outline          ?? this.outline,
    outlineSoft:      outlineSoft      ?? this.outlineSoft,
    rule:             rule             ?? this.rule,
    heatmap:          heatmap          ?? this.heatmap,
  );

  @override
  BakaTokens lerp(ThemeExtension<BakaTokens>? other, double t) {
    if (other is! BakaTokens) return this;
    return BakaTokens(
      background:       Color.lerp(background,       other.background,       t)!,
      surface:          Color.lerp(surface,           other.surface,          t)!,
      surfaceElev:      Color.lerp(surfaceElev,       other.surfaceElev,      t)!,
      onBackground:     Color.lerp(onBackground,      other.onBackground,     t)!,
      onSurface:        Color.lerp(onSurface,         other.onSurface,        t)!,
      onSurfaceMuted:   Color.lerp(onSurfaceMuted,    other.onSurfaceMuted,   t)!,
      primary:          Color.lerp(primary,           other.primary,          t)!,
      primaryContainer: Color.lerp(primaryContainer,  other.primaryContainer, t)!,
      onPrimaryContainer:   Color.lerp(onPrimaryContainer,   other.onPrimaryContainer,   t)!,
      secondary:        Color.lerp(secondary,         other.secondary,        t)!,
      secondaryContainer:   Color.lerp(secondaryContainer,   other.secondaryContainer,   t)!,
      onSecondaryContainer: Color.lerp(onSecondaryContainer, other.onSecondaryContainer, t)!,
      outline:          Color.lerp(outline,           other.outline,          t)!,
      outlineSoft:      Color.lerp(outlineSoft,       other.outlineSoft,      t)!,
      rule:             Color.lerp(rule,              other.rule,             t)!,
      heatmap: List.generate(
        heatmap.length,
        (i) => Color.lerp(heatmap[i], other.heatmap[i], t)!,
      ),
    );
  }
}

extension BakaContext on BuildContext {
  BakaTokens get tokens => Theme.of(this).extension<BakaTokens>()!;
}

/// Named text styles. Families resolve through the active font preset, so a
/// `hand*` style is whatever the preset nominates as its accent face — not
/// necessarily a handwriting font.
class AppText {
  static TextStyle displayL(BuildContext x, Color c) => TextStyle(
        fontFamily: x.fonts.display,
        fontSize: 36, fontWeight: FontWeight.w600, height: 1.1,
        letterSpacing: -0.5, color: c,
      );
  static TextStyle displayM(BuildContext x, Color c) => TextStyle(
        fontFamily: x.fonts.display,
        fontSize: 28, fontWeight: FontWeight.w600, height: 1.2,
        letterSpacing: -0.3, color: c,
      );
  static TextStyle displayS(BuildContext x, Color c) => TextStyle(
        fontFamily: x.fonts.display,
        fontSize: 20, fontWeight: FontWeight.w600, height: 1.3, color: c,
      );

  static TextStyle handLg(BuildContext x, Color c) => TextStyle(
        fontFamily: x.fonts.accent,
        fontSize: 22, color: c, height: 1.2,
      );
  static TextStyle hand(BuildContext x, Color c) => TextStyle(
        fontFamily: x.fonts.accent,
        fontSize: 18, color: c, height: 1.25,
      );
  static TextStyle handSm(BuildContext x, Color c) => TextStyle(
        fontFamily: x.fonts.accent,
        fontSize: 15, color: c, height: 1.3,
      );

  static TextStyle body(BuildContext x, Color c) => TextStyle(
        fontFamily: x.fonts.body,
        fontSize: 16, height: 1.55, color: c,
      );
  static TextStyle bodySm(BuildContext x, Color c) => TextStyle(
        fontFamily: x.fonts.body,
        fontSize: 14.5, height: 1.55, color: c,
      );
  static TextStyle bodyItalic(BuildContext x, Color c) => TextStyle(
        fontFamily: x.fonts.body,
        fontSize: 16, height: 1.55, color: c, fontStyle: FontStyle.italic,
      );

  static TextStyle mono(BuildContext x, Color c) => TextStyle(
        fontFamily: x.fonts.mono,
        fontSize: 12, letterSpacing: 0.5, color: c,
      );

  /// Oversized decorative headline in the accent face. Not the logo — the
  /// logo is [WordmarkWidget], which pins [kWordmarkFamily] on purpose.
  static TextStyle handXl(BuildContext x, Color c, double size) => TextStyle(
        fontFamily: x.fonts.accent,
        fontSize: size, fontWeight: FontWeight.w700, height: 0.9, color: c,
      );
}

class AppTheme {
  static ThemeData light({required FontPreset preset, String? writingFont}) {
    final f = BakaFonts.of(preset, writingFont: writingFont);
    final textTheme = _buildTextTheme(
      f,
      onBackground: AppColors.lightOnBackground,
      muted: AppColors.lightMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightOnPrimary,
        primaryContainer: AppColors.lightPrimaryContainer,
        onPrimaryContainer: AppColors.lightOnBackground,
        secondary: AppColors.lightSecondary,
        onSecondary: AppColors.lightOnPrimary,
        error: AppColors.lightError,
        onError: AppColors.lightOnPrimary,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
        outline: AppColors.lightOutline,
        outlineVariant: AppColors.lightOutlineSoft,
        scrim: AppColors.lightScrim,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardColor: AppColors.lightCard,
      dividerColor: AppColors.lightOutline,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightOnBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: f.display,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.lightOnBackground,
        ),
        iconTheme: IconThemeData(color: AppColors.lightOnBackground),
      ),
      iconTheme: const IconThemeData(color: AppColors.lightOnBackground, size: 24),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightOutline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.lightMuted),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return AppColors.lightOnPrimary;
          return AppColors.lightOutline;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return AppColors.lightPrimary;
          return AppColors.lightSurface;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return Colors.transparent;
          return AppColors.lightOutline;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightOnBackground,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.lightBackground),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(fontFamily: f.display,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.lightOnBackground,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightCard,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.lightOutline,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: TextStyle(fontFamily: f.body, fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightOnBackground,
          side: const BorderSide(color: AppColors.lightOutline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: TextStyle(fontFamily: f.body, fontWeight: FontWeight.w500, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: TextStyle(fontFamily: f.body, fontWeight: FontWeight.w500, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurface,
        labelStyle: TextStyle(fontFamily: f.accent, fontSize: 13, color: AppColors.lightOnSurface),
        side: const BorderSide(color: AppColors.lightOutline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: AppColors.lightOnPrimary,
        elevation: 2,
      ),
      extensions: [BakaTokens.light, f],
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurfaceElev,
        indicatorColor: AppColors.lightPrimaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.lightPrimary, size: 24);
          }
          return const IconThemeData(color: AppColors.lightMuted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return TextStyle(fontFamily: f.accent,
              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightPrimary,
            );
          }
          return TextStyle(fontFamily: f.accent, fontSize: 12, color: AppColors.lightMuted);
        }),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
      ),
    );
  }

  static ThemeData dark({required FontPreset preset, String? writingFont}) {
    final f = BakaFonts.of(preset, writingFont: writingFont);
    final textTheme = _buildTextTheme(
      f,
      onBackground: AppColors.darkOnBackground,
      muted: AppColors.darkMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        primaryContainer: AppColors.darkPrimaryContainer,
        onPrimaryContainer: AppColors.darkOnBackground,
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkOnPrimary,
        error: AppColors.darkError,
        onError: AppColors.darkOnPrimary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        outline: AppColors.darkOutline,
        outlineVariant: AppColors.darkOutlineSoft,
        scrim: AppColors.darkScrim,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkCard,
      dividerColor: AppColors.darkOutline,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkOnBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: f.display,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.darkOnBackground,
        ),
        iconTheme: IconThemeData(color: AppColors.darkOnBackground),
      ),
      iconTheme: const IconThemeData(color: AppColors.darkOnBackground, size: 24),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkOutline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.darkMuted),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return AppColors.darkBackground;
          return AppColors.darkOutline;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return AppColors.darkPrimary;
          return AppColors.darkSurface;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return Colors.transparent;
          return AppColors.darkOutline;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkOnBackground,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.darkBackground),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(fontFamily: f.display,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkOnBackground,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.darkOutline,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: TextStyle(fontFamily: f.body, fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkOnBackground,
          side: const BorderSide(color: AppColors.darkOutline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: TextStyle(fontFamily: f.body, fontWeight: FontWeight.w500, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: TextStyle(fontFamily: f.body, fontWeight: FontWeight.w500, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface,
        labelStyle: TextStyle(fontFamily: f.accent, fontSize: 13, color: AppColors.darkOnSurface),
        side: const BorderSide(color: AppColors.darkOutline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkOnPrimary,
        elevation: 2,
      ),
      extensions: [BakaTokens.dark, f],
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurfaceElev,
        indicatorColor: AppColors.darkPrimaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.darkPrimary, size: 24);
          }
          return const IconThemeData(color: AppColors.darkMuted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return TextStyle(fontFamily: f.accent,
              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkPrimary,
            );
          }
          return TextStyle(fontFamily: f.accent, fontSize: 12, color: AppColors.darkMuted);
        }),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static TextTheme _buildTextTheme(
    BakaFonts f, {
    required Color onBackground,
    required Color muted,
  }) {
    TextStyle body(double size, FontWeight weight, Color color) =>
        TextStyle(fontFamily: f.body, fontSize: size, fontWeight: weight, color: color);

    return TextTheme(
      displayLarge:   TextStyle(fontFamily: f.display, fontSize: 40, fontWeight: FontWeight.w700, color: onBackground),
      displayMedium:  TextStyle(fontFamily: f.display, fontSize: 34, fontWeight: FontWeight.w700, color: onBackground),
      displaySmall:   TextStyle(fontFamily: f.display, fontSize: 28, fontWeight: FontWeight.w600, color: onBackground),
      headlineLarge:  TextStyle(fontFamily: f.display, fontSize: 26, fontWeight: FontWeight.w600, color: onBackground),
      headlineMedium: TextStyle(fontFamily: f.display, fontSize: 22, fontWeight: FontWeight.w600, color: onBackground),
      headlineSmall:  TextStyle(fontFamily: f.display, fontSize: 18, fontWeight: FontWeight.w600, color: onBackground),
      titleLarge:     TextStyle(fontFamily: f.display, fontSize: 20, fontWeight: FontWeight.w600, color: onBackground),
      titleMedium: body(16, FontWeight.w600, onBackground),
      titleSmall:  body(14, FontWeight.w600, onBackground),
      bodyLarge:   body(18, FontWeight.w400, onBackground),
      bodyMedium:  body(16, FontWeight.w400, onBackground),
      bodySmall:   body(14, FontWeight.w400, muted),
      labelLarge:  body(14, FontWeight.w500, onBackground),
      labelMedium: body(12, FontWeight.w500, muted),
      labelSmall:  body(11, FontWeight.w400, muted),
    );
  }
}

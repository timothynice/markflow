import 'package:flutter/material.dart';

/// Application theme configuration.
/// Vectorizer-inspired minimalist, monochromatic system with subtle depth.

/// Light mode color palette (Vectorizer-inspired)
class LightModeColors {
  // Primary greys
  static const primaryGrey = Color(0xFF4A5568); // --primary-grey
  static const primaryGreyHover = Color(0xFF2D3748); // --primary-dark
  static const brandIcon = Color(0xFF718096); // --brand-icon

  // Backgrounds
  static const backgroundPrimary = Color(0xFFFAFBFC); // --background-primary
  static const backgroundCard = Color(0xFFFFFFFF); // --background-card
  static const backgroundInput = Color(0xFFF8FAFC); // --background-input
  static const backgroundHover = Color(0xFFF1F5F9); // --background-hover
  static const backgroundSubtle = Color(0xFFF7FAFC); // --background-subtle

  // Borders
  static const borderPrimary = Color(0xFFE2E8F0); // --border-primary
  static const borderSecondary = Color(0xFFCBD5E0); // --border-secondary
  static const borderLight = Color(0xFFE5E7EB); // --border-light
  static const borderDisabled = Color(0xFFD1D5DB); // --border-disabled

  // Text
  static const textPrimary = Color(0xFF1A202C); // --text-primary
  static const textSecondary = Color(0xFF2D3748); // --text-secondary
  static const textBody = Color(0xFF4A5568); // --text-body
  static const textMuted = Color(0xFF718096); // --text-muted
  static const textLight = Color(0xFFA0AEC0); // --text-light
  static const textSubtle = Color(0xFF64748B); // --text-subtle

  // Status
  static const error = Color(0xFFE53E3E); // --error-color
  static const errorBackground = Color(0xFFFED7D7); // --error-background

  // Shadows
  static const lightShadow = Color(0x14000000); // very subtle generic

  // App bars
  static const appBar = Color(0xFFF5F5F5); // light subtle app bar background
}

/// Dark mode color palette inferred to match Vectorizer intent
class DarkModeColors {
  // Primary greys
  static const primaryGrey = Color(0xFF94A3B8); // slate-400
  static const primaryGreyHover = Color(0xFF64748B); // slate-500
  static const brandIcon = Color(0xFF94A3B8);

  // Backgrounds
  static const backgroundPrimary = Color(0xFF0B0F14); // deep, muted
  static const backgroundCard = Color(0xFF11161C);
  static const backgroundInput = Color(0xFF0E141A);
  static const backgroundHover = Color(0xFF141A22);
  static const backgroundSubtle = Color(0xFF0C1117);

  // Borders
  static const borderPrimary = Color(0xFF1F2A37);
  static const borderSecondary = Color(0xFF2A3441);
  static const borderLight = Color(0xFF1A2430);
  static const borderDisabled = Color(0xFF2B3643);

  // Text
  static const textPrimary = Color(0xFFE5E7EB);
  static const textSecondary = Color(0xFFCBD5E1);
  static const textBody = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);
  static const textLight = Color(0xFF475569);
  static const textSubtle = Color(0xFF5B6778);

  // Status
  static const error = Color(0xFFEF4444);
  static const errorBackground = Color(0xFF7F1D1D);

  static const appBar = Color(0xFF0F141A);
}

/// Font sizes and typography definitions
class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 24.0;
  static const double headlineSmall = 22.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0;
  static const double titleSmall = 16.0;
  static const double labelLarge = 16.0;
  static const double labelMedium = 14.0;
  static const double labelSmall = 12.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;

  // Legacy properties for backward compatibility
  static const double xs = labelSmall;
  static const double sm = labelMedium;
  static const double base = bodyMedium;
  static const double lg = bodyLarge;
  static const double xl = titleSmall;
  static const double xl2 = titleMedium;
  static const double xl3 = titleLarge;
  static const double xl4 = headlineSmall;
  static const double xl5 = headlineMedium;
  static const double xl6 = headlineLarge;
  static const double xl7 = displaySmall;
  static const double xl8 = displayMedium;
  static const double xl9 = displayLarge;
}

/// Breakpoints for responsive design
class Breakpoints {
  static const double sm = 640.0;
  static const double md = 768.0;
  static const double lg = 1024.0;
  static const double xl = 1280.0;
  static const double xl2 = 1536.0;
}

/// Extension methods to check screen size
extension BreakpointExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  bool get isSm => screenWidth >= Breakpoints.sm;
  bool get isMd => screenWidth >= Breakpoints.md;
  bool get isLg => screenWidth >= Breakpoints.lg;
  bool get isXl => screenWidth >= Breakpoints.xl;
  bool get is2Xl => screenWidth >= Breakpoints.xl2;
}

/// Extension methods to easily access theme colors
extension ThemeColors on BuildContext {
  Color get primary => Theme.of(this).colorScheme.primary;
  Color get onPrimary => Theme.of(this).colorScheme.onPrimary;
  Color get background => Theme.of(this).scaffoldBackgroundColor;
  Color get foreground => Theme.of(this).colorScheme.onSurface;
  Color get error => Theme.of(this).colorScheme.error;
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get outline => Theme.of(this).dividerColor;
}

/// Light theme data
ThemeData get lightTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    scaffoldBackgroundColor: LightModeColors.backgroundPrimary,
    colorScheme: const ColorScheme.light(
      primary: LightModeColors.primaryGrey,
      onPrimary: Colors.white,
      surface: LightModeColors.backgroundCard,
      onSurface: LightModeColors.textBody,
      error: LightModeColors.error,
    ),
    dividerColor: LightModeColors.borderPrimary,
    appBarTheme: const AppBarTheme(
      backgroundColor: LightModeColors.appBar,
      foregroundColor: LightModeColors.textSecondary,
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.normal,
      fontFamily: 'Geist',
    ),
    displayMedium: TextStyle(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.normal,
      fontFamily: 'Geist',
    ),
    displaySmall: TextStyle(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
      fontFamily: 'Geist',
    ),
    headlineLarge: TextStyle(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.normal,
      fontFamily: 'Geist',
    ),
    headlineMedium: TextStyle(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w500,
      fontFamily: 'Geist',
    ),
    headlineSmall: TextStyle(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
      fontFamily: 'Geist',
    ),
    titleLarge: TextStyle(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w500,
      fontFamily: 'Geist',
    ),
    titleMedium: TextStyle(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
      fontFamily: 'Geist',
    ),
    titleSmall: TextStyle(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
      fontFamily: 'Geist',
    ),
    labelLarge: TextStyle(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
      fontFamily: 'Geist',
    ),
    labelMedium: TextStyle(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
      fontFamily: 'Geist',
    ),
    labelSmall: TextStyle(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
      fontFamily: 'Geist',
    ),
    bodyLarge: TextStyle(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
      fontFamily: 'Geist',
    ),
    bodyMedium: TextStyle(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
      fontFamily: 'Geist',
    ),
    bodySmall: TextStyle(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
      fontFamily: 'Geist',
    ),
    ),
    fontFamily: 'Geist',
    fontFamilyFallback: const ['Geist', 'sans-serif'],
    // Buttons
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const MaterialStatePropertyAll(Size(40, 40)),
        padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.pressed) || states.contains(MaterialState.hovered)) {
            return LightModeColors.primaryGreyHover;
          }
          return LightModeColors.primaryGrey;
        }),
        foregroundColor: const MaterialStatePropertyAll(Colors.white),
        elevation: const MaterialStatePropertyAll(0),
        overlayColor: const MaterialStatePropertyAll(Colors.transparent),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        side: MaterialStatePropertyAll(
          BorderSide(color: LightModeColors.borderSecondary, width: 1),
        ),
        foregroundColor: const MaterialStatePropertyAll(LightModeColors.textBody),
        overlayColor: const MaterialStatePropertyAll(Colors.transparent),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        overlayColor: const MaterialStatePropertyAll(Colors.transparent),
      ),
    ),
    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: LightModeColors.backgroundInput,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: const TextStyle(color: LightModeColors.textLight),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: LightModeColors.borderDisabled, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: LightModeColors.borderDisabled, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: LightModeColors.primaryGrey, width: 1.5),
      ),
    ),
    // Sliders
    sliderTheme: const SliderThemeData(
      trackHeight: 4,
      inactiveTrackColor: LightModeColors.borderPrimary,
      activeTrackColor: LightModeColors.primaryGrey,
      thumbColor: LightModeColors.primaryGrey,
      overlayColor: Color(0x144A5568),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return LightModeColors.primaryGrey;
        return LightModeColors.borderSecondary;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return LightModeColors.primaryGrey.withValues(alpha: 0.35);
        return LightModeColors.borderPrimary;
      }),
    ),
    // Cards / panels
    cardTheme: const CardThemeData(
      color: LightModeColors.backgroundCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: LightModeColors.borderPrimary, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: LightModeColors.borderPrimary,
      thickness: 1,
      space: 1,
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(color: Color(0xFF111111)),
      textStyle: TextStyle(color: Colors.white),
    ),
  );
}

/// Dark theme data
ThemeData get darkTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    scaffoldBackgroundColor: DarkModeColors.backgroundPrimary,
    colorScheme: const ColorScheme.dark(
      primary: DarkModeColors.primaryGrey,
      onPrimary: Colors.black,
      surface: DarkModeColors.backgroundCard,
      onSurface: DarkModeColors.textBody,
      error: DarkModeColors.error,
    ),
    dividerColor: DarkModeColors.borderPrimary,
    appBarTheme: const AppBarTheme(
      backgroundColor: DarkModeColors.appBar,
      foregroundColor: DarkModeColors.textSecondary,
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.normal,
      fontFamily: 'Geist',
    ),
    displayMedium: TextStyle(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.normal,
      fontFamily: 'Geist',
    ),
    displaySmall: TextStyle(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
      fontFamily: 'Geist',
    ),
    headlineLarge: TextStyle(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.normal,
      fontFamily: 'Geist',
    ),
    headlineMedium: TextStyle(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w500,
      fontFamily: 'Geist',
    ),
    headlineSmall: TextStyle(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
      fontFamily: 'Geist',
    ),
    titleLarge: TextStyle(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w500,
      fontFamily: 'Geist',
    ),
    titleMedium: TextStyle(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
      fontFamily: 'Geist',
    ),
    titleSmall: TextStyle(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
      fontFamily: 'Geist',
    ),
    labelLarge: TextStyle(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
      fontFamily: 'Geist',
    ),
    labelMedium: TextStyle(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
      fontFamily: 'Geist',
    ),
    labelSmall: TextStyle(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
      fontFamily: 'Geist',
    ),
    bodyLarge: TextStyle(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
      fontFamily: 'Geist',
    ),
    bodyMedium: TextStyle(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
      fontFamily: 'Geist',
    ),
    bodySmall: TextStyle(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
      fontFamily: 'Geist',
    ),
    ),
    fontFamily: 'Geist',
    fontFamilyFallback: const ['Geist', 'sans-serif'],
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const MaterialStatePropertyAll(Size(40, 40)),
        padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.pressed) || states.contains(MaterialState.hovered)) {
            return DarkModeColors.primaryGreyHover;
          }
          return DarkModeColors.primaryGrey;
        }),
        foregroundColor: const MaterialStatePropertyAll(Colors.black),
        elevation: const MaterialStatePropertyAll(0),
        overlayColor: const MaterialStatePropertyAll(Colors.transparent),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        side: MaterialStatePropertyAll(
          BorderSide(color: DarkModeColors.borderSecondary, width: 1),
        ),
        foregroundColor: const MaterialStatePropertyAll(DarkModeColors.textBody),
        overlayColor: const MaterialStatePropertyAll(Colors.transparent),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        overlayColor: const MaterialStatePropertyAll(Colors.transparent),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: DarkModeColors.backgroundInput,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: const TextStyle(color: DarkModeColors.textLight),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: DarkModeColors.borderDisabled, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: DarkModeColors.borderDisabled, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: DarkModeColors.primaryGrey, width: 1.5),
      ),
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 4,
      inactiveTrackColor: DarkModeColors.borderPrimary,
      activeTrackColor: DarkModeColors.primaryGrey,
      thumbColor: DarkModeColors.primaryGrey,
      overlayColor: Color(0x1494A3B8),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return DarkModeColors.primaryGrey;
        return DarkModeColors.borderSecondary;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return DarkModeColors.primaryGrey.withValues(alpha: 0.35);
        return DarkModeColors.borderPrimary;
      }),
    ),
    cardTheme: const CardThemeData(
      color: DarkModeColors.backgroundCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: DarkModeColors.borderPrimary, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: DarkModeColors.borderPrimary,
      thickness: 1,
      space: 1,
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(color: Color(0xFF0B0B0B)),
      textStyle: TextStyle(color: Colors.white),
    ),
  );
}

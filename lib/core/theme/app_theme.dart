// File: lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Premium Blue theme for reGain focus app
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF469CC5), // Ocean blue
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF5CB3D9), // Lighter bright blue
      onSecondary: Color(0xFF1A1A1A),
      tertiary: Color(0xFF3584A8), // Deeper blue
      onTertiary: Color(0xFFFFFFFF),
      error: Color(0xFFFF5252),
      onError: Colors.white,
      surface: Color(0xFF1E1E1E), // Card/elevated surface
      onSurface: Color(0xFFFFFFFF), // White text
      surfaceContainerHighest: Color(0xFF2A2A2A), // Slightly elevated
      outline: Color(0xFF3A3A3A), // Border color
      shadow: Color(0xFF000000),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFFB0B0B0),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Color(0xFFE0E0E0),
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFFB0B0B0),
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: Color(0xFF8A8A8A),
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFFB0B0B0),
        letterSpacing: 0.3,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8A8A8A),
        letterSpacing: 0.3,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: Color(0xFF6A6A6A),
        letterSpacing: 0.3,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F0F0F),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: Colors.white, size: 24),
      actionsIconTheme: IconThemeData(color: Colors.white, size: 24),
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF469CC5), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF5252), width: 2),
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF8A8A8A),
        fontSize: 14,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF6A6A6A),
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        disabledBackgroundColor: const Color(0xFF3A3A3A),
        disabledForegroundColor: const Color(0xFF6A6A6A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        elevation: 0,
        shadowColor: Colors.transparent,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF469CC5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: const BorderSide(color: Color(0xFF469CC5), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF469CC5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF2D2D2D),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: const TextStyle(
        color: Color(0xFFB0B0B0),
        fontSize: 16,
        height: 1.5,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      modalBackgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF2A2A2A),
      selectedColor: const Color(0xFF469CC5),
      disabledColor: const Color(0xFF1A1A1A),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Color(0xFF1A1A1A),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: BorderSide.none,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF1A1A1A);
        }
        return const Color(0xFF6A6A6A);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF469CC5);
        }
        return const Color(0xFF3A3A3A);
      }),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: Color(0xFF469CC5),
      inactiveTrackColor: Color(0xFF3A3A3A),
      thumbColor: Color(0xFF469CC5),
      overlayColor: Color(0x33469CC5),
      valueIndicatorColor: Color(0xFF469CC5),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFF469CC5),
      linearTrackColor: Color(0xFF3A3A3A),
      circularTrackColor: Color(0xFF3A3A3A),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2A2A2A),
      thickness: 1,
      space: 1,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F0F),
    dividerColor: const Color(0xFF2A2A2A),
    splashColor: const Color(0x1A469CC5),
    highlightColor: const Color(0x0D469CC5),
    iconTheme: const IconThemeData(
      color: Colors.white,
      size: 24,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF469CC5),
      foregroundColor: Colors.white,
      elevation: 0,
      highlightElevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF0F0F0F),
      indicatorColor: const Color(0xFF469CC5).withOpacity(0.15),
      elevation: 0,
      height: 70,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF469CC5),
          );
        }
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6A6A6A),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
            color: Color(0xFF469CC5),
            size: 26,
          );
        }
        return const IconThemeData(
          color: Color(0xFF6A6A6A),
          size: 26,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF2A2A2A),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: AppColors.surface,
      textColor: Colors.white,
      iconColor: Color(0xFF469CC5),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    badgeTheme: const BadgeThemeData(
      backgroundColor: Color(0xFF469CC5),
      textColor: Colors.white,
      textStyle: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

// Premium Blue Color Palette
// File: lib/core/theme/app_colors.dart
class AppColors {
  // Brand Colors - Premium Blue Theme
    static const primaryBlue = Color(0xFF469CC5); // Ocean blue - main brand
  static const lightBlue = Color(0xFF5CB3D9); // Bright lighter blue for accents
  static const deepBlue = Color(0xFF3584A8); // Deeper blue for depth
  static const skyBlue = Color(0xFF6FCCE8); // Sky blue for highlights

  // Background Colors
  static const background = Color(0xFF0F0F0F); // Deep black background
  static const surface = Color(0xFF2D2D2D); // Cards and elevated surfaces
  static const surfaceElevated = Color(0xFF2A2A2A); // More elevated surfaces

  // Text Colors
  static const textPrimary = Color(0xFFFFFFFF); // Pure white
  static const textSecondary = Color(0xFFE0E0E0); // Light gray
  static const textTertiary = Color(0xFFB0B0B0); // Medium gray
  static const textMuted = Color(0xFF8A8A8A); // Muted gray
  static const textDisabled = Color(0xFF6A6A6A); // Disabled gray

  // Border & Divider
  static const border = Color(0xFF3A3A3A);
  static const divider = Color(0xFF2A2A2A);

  // Status Colors
  static const error = Color(0xFFFF5252);
  static const success = Color(0xFF469CC5); // Using blue as success
  static const warning = Color(0xFFFF9500); // Keep amber for warnings
  static const info = Color(0xFF64B5F6);

  // Special
  static const activeIndicator = Color(0xFF469CC5); // Blue dot for "focusing now"
  static const focusGlow = Color(0xFF5CB3D9); // Lighter glow effect
  static const premiumBadge = Color(0xFF469CC5); // Ocean blue for PRO badge

  // Gradient colors for premium effects
  static const gradientStart = Color(0xFF469CC5);
  static const gradientEnd = Color(0xFF3584A8);
}
import 'package:flutter/material.dart';

class AppColors {
  static bool _isDark = true;

  /// Call this when theme mode changes. All `AppColors.xxx` getters
  /// will automatically return the appropriate color.
  static void setDark(bool dark) => _isDark = dark;
  static bool get isDark => _isDark;

  // ── Background ──────────────────────────────────────────────
  static Color get bgPrimary =>
      _isDark ? const Color(0xFF13161C) : const Color(0xFFF8F9FA);
  static Color get bgSecondary =>
      _isDark ? const Color(0xFF1C2028) : const Color(0xFFFFFFFF);
  static Color get bgTertiary =>
      _isDark ? const Color(0xFF252C38) : const Color(0xFFF0F1F3);
  static Color get bgElevated =>
      _isDark ? const Color(0xFF212838) : const Color(0xFFFFFFFF);
  static Color get bgHover =>
      _isDark ? const Color(0xFF2A3242) : const Color(0xFFE8EAF0);

  // ── Text ────────────────────────────────────────────────────
  static Color get textPrimary =>
      _isDark ? const Color(0xFFF0F1F4) : const Color(0xFF1A1D28);
  static Color get textSecondary =>
      _isDark ? const Color(0xFFC8CED8) : const Color(0xFF4A5068);
  static Color get textTertiary =>
      _isDark ? const Color(0xFF9CA4B8) : const Color(0xFF6B7390);

  // ── Border ──────────────────────────────────────────────────
  static Color get borderSubtle =>
      _isDark ? const Color(0xFF343C50) : const Color(0xFFE5E7EB);
  static Color get borderDefault =>
      _isDark ? const Color(0xFF424A60) : const Color(0xFFD1D5DB);
  static Color get borderStrong =>
      _isDark ? const Color(0xFF4A5370) : const Color(0xFFB0B8C8);

  // ── Accent ──────────────────────────────────────────────────
  static const accentPrimary = Color(0xFF5A96FF);
  static const accentSubtle = Color(0x264F8CFF);
  static Color get accentText =>
      _isDark ? const Color(0xFF7DB3FF) : const Color(0xFF3A78E0);

  // ── Status ──────────────────────────────────────────────────
  static const statusRunning = Color(0xFF34D399);
  static const statusIdle = Color(0xFFFBBF24);
  static const statusStopped = Color(0xFF6B7280);
  static const statusError = Color(0xFFEF4444);

  // ── Semantic ────────────────────────────────────────────────
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF22C55E);
}

class AppTheme {
  static Color _parseHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  static ThemeData darkTheme({String? accentHex}) {
    final accent = _parseHex(accentHex, AppColors.accentPrimary);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF13161C),
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: const Color(0xFF1C2028),
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFFF0F1F4),
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1C2028),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF343C50)),
        ),
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF13161C),
        foregroundColor: Color(0xFFF0F1F4),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C2028),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF424A60)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF424A60)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: const TextStyle(color: Color(0xFF9CA4B8), fontSize: 13),
        labelStyle: const TextStyle(color: Color(0xFFC8CED8), fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFC8CED8),
          side: const BorderSide(color: Color(0xFF424A60)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF343C50),
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFF0F1F4)),
        headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF0F1F4)),
        headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFF0F1F4)),
        bodyLarge: TextStyle(fontSize: 14, color: Color(0xFFF0F1F4)),
        bodyMedium: TextStyle(fontSize: 13, color: Color(0xFFF0F1F4)),
        bodySmall: TextStyle(fontSize: 12, color: Color(0xFFC8CED8)),
        labelSmall: TextStyle(fontSize: 11, color: Color(0xFF9CA4B8)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: const Color(0xFF9CA4B8),
        indicatorColor: accent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF252C38),
        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFFC8CED8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: Color(0xFF343C50)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF212838),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF212838),
        contentTextStyle: TextStyle(color: Color(0xFFF0F1F4), fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(Color(0xFF212838)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          elevation: const WidgetStatePropertyAll(8),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF212838),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData lightTheme({String? accentHex}) {
    final accent = _parseHex(accentHex, AppColors.accentPrimary);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: accent,
        surface: const Color(0xFFFFFFFF),
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFF1A1D28),
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8F9FA),
        foregroundColor: Color(0xFF1A1D28),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: const TextStyle(color: Color(0xFF6B7390), fontSize: 13),
        labelStyle: const TextStyle(color: Color(0xFF4A5068), fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4A5068),
          side: const BorderSide(color: Color(0xFFD1D5DB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A1D28)),
        headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1D28)),
        headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1D28)),
        bodyLarge: TextStyle(fontSize: 14, color: Color(0xFF1A1D28)),
        bodyMedium: TextStyle(fontSize: 13, color: Color(0xFF1A1D28)),
        bodySmall: TextStyle(fontSize: 12, color: Color(0xFF4A5068)),
        labelSmall: TextStyle(fontSize: 11, color: Color(0xFF6B7390)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: const Color(0xFF6B7390),
        indicatorColor: accent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0F1F3),
        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF4A5068)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF1A1D28),
        contentTextStyle: TextStyle(color: Color(0xFFF0F1F4), fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(Color(0xFFFFFFFF)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          elevation: const WidgetStatePropertyAll(8),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}

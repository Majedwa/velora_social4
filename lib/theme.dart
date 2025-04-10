import 'package:flutter/material.dart';

class AppTheme {
  // الألوان الأساسية
  static const Color primaryColor = Color(0xFF3F51B5);      // أزرق داكن
  static const Color secondaryColor = Color(0xFF303F9F);    // أزرق أغمق
  static const Color accentColor = Color(0xFFFF4081);       // وردي
  static const Color backgroundColor = Color(0xFFF5F5F5);   // رمادي فاتح
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFB00020);

  // ألوان النص للوضع الفاتح
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textLightColor = Color(0xFFBDBDBD);

  // ألوان للوضع الداكن
  static const Color darkPrimaryColor = Color(0xFF303F9F);      // أزرق داكن
  static const Color darkSecondaryColor = Color(0xFF1A237E);    // أزرق أغمق
  static const Color darkAccentColor = Color(0xFFFF4081);       // وردي
  static const Color darkBackgroundColor = Color(0xFF121212);   // رمادي داكن
  static const Color darkSurfaceColor = Color(0xFF1D1D1D);      // سطح داكن
  static const Color darkErrorColor = Color(0xFFCF6679);        // أحمر داكن

  // ألوان النص للوضع الداكن
  static const Color darkTextPrimaryColor = Color(0xFFEEEEEE);
  static const Color darkTextSecondaryColor = Color(0xFFAAAAAA);
  static const Color darkTextLightColor = Color(0xFF666666);

  // خط موحد للتطبيق
  static const String fontFamily = 'Cairo';

  // موضوع التطبيق للوضع العادي
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: surfaceColor,
      background: backgroundColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimaryColor,
      onBackground: textPrimaryColor,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: backgroundColor,
    fontFamily: fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: fontFamily,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textPrimaryColor),
      displayMedium: TextStyle(color: textPrimaryColor),
      displaySmall: TextStyle(color: textPrimaryColor),
      headlineMedium: TextStyle(color: textPrimaryColor),
      headlineSmall: TextStyle(color: textPrimaryColor),
      titleLarge: TextStyle(color: textPrimaryColor),
      bodyLarge: TextStyle(color: textPrimaryColor),
      bodyMedium: TextStyle(color: textPrimaryColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: textLightColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondaryColor,
    ),
  );

  // موضوع التطبيق للوضع الداكن
  static ThemeData darkTheme = ThemeData(
    primaryColor: darkPrimaryColor,
    colorScheme: ColorScheme.dark(
      primary: darkPrimaryColor,
      secondary: darkAccentColor,
      surface: darkSurfaceColor,
      background: darkBackgroundColor,
      error: darkErrorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkTextPrimaryColor,
      onBackground: darkTextPrimaryColor,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    fontFamily: fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkPrimaryColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: fontFamily,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: darkTextPrimaryColor),
      displayMedium: TextStyle(color: darkTextPrimaryColor),
      displaySmall: TextStyle(color: darkTextPrimaryColor),
      headlineMedium: TextStyle(color: darkTextPrimaryColor),
      headlineSmall: TextStyle(color: darkTextPrimaryColor),
      titleLarge: TextStyle(color: darkTextPrimaryColor),
      bodyLarge: TextStyle(color: darkTextPrimaryColor),
      bodyMedium: TextStyle(color: darkTextPrimaryColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: darkTextLightColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: darkPrimaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      fillColor: darkSurfaceColor,
      filled: true,
    ),
    cardTheme: CardTheme(
      color: darkSurfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurfaceColor,
      selectedItemColor: darkAccentColor,
      unselectedItemColor: darkTextSecondaryColor,
    ),
    iconTheme: const IconThemeData(
      color: darkTextPrimaryColor,
    ),
    dividerColor: darkTextLightColor.withOpacity(0.2),
  );
}
import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF00BCD4); // Cyan seed — matches MediaSnatch's cyan header

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      background: const Color(0xFF0D1117),
      surface: const Color(0xFF161B22),
      surfaceVariant: const Color(0xFF1C2128),
      primary: _seed,
      secondary: const Color(0xFF58A6FF),
      tertiary: const Color(0xFF3FB950),
      error: const Color(0xFFF85149),
    ),
    scaffoldBackgroundColor: const Color(0xFF0D1117),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF161B22),
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF161B22),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF30363D), width: 1),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Color(0xFF00BCD4),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
      subtitleTextStyle: TextStyle(color: Color(0xFF8B949E), fontSize: 12),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1C2128),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF30363D)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF30363D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF8B949E)),
      hintStyle: const TextStyle(color: Color(0xFF484F58)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _seed,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _seed),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF1C2128),
      selectedColor: _seed.withOpacity(0.2),
      side: const BorderSide(color: Color(0xFF30363D)),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF21262D), thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1C2128),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF161B22),
      selectedItemColor: Color(0xFF00BCD4),
      unselectedItemColor: Color(0xFF8B949E),
    ),
  );
}

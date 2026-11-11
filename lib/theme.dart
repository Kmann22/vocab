import 'package:flutter/material.dart';

/// WordWiser brand colours (match the landing page).
class WW {
  WW._();

  static const navy = Color(0xFF16296B);
  static const blue = Color(0xFF5B88DC);
  static const sky = Color(0xFFEAF3FF);
  static const background = Color(0xFFD8E8FB);
  static const outline = Color(0xFFB9D0F3);
  static const flower = Color(0xFFA9C6F5);
  static const yellow = Color(0xFFFBDA6E);
  static const yellowSoft = Color(0xFFFBE08A);
  static const muted = Color(0xFF4A5A8A);
  static const white = Colors.white;

  // Game colours
  static const correct = Color(0xFF2F8F5B);
  static const present = Color(0xFFB7791F);
  static const absent = Color(0xFF6F7A9C);
  static const danger = Color(0xFFC0392B);

  static const shadow = [
    BoxShadow(color: Color(0x1416296B), blurRadius: 30, offset: Offset(0, 12)),
  ];
}

/// Big condensed headline, like "LEARN A NEW WORD."
TextStyle displayStyle(double size, {Color color = WW.navy}) =>
    TextStyle(
      fontFamily: 'BebasNeue',
      fontSize: size,
      color: color,
      height: 0.95,
      letterSpacing: 0.6,
    );

/// Rounded logo type.
TextStyle logoStyle(double size, {Color color = WW.navy}) => TextStyle(
      fontFamily: 'Fredoka',
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      height: 0.95,
    );

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'DMSans',
    colorScheme: ColorScheme.fromSeed(
      seedColor: WW.blue,
      primary: WW.navy,
      onPrimary: Colors.white,
      secondary: WW.yellow,
      onSecondary: WW.navy,
      surface: Colors.white,
      onSurface: WW.navy,
      error: WW.danger,
    ),
  );

  final text = base.textTheme.apply(
    fontFamily: 'DMSans',
    bodyColor: WW.navy,
    displayColor: WW.navy,
  );

  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: WW.outline, width: 1.5),
  );

  return base.copyWith(
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
    scaffoldBackgroundColor: WW.sky,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: WW.sky,
      foregroundColor: WW.navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontFamily: 'BebasNeue',
        fontSize: 30,
        color: WW.navy,
        letterSpacing: 1,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: WW.yellow,
        foregroundColor: WW.navy,
        disabledBackgroundColor: WW.yellowSoft,
        disabledForegroundColor: WW.muted,
        elevation: 0,
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontFamily: 'DMSans', 
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: WW.navy,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        side: const BorderSide(color: WW.outline, width: 1.5),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontFamily: 'DMSans', fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: WW.navy,
        minimumSize: const Size(44, 44),
        textStyle: const TextStyle(fontFamily: 'DMSans', fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: const TextStyle(color: WW.muted),
      floatingLabelStyle: const TextStyle(color: WW.navy, fontWeight: FontWeight.w600),
      hintStyle: const TextStyle(color: WW.muted),
      helperStyle: const TextStyle(color: WW.muted),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: WW.navy, width: 2),
      ),
      errorBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: WW.danger, width: 1.5),
      ),
      focusedErrorBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: WW.danger, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: WW.navy,
      contentTextStyle: const TextStyle(fontFamily: 'DMSans', color: Colors.white, fontSize: 15),
      actionTextColor: WW.yellow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: WW.navy),
    dividerColor: WW.outline,
  );
}

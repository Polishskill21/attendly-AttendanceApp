import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Themebuilder {

  static ThemeData buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.deepPurple,
      primaryColor: Colors.deepPurple,
      primaryColorLight: Colors.purpleAccent,
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: AppBarTheme(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.deepPurple, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.deepPurple),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

static ThemeData buildDarkTheme() {
   final base = ThemeData.dark();
  return base.copyWith(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
    //primarySwatch: Colors.deepPurple,
    primaryColor: Colors.deepPurple,
    primaryColorLight: Colors.purpleAccent,
    scaffoldBackgroundColor: Colors.grey[900],
    drawerTheme: DrawerThemeData(
      backgroundColor: Colors.grey[900],
    ),
    listTileTheme: ListTileThemeData(
  iconColor: Colors.grey[300],      // light gray icons
  textColor: Colors.grey[300],      // light gray text to match icons
),
    appBarTheme: AppBarTheme(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF121212),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.deepPurple),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dialogTheme: DialogTheme(
        backgroundColor: Colors.grey[850],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[800],
      hintStyle: TextStyle(color: Colors.grey[400]),
      labelStyle: TextStyle(color: Colors.deepPurple),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade600),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.deepPurple, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textTheme: base.textTheme.copyWith(
    bodyLarge: TextStyle(color: Colors.white),        // Main body
    bodyMedium: TextStyle(color: Colors.white70),     // Secondary body
    titleLarge: TextStyle(color: Colors.white),       // Headline
    titleMedium: TextStyle(color: Colors.white70),    // Subheadline
    labelLarge: TextStyle(color: Colors.white60),     // Button labels, etc.
    ),
    iconTheme: IconThemeData(color: Colors.grey),
  );
}

  // static ThemeData buildDarkTheme() {
  //   return ThemeData(
  //     brightness: Brightness.dark,
  //     primarySwatch: Colors.deepPurple,
  //     primaryColor: Colors.deepPurple,
  //     primaryColorLight: Colors.purpleAccent,
  //     scaffoldBackgroundColor: Colors.grey[900],
  //     appBarTheme: AppBarTheme(
  //       systemOverlayStyle: SystemUiOverlayStyle(
  //         // Make status bar icons light
  //         statusBarIconBrightness: Brightness.light,
  //         // For iOS
  //         statusBarBrightness: Brightness.dark,
  //       ),
  //       backgroundColor: Colors.transparent,
  //       elevation: 0,
  //       iconTheme: IconThemeData(color: Colors.deepPurple),
  //       titleTextStyle: TextStyle(
  //         color: Colors.white,
  //         fontSize: 22,
  //         fontWeight: FontWeight.bold,
  //       ),
  //     ),
  //     cardTheme: CardTheme(
  //       elevation: 2,
  //       color: Colors.grey[800],
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //     ),
  //     floatingActionButtonTheme: FloatingActionButtonThemeData(
  //       backgroundColor: Colors.deepPurple,
  //       foregroundColor: Colors.white,
  //     ),
  //     inputDecorationTheme: InputDecorationTheme(
  //       border: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(8),
  //         borderSide: BorderSide(color: Colors.grey.shade600),
  //       ),
  //       focusedBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(8),
  //         borderSide: BorderSide(color: Colors.deepPurple, width: 2),
  //       ),
  //       labelStyle: TextStyle(color: Colors.deepPurple),
  //     ),
  //     elevatedButtonTheme: ElevatedButtonThemeData(
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: Colors.deepPurple,
  //         foregroundColor: Colors.white,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //         padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  //       ),
  //     ),
  //   );
  // }
}
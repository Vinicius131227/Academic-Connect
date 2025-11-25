import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // --- CORES FIXAS ---
  static const Color primaryPurple = Color(0xFF8C52FF); 
  static const Color secondaryPurple = Color(0xFF9D5CFF); 
  static const Color cardYellow = Color(0xFFFBC02D);
  static const Color cardOrange = Color(0xFFFF7043);
  static const Color cardBlue = Color(0xFF42A5F5);
  static const Color cardGreen = Color(0xFF66BB6A);

  // --- CORES ESCURO ---
  static const Color backgroundDark = Color(0xFF181818); 
  static const Color surfaceDark = Color(0xFF2C2C2C);    
  static const Color textWhite = Colors.white;
  static const Color textGreyDark = Colors.white54;

  // --- CORES CLARO ---
  static const Color backgroundLight = Color(0xFFF4F6F8); 
  static const Color surfaceLight = Colors.white;         
  static const Color textBlack = Color(0xFF1A1A1A);       
  static const Color textGreyLight = Color(0xFF757575);   
  
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF66BB6A);

  // --- ALIASES DE COMPATIBILIDADE ---
  static const Color background = backgroundDark; 
  static const Color surface = surfaceDark;       
  static const Color inputFill = surfaceDark;
  static const Color textGrey = textGreyDark;
  
  static const Color darkBg = backgroundDark;
  static const Color darkSurface = surfaceDark;
  static const Color lightBg = backgroundLight;
  static const Color lightSurface = surfaceLight;
  static const Color darkText = textWhite;
  static const Color lightText = textBlack;
  static const Color darkTextSecondary = textGreyDark;
  static const Color lightTextSecondary = textGreyLight;
  static const Color darkTextHint = textGreyDark;
  static const Color lightTextHint = textGreyLight;
  static const Color darkAccent = primaryPurple;
  static const Color lightAccent = primaryPurple;
  static const Color darkPrimary = primaryPurple;
  static const Color lightPrimary = primaryPurple;
}

class AppTheme {
  // --- TEMA ESCURO ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      primaryColor: AppColors.primaryPurple,
      
      // Define a cor padrão dos cards via colorScheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryPurple,
        onPrimary: Colors.white,
        secondary: AppColors.secondaryPurple,
        surface: AppColors.surfaceDark, // Isso define a cor dos Cards automaticamente
        background: AppColors.backgroundDark,
        error: AppColors.error,
      ),

      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textWhite,
        displayColor: AppColors.textWhite,
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textWhite),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundDark,
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade800)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primaryPurple)),
      ),
      
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  // --- TEMA CLARO ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      primaryColor: AppColors.primaryPurple,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryPurple,
        onPrimary: Colors.white,
        secondary: AppColors.secondaryPurple,
        surface: AppColors.surfaceLight, // Cor dos Cards no modo claro
        background: AppColors.backgroundLight,
        error: AppColors.error,
      ),

      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: AppColors.textBlack,
        displayColor: AppColors.textBlack,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textBlack),
        titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textBlack),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor: Colors.black26,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.black12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primaryPurple)),
      ),
      
      iconTheme: const IconThemeData(color: AppColors.textBlack),
    );
  }
}
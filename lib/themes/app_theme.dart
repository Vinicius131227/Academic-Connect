import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Classe para guardar nossas cores (baseada nas suas paletas)
class AppColors {
  // Paleta Escura (Roxo/Preto)
  static const Color darkBg = Color(0xFF1A1A2E); // Um fundo quase preto
  static const Color darkSurface = Color(0xFF240046); // Card principal (Roxo escuro)
  static const Color darkPrimary = Color(0xFF7B2CBF); // Roxo principal
  static const Color darkAccent = Color(0xFF9D4EDD); // Roxo mais claro

  // Paleta Clara (Lilás/Bege)
  static const Color lightBg = Color(0xFFF8F7FF); // Fundo (Branco gelo/Lilás)
  static const Color lightSurface = Color(0xFFFFFFFF); // Card (Branco puro)
  static const Color lightPrimary = Color(0xFF9370DB); // Lilás (do seu exemplo)
  static const Color lightAccent = Color(0xFFCBA2CB); // Lilás claro (do seu exemplo)
  
  // Cores Neutras
  static const Color lightText = Color(0xFF000000);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color lightTextSecondary = Color(0xFF5A5A5A);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color lightTextHint = Color(0xFF9E9E9E);
  static const Color darkTextHint = Color(0xFF757575);
}

class AppTheme {

  // --- TEMA CLARO ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.lightPrimary,
        brightness: Brightness.light,
        surface: AppColors.lightSurface, // Fundo dos Cards
        background: AppColors.lightBg, // Fundo do App
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        titleLarge: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.lightText),
        titleMedium: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.lightText),
        bodyMedium: const TextStyle(color: AppColors.lightTextSecondary),
        bodySmall: const TextStyle(color: AppColors.lightTextHint),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: AppColors.darkText, // Texto branco no AppBar
      ),
      
      // --- CORREÇÃO AQUI ---
      cardTheme: CardThemeData( 
        elevation: 0, 
        color: AppColors.lightSurface,
        margin: const EdgeInsets.only(bottom: 16.0), 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), 
          side: BorderSide(color: Colors.grey[200]!),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[150],
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.darkText,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.lightPrimary,
        unselectedItemColor: AppColors.lightTextHint,
        elevation: 5,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // --- TEMA ESCURO ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.darkPrimary,
        brightness: Brightness.dark,
        surface: AppColors.darkSurface, // Fundo dos Cards
        background: AppColors.darkBg, // Fundo do App
        onSurface: AppColors.darkText,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        titleLarge: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText),
        titleMedium: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkText),
        bodyMedium: const TextStyle(color: AppColors.darkTextSecondary),
        bodySmall: const TextStyle(color: AppColors.darkTextHint),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.darkSurface, // AppBar escura
        foregroundColor: AppColors.darkText,
      ),
      
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        margin: const EdgeInsets.only(bottom: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: AppColors.darkPrimary.withOpacity(0.5)),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppColors.darkBg, // Inputs mais escuros
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkAccent,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkAccent,
        unselectedItemColor: AppColors.darkTextHint,
        elevation: 5,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
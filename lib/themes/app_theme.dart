// lib/themes/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Classe que centraliza todas as cores usadas no aplicativo.
/// Facilita a manutenção e garante consistência visual.
class AppColors {
  // ===========================================================================
  // 1. PALETA DE IDENTIDADE VISUAL (Fixa)
  // ===========================================================================
  // Estas cores não mudam, independentemente do tema (Claro/Escuro).
  
  /// Roxo vibrante principal (Botões, Destaques, Ícones ativos).
  static const Color primaryPurple = Color(0xFF8C52FF); 
  
  /// Roxo secundário (Gradientes).
  static const Color secondaryPurple = Color(0xFF9D5CFF); 
  
  // Cores para os cartões do Dashboard (Estilo "ToDoDo")
  static const Color cardYellow = Color(0xFFFBC02D); // Amarelo
  static const Color cardOrange = Color(0xFFFF7043); // Laranja
  static const Color cardBlue = Color(0xFF42A5F5);   // Azul
  static const Color cardGreen = Color(0xFF66BB6A);  // Verde

  // ===========================================================================
  // 2. PALETA DO TEMA ESCURO (Dark Mode)
  // ===========================================================================
  
  /// Fundo principal escuro (quase preto).
  static const Color backgroundDark = Color(0xFF181818); 
  
  /// Cor de superfície (Cards, Modais) no modo escuro.
  static const Color surfaceDark = Color(0xFF2C2C2C);    
  
  /// Texto padrão no modo escuro.
  static const Color textWhite = Colors.white;
  
  /// Texto secundário (dicas, legendas) no modo escuro.
  static const Color textGreyDark = Colors.white54;

  // ===========================================================================
  // 3. PALETA DO TEMA CLARO (Light Mode)
  // ===========================================================================
  
  /// Fundo principal claro (Branco Puro).
  static const Color backgroundLight = Color(0xFFFFFFFF); 
  
  /// Cor de superfície (Cards) no modo claro (Cinza muito suave).
  static const Color surfaceLight = Color(0xFFF5F5F5);    
  
  /// Texto padrão no modo claro (Preto suave).
  static const Color textBlack = Color(0xFF121212);       
  
  /// Texto secundário no modo claro.
  static const Color textGreyLight = Color(0xFF757575);   
  
  // ===========================================================================
  // 4. CORES DE FEEDBACK (Erro/Sucesso)
  // ===========================================================================
  
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF66BB6A);

  // ===========================================================================
  // 5. ALIASES DE COMPATIBILIDADE
  // ===========================================================================
  // Estes getters permitem que o código antigo (que chamava AppColors.background)
  // continue funcionando sem quebrar. Por padrão, retornam as cores do tema ESCURO.
  // O ideal é migrar as telas para usar Theme.of(context) para serem dinâmicas.
  
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

/// Classe que define os temas (ThemeData) completos para o MaterialApp.
class AppTheme {
  
  // ===========================================================================
  // TEMA ESCURO (Dark Mode)
  // ===========================================================================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Cores principais
      scaffoldBackgroundColor: AppColors.backgroundDark,
      primaryColor: AppColors.primaryPurple,
      
      // Esquema de cores completo do Material 3
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryPurple,
        onPrimary: Colors.white,
        secondary: AppColors.secondaryPurple,
        surface: AppColors.surfaceDark,
        background: AppColors.backgroundDark,
        error: AppColors.error,
        onSurface: Colors.white, // Cor de texto/ícones sobre superfícies
      ),

      // Tipografia Global (Poppins)
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textWhite,
        displayColor: AppColors.textWhite,
      ),
      
      // Barra superior transparente
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20, 
          fontWeight: FontWeight.bold, 
          color: AppColors.textWhite
        ),
      ),

      // Barra de navegação inferior
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundDark,
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
      
      // Estilo padrão dos Botões
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        )
      ),
      
      // Estilo dos Campos de Texto (Inputs)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark, // Fundo cinza escuro
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.grey[600]),
        
        // Borda padrão (sem foco)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: BorderSide(color: Colors.grey.shade800)
        ),
        // Borda quando focado (Roxo)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: const BorderSide(color: AppColors.primaryPurple)
        ),
      ),
      
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  // ===========================================================================
  // TEMA CLARO (Light Mode)
  // ===========================================================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Cores principais
      scaffoldBackgroundColor: AppColors.backgroundLight, // Branco
      primaryColor: AppColors.primaryPurple,

      // Esquema de cores completo
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryPurple,
        onPrimary: Colors.white,
        secondary: AppColors.secondaryPurple,
        surface: AppColors.surfaceLight,
        background: AppColors.backgroundLight,
        error: AppColors.error,
        onSurface: AppColors.textBlack, // Texto preto sobre superfícies
      ),

      // Tipografia (Preta)
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: AppColors.textBlack,
        displayColor: AppColors.textBlack,
      ),

      // Barra superior
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textBlack),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20, 
          fontWeight: FontWeight.bold, 
          color: AppColors.textBlack
        ),
      ),

      // Barra de navegação inferior
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor: Colors.black26,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),

      // Botões (Iguais ao dark, mas sempre roxos)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        )
      ),

      // Campos de Texto (Inputs) - Adaptados para fundo branco
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white, // Fundo branco
        labelStyle: const TextStyle(color: Colors.black54),
        hintStyle: const TextStyle(color: Colors.black38),
        
        // Borda cinza clara
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: const BorderSide(color: Colors.black12)
        ),
        // Borda roxa no foco
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: const BorderSide(color: AppColors.primaryPurple)
        ),
      ),
      
      iconTheme: const IconThemeData(color: AppColors.textBlack),
    );
  }
}
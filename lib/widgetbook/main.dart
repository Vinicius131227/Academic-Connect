// lib/widgetbook/main.dart

import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Importações de Tema e Localização
import '../themes/app_theme.dart';
import '../l10n/app_localizations.dart';

// Importações dos Casos de Uso (Módulos)
import 'use_cases_auth.dart';
import 'use_cases_app.dart';

/// Função principal para rodar o Widgetbook.
/// Execute com: flutter run -t lib/widgetbook/main.dart -d chrome
void main() {
  runApp(const WidgetbookApp());
}

/// A classe principal do Widgetbook.
/// Configura o ambiente de teste visual (temas, dispositivos, localização).
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      // --- 1. ADDONS (Ferramentas Laterais) ---
      addons: [
        // Troca de Tema (Claro / Escuro)
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Claro', data: AppTheme.lightTheme),
            WidgetbookTheme(name: 'Escuro', data: AppTheme.darkTheme),
          ],
        ),

        // Troca de Idioma (PT / EN / ES)
        LocalizationAddon(
          locales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialLocale: const Locale('pt'),
        ),

        // Simulação de Dispositivos
        DeviceFrameAddon(
          devices: [
            Devices.ios.iPhone13,
            Devices.ios.iPadPro11Inches,
            Devices.android.samsungGalaxyS20,
            Devices.macOS.macBookPro,
          ],
        ),
        
        // Escala de Texto (Acessibilidade)
        TextScaleAddon(
          scales: [1.0, 1.5, 2.0],
        ),
      ],

      // --- 2. DIRETÓRIOS (Menu Lateral) ---
      directories: [
        // Categoria: Autenticação (Login, Cadastro...)
        WidgetbookCategory(
          name: 'Autenticação',
          children: authUseCases, // Importado de use_cases_auth.dart
        ),

        // Categoria: Aplicação Principal (Aluno, Prof, CA...)
        WidgetbookCategory(
          name: 'Aplicação',
          children: appUseCases, // Importado de use_cases_app.dart
        ),
      ],
    );
  }
}
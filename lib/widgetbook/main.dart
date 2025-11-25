// widgetbook/main.dart
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as anno;

// Importa os TEMAS REAIS do seu app
import 'package:ddm_projeto_final/themes/app_theme.dart';
// Importa as LOCALIZAÇÕES REAIS do seu app
import 'package:ddm_projeto_final/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Importa o arquivo que SERÁ GERADO pelo build_runner
import '../../widgetbook/main.directories.g.dart';

void main() {
  runApp(const WidgetbookApp());
}

@anno.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Temas estáticos para teste ---
    final teaTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B4513),
        brightness: Brightness.light,
      ),
      primaryColor: const Color(0xFF8B4513),
      scaffoldBackgroundColor: const Color(0xFFF5E6D3),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF8B4513),
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B4513),
          foregroundColor: Colors.white,
        ),
      ),
    );

    final purpleTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.purpleAccent,
        brightness: Brightness.light,
      ),
    );
    // ----------------------------------

    return Widgetbook.material(
      // 'directories' será gerado no próximo passo
      directories: directories,
      
      addons: [
        ViewportAddon(Viewports.all),
        InspectorAddon(),
        GridAddon(20),
        AlignmentAddon(),
        TextScaleAddon(scales: [1.0, 1.2, 2.0]),
        ZoomAddon(),

        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'App Claro', data: AppTheme.lightTheme),
            WidgetbookTheme(name: 'App Escuro', data: AppTheme.darkTheme),
            WidgetbookTheme(name: 'Tea', data: teaTheme),
            WidgetbookTheme(name: 'Purple', data: purpleTheme),
          ],
        ),

        // --- CORREÇÃO AQUI ---
        // API correta para Widgetbook 3.19+
        LocalizationAddon(
          locales: AppLocalizations.supportedLocales,
          initialLocale: AppLocalizations.supportedLocales.first,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
        // ---------------------
      ],
    );
  }
}
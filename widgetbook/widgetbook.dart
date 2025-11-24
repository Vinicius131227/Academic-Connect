import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as anno;

// Importa os TEMAS REAIS do seu app (para usá-los estaticamente)
import 'package:ddm_projeto_final/themes/app_theme.dart';
// Importa as LOCALIZAÇÕES REAIS do seu app (para usá-las estaticamente)
import 'package:ddm_projeto_final/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Importa o arquivo que SERÁ GERADO pelo build_runner
// (Ignore o erro "file not found" aqui por enquanto)
import 'main.directories.g.dart';

// 1. O main() simples para o Widgetbook
void main() {
  runApp(const WidgetbookApp());
}

// 2. A anotação @App que o build_runner procura
@anno.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Definindo os temas do seu exemplo ("Tea" e "Purple") ---
    final teaTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B4513), // Marrom
        brightness: Brightness.light,
      ),
      primaryColor: const Color(0xFF8B4513),
      scaffoldBackgroundColor: const Color(0xFFF5E6D3), // Creme
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
        seedColor: Colors.purpleAccent, // Roxo
        brightness: Brightness.light,
      ),
    );
    // --- Fim da definição dos temas ---

    // 3. Usamos a API Widgetbook.material
    return Widgetbook.material(
      // 'directories' será gerado no Passo 3
      directories: directories,
      
      // 4. Adicionamos os Addons
      addons: [
        // Addon de Localização (Obrigatório para o AppLocalizations)
        LocalizationAddon(
          // API correta para sua versão (v3.19.0)
          initialLocale: AppLocalizations.supportedLocales.first,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),

        // Addon de Tema (Mistura os temas do app com os do exemplo)
        MaterialThemeAddon(
          themes: [
            // Temas REAIS do seu App (pegos estaticamente)
            WidgetbookTheme(name: 'App Claro', data: AppTheme.lightTheme),
            WidgetbookTheme(name: 'App Escuro', data: AppTheme.darkTheme),
            
            // Temas do seu exemplo
            WidgetbookTheme(name: 'Tea', data: teaTheme),
            WidgetbookTheme(name: 'Purple', data: purpleTheme),
          ],
        ),

        // Addons visuais do seu exemplo
        ViewportAddon(Viewports.all),
        InspectorAddon(),
        GridAddon(20),
        AlignmentAddon(),
        TextScaleAddon(scales: [1.0, 1.2, 2.0]),
        ZoomAddon(),
      ],
    );
  }
}
// lib/widgetbook/main.dart

import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Imports do seu projeto
import '../themes/app_theme.dart';
import '../l10n/app_localizations.dart';

// Importa a lista de diretórios que criamos
import 'directories.dart';

void main() {
  runApp(const WidgetbookApp());
}

class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      // Passamos a lista de telas
      directories: directories,
      
      addons: [
        // 1. TEMA
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Claro', data: AppTheme.lightTheme),
            WidgetbookTheme(name: 'Escuro', data: AppTheme.darkTheme),
          ],
        ),

        // 2. LOCALIZAÇÃO (Correção do erro de Assert)
        LocalizationAddon(
          locales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Pega o primeiro idioma 'pt' da lista real gerada pelo Flutter
          initialLocale: AppLocalizations.supportedLocales.firstWhere(
            (loc) => loc.languageCode == 'pt',
            orElse: () => AppLocalizations.supportedLocales.first,
          ),
        ),

        // 3. DISPOSITIVO (Frame de celular)
        DeviceFrameAddon(
          devices: [
            Devices.ios.iPhone13,
            Devices.ios.iPadPro11Inches,
            Devices.android.samsungGalaxyS20,
          ],
          initialDevice: Devices.ios.iPhone13,
        ),
      ],
    );
  }
}
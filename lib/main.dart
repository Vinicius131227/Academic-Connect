import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'l10n/app_localizations.dart';
import 'themes/app_theme.dart';
import 'telas/login/portao_autenticacao.dart';
import 'telas/comum/tela_onboarding.dart';
import 'providers/provedor_localizacao.dart';
import 'providers/provedor_tema.dart';
import 'servico_preferencias.dart';
import 'providers/provedor_onboarding.dart';
import 'telas/comum/overlay_carregamento.dart';
import 'telas/comum/widget_carregamento.dart';

// --- Imports do Firebase (Corretos) ---
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- Inicializa o Firebase ---
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('pt_BR', null); 
  
  final servicoPreferencias = ServicoPreferencias();
  await servicoPreferencias.init();
  
  runApp(
    ProviderScope(
      overrides: [
        provedorPreferencias.overrideWithValue(servicoPreferencias),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(provedorBrightness);
    final locale = ref.watch(provedorLocalizacao); 
    final isFirstLaunch = ref.watch(provedorOnboarding);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Academic Connect',
      theme: AppTheme.lightTheme, 
      darkTheme: AppTheme.darkTheme, 
      themeMode: themeMode,
      
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      
      builder: (context, child) {
        return OverlayCarregamento(
          child: child ?? const TelaCarregamento(),
        );
      },
      
      home: isFirstLaunch ? const TelaOnboarding() : const PortaoAutenticacao(),
    );
  }
}
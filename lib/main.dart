import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Certifique-se de que este arquivo existe (gerado pelo flutterfire configure)
import 'telas/login/portao_autenticacao.dart';
import 'servico_preferencias.dart';
import 'themes/app_theme.dart';
import 'providers/provedor_tema.dart';
import 'providers/provedor_localizacao.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicializa o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Inicializa as Preferências (Tema, Idioma, Onboarding)
  final prefs = ServicoPreferencias();
  await prefs.init();

  // 3. Inicia o App com o Escopo do Riverpod
  runApp(
    ProviderScope(
      overrides: [
        // Injeta a instância de preferências carregada
        provedorPreferencias.overrideWithValue(prefs),
      ],
      child: const AcademicConnectApp(),
    ),
  );
}

class AcademicConnectApp extends ConsumerWidget {
  const AcademicConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ouve as mudanças de estado (Tema e Idioma)
    final modoTema = ref.watch(provedorNotificadorTema);
    final locale = ref.watch(provedorLocalizacao);

    return MaterialApp(
      title: 'Academic Connect',
      debugShowCheckedModeBanner: false,
      
      // --- CONFIGURAÇÃO DE TEMA ---
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: modoTema == ModoSistemaTema.claro 
          ? ThemeMode.light 
          : (modoTema == ModoSistemaTema.escuro ? ThemeMode.dark : ThemeMode.system),

      // --- CONFIGURAÇÃO DE IDIOMA ---
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // --- TELA INICIAL (Portão decide se vai p/ Login ou Home) ---
      home: const PortaoAutenticacao(),
    );
  }
}
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Configuração gerada pelo FlutterFire CLI
import 'telas/login/portao_autenticacao.dart';
import 'services/servico_preferencias.dart';
import 'themes/app_theme.dart';
import 'providers/provedor_tema.dart';
import 'providers/provedor_localizacao.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Função principal que inicia a execução do aplicativo.
void main() async {
  // Garante que a engine do Flutter esteja pronta antes de executar código assíncrono
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicializa a conexão com o Firebase (Banco de Dados e Auth)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Inicializa o serviço de Preferências (Carrega tema/língua salvos)
  final prefs = ServicoPreferencias();
  await prefs.init();

  // 3. Inicia o App dentro do escopo do Riverpod (Gerenciamento de Estado)
  runApp(
    ProviderScope(
      overrides: [
        // Injeta a instância de 'prefs' já inicializada no provedor.
        // Isso substitui o 'UnimplementedError' definido no arquivo do serviço.
        provedorPreferencias.overrideWithValue(prefs),
      ],
      child: const AcademicConnectApp(),
    ),
  );
}

/// Widget raiz da aplicação.
/// Configura o roteamento, temas e internacionalização.
class AcademicConnectApp extends ConsumerWidget {
  const AcademicConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 'Observa' (watch) os provedores de estado. 
    // Se o tema ou a língua mudarem, este widget é reconstruído automaticamente.
    final modoTema = ref.watch(provedorNotificadorTema);
    final locale = ref.watch(provedorLocalizacao);

    return MaterialApp(
      title: 'Academic Connect',
      debugShowCheckedModeBanner: false, // Remove a faixa "Debug" no canto
      
      // --- CONFIGURAÇÃO DE TEMA (Aparência) ---
      theme: AppTheme.lightTheme, // Tema Claro definido em app_theme.dart
      darkTheme: AppTheme.darkTheme, // Tema Escuro definido em app_theme.dart
      
      // Define qual tema usar com base na preferência do usuário
      themeMode: modoTema == ModoSistemaTema.claro 
          ? ThemeMode.light 
          : (modoTema == ModoSistemaTema.escuro ? ThemeMode.dark : ThemeMode.system),

      // --- CONFIGURAÇÃO DE IDIOMA (i18n) ---
      locale: locale, // Idioma atual selecionado
      supportedLocales: AppLocalizations.supportedLocales, // Lista: pt, en, es
      
      // Delegados que ensinam o Flutter a traduzir os widgets padrões (datas, botões, etc)
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // --- TELA INICIAL ---
      // O PortaoAutenticacao decide se mostra o Login, a Home ou o Onboarding
      home: const PortaoAutenticacao(),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../comum/tela_configuracoes.dart';
import 'aba_inicio_ca.dart';
import 'aba_perfil_ca.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';

class TelaPrincipalCAProjeto extends ConsumerStatefulWidget {
  const TelaPrincipalCAProjeto({super.key});

  @override
  ConsumerState<TelaPrincipalCAProjeto> createState() => _TelaPrincipalCAProjetoState();
}

class _TelaPrincipalCAProjetoState extends ConsumerState<TelaPrincipalCAProjeto> {
  int _indiceAtual = 0;

  // Lista de Abas
  final List<Widget> _telas = [
    const AbaInicioCA(), // Dashboard com Estatísticas e Ações
    const AbaPerfilCA(), // Perfil e Configurações
  ];

  void _onTabTapped(int index) {
    setState(() {
      _indiceAtual = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    // Títulos dinâmicos para a AppBar
    final List<String> _titulos = [
      t.t('ca_titulo'),    // Portal C.A.
      t.t('perfil_titulo'), // Perfil
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      
      // AppBar Transparente com Configurações
      appBar: AppBar(
        title: Text(
          _titulos[_indiceAtual],
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: textColor?.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.settings_outlined, color: textColor),
              tooltip: t.t('config_titulo'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const TelaConfiguracoes()),
                );
              },
            ),
          ),
        ],
      ),
      
      // Corpo com preservação de estado
      body: IndexedStack(
        index: _indiceAtual,
        children: _telas,
      ),
      
      // Barra de Navegação Minimalista
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: textColor?.withOpacity(0.1) ?? Colors.transparent, width: 1)
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _indiceAtual,
          onTap: _onTabTapped,
          backgroundColor: theme.scaffoldBackgroundColor,
          selectedItemColor: AppColors.primaryPurple,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false, // Estilo limpo (sem texto)
          showUnselectedLabels: false,
          iconSize: 28,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard),
              label: t.t('nav_inicio'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: t.t('perfil_titulo'),
            ),
          ],
        ),
      ),
    );
  }
}
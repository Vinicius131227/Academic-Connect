// lib/telas/professor/tela_principal_professor.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações das abas
import 'aba_inicio_professor.dart';
import 'aba_turmas_professor.dart';
import 'aba_perfil_professor.dart';

// Importações de configuração
import '../comum/tela_configuracoes.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Principal Professor',
  type: TelaPrincipalProfessor,
)
Widget buildTelaPrincipalProfessor(BuildContext context) {
  return const ProviderScope(
    child: TelaPrincipalProfessor(),
  );
}

/// Tela Principal ("Shell") do Professor.
/// Contém a BottomNavigationBar e gerencia a troca de abas.
class TelaPrincipalProfessor extends ConsumerStatefulWidget {
  const TelaPrincipalProfessor({super.key});

  @override
  ConsumerState<TelaPrincipalProfessor> createState() => _TelaPrincipalProfessorState();
}

class _TelaPrincipalProfessorState extends ConsumerState<TelaPrincipalProfessor> {
  int _indiceAtual = 0;

  /// Método para trocar de aba programaticamente (usado pelos atalhos da Home).
  void _navegarParaAba(int index) {
    setState(() {
      _indiceAtual = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final isDark = theme.brightness == Brightness.dark;

    // Lista de telas (Lazy loading via IndexedStack é gerenciado no body)
    final List<Widget> telas = [
      AbaInicioProfessor(onNavigateToTab: _navegarParaAba), // Passa o callback
      const AbaTurmasProfessor(),
      const AbaPerfilProfessor(),
    ];

    // Títulos da AppBar
    final List<String> titulos = [
      t.t('prof_titulo'),        // "Portal do Professor"
      t.t('prof_turmas_titulo'), // "Minhas Turmas"
      t.t('perfil_titulo'),      // "Perfil"
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      
      // AppBar com Configurações
      appBar: AppBar(
        title: Text(
          titulos[_indiceAtual],
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor),
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

      // Corpo
      body: IndexedStack(
        index: _indiceAtual,
        children: telas,
      ),

      // Barra de Navegação
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
        ),
        child: BottomNavigationBar(
          currentIndex: _indiceAtual,
          onTap: _navegarParaAba,
          backgroundColor: theme.scaffoldBackgroundColor,
          selectedItemColor: AppColors.primaryPurple,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: t.t('nav_inicio'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.class_outlined),
              activeIcon: const Icon(Icons.class_),
              label: t.t('nav_turmas'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: t.t('nav_perfil'),
            ),
          ],
        ),
      ),
    );
  }
}
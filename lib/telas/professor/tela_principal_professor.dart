// lib/telas/professor/tela_principal_professor.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../comum/tela_configuracoes.dart';
import 'aba_inicio_professor.dart';
import 'aba_turmas_professor.dart';
import 'aba_solicitacoes_professor.dart';
import '../../l10n/app_localizations.dart'; // Importa i18n

class TelaPrincipalProfessor extends ConsumerStatefulWidget {
  const TelaPrincipalProfessor({super.key});

  @override
  ConsumerState<TelaPrincipalProfessor> createState() => _TelaPrincipalProfessorState();
}

class _TelaPrincipalProfessorState extends ConsumerState<TelaPrincipalProfessor> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Atualiza a UI para trocar o título
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navegarParaAba(int index) {
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    // Títulos (traduzidos)
    final List<String> _titulos = [
      t.t('prof_titulo'),
      t.t('prof_turmas_titulo'),
      t.t('prof_solicitacoes_titulo'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_tabController.index]), // Título dinâmico
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: t.t('config_titulo'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TelaConfiguracoes()),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AbaInicioProfessor(onNavigateToTab: _navegarParaAba),
          const AbaTurmasProfessor(),
          const AbaSolicitacoesProfessor(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabController.index,
        onTap: _navegarParaAba,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: t.t('aluno_inicio_titulo'), // Reusa a tradução "Início"
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book_outlined),
            activeIcon: const Icon(Icons.book),
            label: t.t('prof_turmas_titulo'), // "Turmas"
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inbox_outlined),
            activeIcon: const Icon(Icons.inbox),
            label: t.t('prof_solicitacoes_titulo'), // "Solicitações"
          ),
        ],
      ),
    );
  }
}
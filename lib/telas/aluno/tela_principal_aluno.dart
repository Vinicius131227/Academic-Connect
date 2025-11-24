// lib/telas/aluno/tela_principal_aluno.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../comum/tela_configuracoes.dart';
import 'aba_inicio_aluno.dart';
import 'aba_disciplinas_aluno.dart';
import 'aba_perfil_aluno.dart';
// REMOVIDO: import 'tela_artigos_recentes.dart'; 
import '../../l10n/app_localizations.dart'; 

class TelaPrincipalAluno extends ConsumerStatefulWidget {
  const TelaPrincipalAluno({super.key});

  @override
  ConsumerState<TelaPrincipalAluno> createState() => _TelaPrincipalAlunoState();
}

class _TelaPrincipalAlunoState extends ConsumerState<TelaPrincipalAluno> {
  int _indiceAtual = 0; 

  // Lista de telas para o IndexedStack (AGORA SÃO 3)
  final List<Widget> _telas = [
    const AbaInicioAluno(),
    const AbaDisciplinasAluno(),
    const AbaPerfilAluno(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    // Títulos para a AppBar
    final List<String> _titulos = [
      t.t('aluno_inicio_titulo'),
      t.t('aluno_disciplinas_titulo'),
      t.t('aluno_perfil_titulo'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_indiceAtual]), 
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
      
      // IndexedStack preserva o estado de cada aba
      body: IndexedStack(
        index: _indiceAtual,
        children: _telas,
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: (index) => setState(() => _indiceAtual = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: t.t('aluno_inicio_titulo'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book_outlined),
            activeIcon: const Icon(Icons.book),
            label: t.t('aluno_disciplinas_titulo'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: t.t('aluno_perfil_titulo'),
          ),
        ],
      ),
    );
  }
}
// lib/telas/professor/tela_principal_professor.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../comum/tela_configuracoes.dart';
import 'aba_inicio_professor.dart';
import 'aba_turmas_professor.dart';
import 'aba_perfil_professor.dart'; // IMPORTANTE
import '../../l10n/app_localizations.dart';

class TelaPrincipalProfessor extends ConsumerStatefulWidget {
  const TelaPrincipalProfessor({super.key});

  @override
  ConsumerState<TelaPrincipalProfessor> createState() => _TelaPrincipalProfessorState();
}

class _TelaPrincipalProfessorState extends ConsumerState<TelaPrincipalProfessor> with SingleTickerProviderStateMixin {
  int _indiceAtual = 0;

  void _navegarParaAba(int index) {
    setState(() {
      _indiceAtual = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // LISTA DE TELAS ATUALIZADA
    final List<Widget> _telas = [
      AbaInicioProfessor(onNavigateToTab: _navegarParaAba),
      const AbaTurmasProfessor(),
      const AbaPerfilProfessor(), // Perfil novo
    ];

    final List<String> _titulos = [
      t.t('prof_titulo'),
      t.t('prof_turmas_titulo'),
      t.t('perfil_titulo'),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _indiceAtual,
        children: _telas,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: _navegarParaAba,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: t.t('aluno_inicio_titulo'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book_outlined),
            activeIcon: const Icon(Icons.book),
            label: t.t('prof_turmas_titulo'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: t.t('perfil_titulo'),
          ),
        ],
      ),
    );
  }
}
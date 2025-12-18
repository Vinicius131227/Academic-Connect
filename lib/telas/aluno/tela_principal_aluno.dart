import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/servico_preferencias.dart';
import '../../themes/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'aba_inicio_aluno.dart';
import 'aba_disciplinas_aluno.dart';
import 'aba_perfil_aluno.dart';
import '../comum/tela_configuracoes.dart';

class TelaPrincipalAluno extends ConsumerStatefulWidget {
  const TelaPrincipalAluno({super.key});

  @override
  ConsumerState<TelaPrincipalAluno> createState() => _TelaPrincipalAlunoState();
}

class _TelaPrincipalAlunoState extends ConsumerState<TelaPrincipalAluno> {
  int _indiceAtual = 0;

  // Lista das telas que compõem as abas
  final List<Widget> _telas = [
    const AbaInicioAluno(),
    const AbaDisciplinasAluno(),
    const AbaPerfilAluno(),
  ];

  @override
  void initState() {
    super.initState();
    _carregarAbaSalva();
  }

  Future<void> _carregarAbaSalva() async {
    final prefs = ref.read(provedorPreferencias);
    final indiceSalvo = prefs.carregarUltimaAba('aluno');
    if (indiceSalvo >= 0 && indiceSalvo < _telas.length) {
      setState(() {
        _indiceAtual = indiceSalvo;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _indiceAtual = index;
    });
    ref.read(provedorPreferencias).salvarUltimaAba(index, 'aluno');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<String> titulos = [
      t.t('aluno_inicio_titulo'),
      t.t('aluno_disciplinas_titulo'),
      t.t('aluno_perfil_titulo'),
    ];

    return Scaffold(
      // AppBar Comum para todas as abas
      appBar: AppBar(
        title: Text(titulos[_indiceAtual]),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
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
      
      // Corpo que muda conforme a aba
      body: IndexedStack(
        index: _indiceAtual,
        children: _telas,
      ),
      
      // Menu Inferior
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _indiceAtual,
          onTap: _onTabTapped,
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          selectedItemColor: AppColors.primaryPurple, // Usa a cor do tema
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
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
      ),
    );
  }
}
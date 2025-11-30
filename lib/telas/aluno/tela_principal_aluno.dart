// lib/telas/aluno/tela_principal_aluno.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/servico_preferencias.dart'; 
import '../comum/tela_configuracoes.dart';
import 'aba_inicio_aluno.dart';
import 'aba_disciplinas_aluno.dart';
import 'aba_perfil_aluno.dart';
import '../../l10n/app_localizations.dart'; 

// NÃO IMPORTE O APP_THEME AQUI SE NÃO FOR USAR EXPLICITAMENTE AS CORES.
// A CLASSE ABA_INICIO_ALUNO JÁ IMPORTA.
// SE PRECISAR DE CORES AQUI, CERTIFIQUE-SE DE QUE NENHUM OUTRO ARQUIVO NESTA TELA
// ESTEJA DEFININDO 'AppColors' TAMBÉM.

class TelaPrincipalAluno extends ConsumerStatefulWidget {
  const TelaPrincipalAluno({super.key});

  @override
  ConsumerState<TelaPrincipalAluno> createState() => _TelaPrincipalAlunoState();
}

class _TelaPrincipalAlunoState extends ConsumerState<TelaPrincipalAluno> {
  int _indiceAtual = 0; 

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
    
    final List<String> _titulos = [
      t.t('aluno_inicio_titulo'),
      t.t('aluno_disciplinas_titulo'),
      t.t('aluno_perfil_titulo'),
    ];

    return Scaffold(
      // AppBar padrão removida/transparente pois as abas têm seus próprios cabeçalhos
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
      
      body: IndexedStack(
        index: _indiceAtual,
        children: _telas,
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: _onTabTapped, 
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
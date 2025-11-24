import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../comum/tela_configuracoes.dart';
import 'aba_inicio_ca.dart';
import 'aba_eventos_ca.dart';
import '../../l10n/app_localizations.dart'; 

class TelaPrincipalCAProjeto extends ConsumerStatefulWidget {
  const TelaPrincipalCAProjeto({super.key});

  @override
  ConsumerState<TelaPrincipalCAProjeto> createState() => _TelaPrincipalCAProjetoState();
}

class _TelaPrincipalCAProjetoState extends ConsumerState<TelaPrincipalCAProjeto> {
  int _indiceAtual = 0; 

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    // --- ATUALIZADO: Usa chaves de tradução existentes ---
    final List<String> _titulos = [
      t.t('aluno_inicio_titulo'), // "Início"
      t.t('ca_eventos_titulo'),   // "Eventos"
    ];
    // --- FIM ATUALIZAÇÃO ---

    final List<Widget> _telas = [
      const AbaInicioCA(), 
      const AbaEventosCA(), 
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
          )
        ],
      ),
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
            label: t.t('aluno_inicio_titulo'), // Reusa "Início"
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.event_outlined),
            activeIcon: const Icon(Icons.event),
            label: t.t('ca_eventos_titulo'), // "Eventos"
          ),
        ],
      ),
    );
  }
}
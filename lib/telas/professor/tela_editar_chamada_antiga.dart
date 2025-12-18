// lib/telas/professor/tela_editar_chamada_antiga.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../../models/turma_professor.dart';
import '../../services/servico_firestore.dart';
import '../../models/aluno_chamada.dart';
import '../../l10n/app_localizations.dart';

@UseCase(
  name: 'Editar Chamada Antiga',
  type: TelaEditarChamadaAntiga,
)
Widget buildTelaEditarChamadaAntiga(BuildContext context) {
  return ProviderScope(
    child: TelaEditarChamadaAntiga(
      turma: TurmaProfessor(
        id: 'mock', nome: 'Turma Teste', horario: '', local: '', professorId: '', turmaCode: '', creditos: 4, alunosInscritos: []
      ),
      dataId: '2025-10-25'
    ),
  );
}

class TelaEditarChamadaAntiga extends ConsumerStatefulWidget {
  final TurmaProfessor turma;
  final String dataId; 
  
  const TelaEditarChamadaAntiga({
    super.key, 
    required this.turma, 
    required this.dataId
  });

  @override
  ConsumerState<TelaEditarChamadaAntiga> createState() => _TelaEditarChamadaAntigaState();
}

class _TelaEditarChamadaAntigaState extends ConsumerState<TelaEditarChamadaAntiga> {
  List<AlunoChamada> _alunos = [];
  bool _loading = true;
  String? _erro; // Para mostrar erro na tela se falhar
  
  List<String> _presentesInicio = [];
  List<String> _presentesFim = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final servico = ref.read(servicoFirestoreProvider);
      
      // 1. Busca alunos
      final alunosBase = await servico.getAlunosDaTurma(widget.turma.id);
      
      // 2. Busca chamada (pode retornar mapa vazio se não existir)
      final dadosChamada = await servico.getDadosChamada(widget.turma.id, widget.dataId);
      
      if (mounted) {
        setState(() {
          _presentesInicio = List<String>.from(dadosChamada['presentes_inicio'] ?? []);
          _presentesFim = List<String>.from(dadosChamada['presentes_fim'] ?? []);
          _alunos = alunosBase;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = e.toString();
          _loading = false; // Para de carregar mesmo com erro
        });
      }
    }
  }

  Future<void> _salvar() async {
    final t = AppLocalizations.of(context)!;
    try {
      await ref.read(servicoFirestoreProvider).atualizarChamadaHistorico(
        widget.turma.id, 
        widget.dataId, 
        _presentesInicio, 
        _presentesFim
      );
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('sucesso')), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // Se estiver carregando
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Se deu erro
    if (_erro != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Erro")),
        body: Center(child: Text("Falha ao carregar: $_erro")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("${t.t('prof_editar_turma')}: ${widget.dataId}")),
      body: _alunos.isEmpty 
        ? const Center(child: Text("Nenhum aluno encontrado."))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _alunos.length,
            itemBuilder: (ctx, i) {
              final aluno = _alunos[i];
              final estaPresenteInicio = _presentesInicio.contains(aluno.id);
              final estaPresenteFim = _presentesFim.contains(aluno.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(aluno.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("RA: ${aluno.ra}"),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          FilterChip(
                            label: Text(t.t('prof_chamada_tipo_inicio')),
                            selected: estaPresenteInicio,
                            selectedColor: Colors.green.withOpacity(0.3),
                            onSelected: (val) {
                              setState(() {
                                val ? _presentesInicio.add(aluno.id) : _presentesInicio.remove(aluno.id);
                              });
                            },
                          ),
                          FilterChip(
                            label: Text(t.t('prof_chamada_tipo_fim')),
                            selected: estaPresenteFim,
                            selectedColor: Colors.green.withOpacity(0.3),
                            onSelected: (val) {
                              setState(() {
                                val ? _presentesFim.add(aluno.id) : _presentesFim.remove(aluno.id);
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _salvar,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.save, color: Colors.white),
        label: Text(t.t('salvar'), style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
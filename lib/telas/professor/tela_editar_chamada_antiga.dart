// lib/telas/professor/tela_editar_chamada_antiga.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/turma_professor.dart';
import '../../services/servico_firestore.dart';
import '../../models/aluno_chamada.dart';

class TelaEditarChamadaAntiga extends ConsumerStatefulWidget {
  final TurmaProfessor turma;
  final String dataId;
  const TelaEditarChamadaAntiga({super.key, required this.turma, required this.dataId});

  @override
  ConsumerState<TelaEditarChamadaAntiga> createState() => _TelaEditarChamadaAntigaState();
}

class _TelaEditarChamadaAntigaState extends ConsumerState<TelaEditarChamadaAntiga> {
  List<AlunoChamada> _alunos = [];
  bool _loading = true;
  List<String> _presentesInicio = [];
  List<String> _presentesFim = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final servico = ref.read(servicoFirestoreProvider);
    final alunosBase = await servico.getAlunosDaTurma(widget.turma.id);
    final dadosChamada = await servico.getDadosChamada(widget.turma.id, widget.dataId);
    
    if (mounted) {
      setState(() {
        _presentesInicio = List<String>.from(dadosChamada['presentes_inicio'] ?? []);
        _presentesFim = List<String>.from(dadosChamada['presentes_fim'] ?? []);
        _alunos = alunosBase;
        _loading = false;
      });
    }
  }

  Future<void> _salvar() async {
    await ref.read(servicoFirestoreProvider).atualizarChamadaHistorico(
      widget.turma.id, 
      widget.dataId, 
      _presentesInicio, 
      _presentesFim
    );
    if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chamada atualizada!")));
        Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text("Editando: ${widget.dataId}")),
      body: ListView.builder(
        itemCount: _alunos.length,
        itemBuilder: (ctx, i) {
          final aluno = _alunos[i];
          final estaPresenteInicio = _presentesInicio.contains(aluno.id);
          final estaPresenteFim = _presentesFim.contains(aluno.id);

          return Card(
            child: Column(
              children: [
                ListTile(title: Text(aluno.nome), subtitle: Text(aluno.ra)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    FilterChip(
                      label: const Text("Início"),
                      selected: estaPresenteInicio,
                      onSelected: (val) {
                        setState(() {
                          val ? _presentesInicio.add(aluno.id) : _presentesInicio.remove(aluno.id);
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text("Fim"),
                      selected: estaPresenteFim,
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _salvar,
        icon: const Icon(Icons.save),
        label: const Text("Salvar Alterações"),
      ),
    );
  }
}
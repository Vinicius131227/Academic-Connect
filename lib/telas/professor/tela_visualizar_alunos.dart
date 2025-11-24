// lib/telas/professor/tela_visualizar_alunos.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/turma_professor.dart';
import '../../models/aluno_chamada.dart';
import '../../services/servico_firestore.dart';
import '../comum/widget_carregamento.dart';

class TelaVisualizarAlunos extends ConsumerStatefulWidget {
  final TurmaProfessor turma;
  const TelaVisualizarAlunos({super.key, required this.turma});

  @override
  ConsumerState<TelaVisualizarAlunos> createState() => _TelaVisualizarAlunosState();
}

class _TelaVisualizarAlunosState extends ConsumerState<TelaVisualizarAlunos> {
  Future<List<AlunoChamada>>? _futureAlunos;

  @override
  void initState() {
    super.initState();
    _carregarAlunos();
  }

  void _carregarAlunos() {
    setState(() {
      _futureAlunos = ref.read(servicoFirestoreProvider).getAlunosDaTurma(widget.turma.id);
    });
  }

  void _removerAluno(String alunoId, String nome) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remover Aluno"),
        content: Text("Tem certeza que deseja remover $nome desta turma?"),
        actions: [
          TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Remover"),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(servicoFirestoreProvider).removerAlunoDaTurma(widget.turma.id, alunoId);
              _carregarAlunos(); // Recarrega a lista
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aluno removido.")));
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alunos Inscritos")),
      body: FutureBuilder<List<AlunoChamada>>(
        future: _futureAlunos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const WidgetCarregamento(texto: "Buscando alunos...");
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erro: ${snapshot.error}"));
          }
          final alunos = snapshot.data ?? [];
          
          if (alunos.isEmpty) {
            return const Center(child: Text("Nenhum aluno inscrito nesta turma."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alunos.length,
            itemBuilder: (context, index) {
              final aluno = alunos[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(aluno.nome[0])),
                  title: Text(aluno.nome),
                  subtitle: Text("RA: ${aluno.ra}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.person_remove, color: Colors.red),
                    onPressed: () => _removerAluno(aluno.id, aluno.nome),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../../models/turma_professor.dart';
import '../../models/aluno_chamada.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../comum/widget_carregamento.dart';
import '../../themes/app_theme.dart';

@UseCase(name: 'Ver Alunos', type: TelaVisualizarAlunos)
Widget buildTelaVisualizarAlunos(BuildContext context) {
  return const ProviderScope(child: Scaffold(body: Center(child: Text("Mock"))));
}

// Provider para buscar a lista combinada (Reais + Pré-cadastrados)
final listaAlunosProvider = FutureProvider.family<List<AlunoChamada>, String>((ref, turmaId) {
  return ref.watch(servicoFirestoreProvider).getAlunosDaTurma(turmaId);
});

class TelaVisualizarAlunos extends ConsumerWidget {
  final TurmaProfessor turma;
  const TelaVisualizarAlunos({super.key, required this.turma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final asyncAlunos = ref.watch(listaAlunosProvider(turma.id));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.t('prof_ver_alunos'), style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        iconTheme: IconThemeData(color: theme.textTheme.bodyLarge?.color),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: asyncAlunos.when(
        loading: () => const WidgetCarregamento(),
        error: (e, s) => Center(child: Text("${t.t('erro_generico')}: $e")),
        data: (alunos) {
          if (alunos.isEmpty) {
            return const Center(child: Text("Nenhum aluno nesta turma."));
          }

          // Separa contagem para exibir no topo
          // O ID dos alunos da planilha começa com "pre_" (definimos isso no serviço)
          final total = alunos.length;
          final pendentes = alunos.where((a) => a.id.startsWith('pre_')).length;

          return Column(
            children: [
              // Painel de Estatísticas
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCounter("Total", total.toString(), Colors.blue),
                    _buildCounter("Ativos", (total - pendentes).toString(), Colors.green),
                    _buildCounter("Pendentes", pendentes.toString(), Colors.orange),
                  ],
                ),
              ),
              const Divider(),
              
              // Lista de Alunos
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alunos.length,
                  itemBuilder: (context, index) {
                    final aluno = alunos[index];
                    final isPendente = aluno.id.startsWith('pre_');

                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPendente ? Colors.orange.withOpacity(0.2) : AppColors.primaryPurple.withOpacity(0.2),
                          child: Icon(
                            isPendente ? Icons.hourglass_empty : Icons.check_circle, 
                            color: isPendente ? Colors.orange : AppColors.primaryPurple,
                            size: 20,
                          ),
                        ),
                        title: Text(aluno.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          isPendente ? t.t('prof_aluno_pendente') : "${t.t('prof_aluno_regular')} • ${aluno.ra}",
                          style: TextStyle(
                            color: isPendente ? Colors.orange : null,
                            fontSize: 12
                          ),
                        ),
                        // Se for pendente, mostra ícone de alerta
                        trailing: isPendente 
                          ? Tooltip(
                              message: "Aluno importado, aguardando cadastro no App",
                              child: Icon(Icons.info_outline, color: Colors.orange.withOpacity(0.5)),
                            )
                          : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCounter(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
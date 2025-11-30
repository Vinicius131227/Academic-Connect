// lib/telas/professor/tela_visualizar_alunos.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/turma_professor.dart';
import '../../models/aluno_chamada.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../comum/widget_carregamento.dart';

/// Caso de uso para o Widgetbook.
/// Simula a tela de visualização de alunos de uma turma.
@UseCase(
  name: 'Visualizar Alunos',
  type: TelaVisualizarAlunos,
)
Widget buildTelaVisualizarAlunos(BuildContext context) {
  return ProviderScope(
    child: TelaVisualizarAlunos(
      turma: TurmaProfessor(
        id: 'mock_id',
        nome: 'Física 1',
        horario: 'Seg 08:00',
        local: 'Sala 10',
        professorId: 'prof_id',
        turmaCode: 'A1B2C3',
        creditos: 4,
        alunosInscritos: [],
      ),
    ),
  );
}

/// Provedor que busca a lista de alunos de uma turma específica.
final alunosTurmaProvider = FutureProvider.family<List<AlunoChamada>, String>((ref, turmaId) async {
  return ref.read(servicoFirestoreProvider).getAlunosDaTurma(turmaId);
});

/// Tela que exibe a lista de alunos inscritos na disciplina.
/// Permite ao professor ter uma visão geral da classe.
class TelaVisualizarAlunos extends ConsumerWidget {
  final TurmaProfessor turma;
  
  const TelaVisualizarAlunos({super.key, required this.turma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    // Busca os dados
    final asyncAlunos = ref.watch(alunosTurmaProvider(turma.id));
    
    // Tema
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t.t('prof_ver_alunos'), // "Ver Alunos"
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: asyncAlunos.when(
        loading: () => const WidgetCarregamento(texto: "Carregando lista..."),
        error: (e, s) => Center(child: Text("${t.t('erro_generico')}: $e")),
        data: (alunos) {
          if (alunos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    "Nenhum aluno inscrito nesta turma.", // Fallback se não houver tradução específica
                    style: TextStyle(color: textColor?.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    "${t.t('criar_turma_codigo_desc')} ${turma.turmaCode}",
                    style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alunos.length,
            itemBuilder: (context, index) {
              final aluno = alunos[index];
              return Card(
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
                    child: Text(
                      aluno.nome.isNotEmpty ? aluno.nome[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(aluno.nome, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  subtitle: Text("${t.t('cadastro_ra_label')}: ${aluno.ra}", style: TextStyle(color: textColor?.withOpacity(0.7))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
// lib/telas/aluno/aba_disciplinas_aluno.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provedores_app.dart';
import '../../models/turma_professor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/servico_firestore.dart'; 
import 'tela_entrar_turma.dart';
import 'tela_detalhes_disciplina_aluno.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import 'package:google_fonts/google_fonts.dart'; // Import

final aulasStreamProvider = StreamProvider.family<QuerySnapshot, String>((ref, turmaId) {
  final servico = ref.watch(servicoFirestoreProvider);
  return servico.getAulasStream(turmaId);
});

class AbaDisciplinasAluno extends ConsumerWidget {
  const AbaDisciplinasAluno({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTurmas = ref.watch(provedorStreamTurmasAluno);
    final theme = Theme.of(context); // Pega o tema atual (Claro ou Escuro)
    final textColor = theme.textTheme.bodyLarge?.color; // Cor do texto dinâmica

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Fundo dinâmico
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              child: Text(
                "Minhas\nDisciplinas",
                style: GoogleFonts.poppins( // Fonte corrigida
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textColor, // Cor dinâmica
                  height: 1.1
                ),
              ),
            ),
          ),
          
          asyncTurmas.when(
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (turmas) {
              if (turmas.isEmpty) {
                return SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Text("Sem disciplinas.", style: TextStyle(color: textColor?.withOpacity(0.6))),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaEntrarTurma())),
                        child: const Text("Entrar em uma turma"),
                      )
                    ],
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final turma = turmas[index];
                      final colors = [
                        AppColors.cardBlue,
                        AppColors.cardGreen,
                        AppColors.cardOrange,
                        AppColors.secondaryPurple,
                      ];
                      final color = colors[index % colors.length];

                      return _CardDisciplinaSolid(turma: turma, color: color);
                    },
                    childCount: turmas.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryPurple,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaEntrarTurma()));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CardDisciplinaSolid extends StatelessWidget {
  final TurmaProfessor turma;
  final Color color;

  const _CardDisciplinaSolid({required this.turma, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TelaDetalhesDisciplinaAluno(turma: turma)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
          ]
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  turma.nome,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  turma.horario.split(',')[0], 
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
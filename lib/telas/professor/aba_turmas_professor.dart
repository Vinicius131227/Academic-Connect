import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/turma_professor.dart';
import '../../providers/provedores_app.dart';
import '../comum/widget_carregamento.dart';
import 'tela_criar_turma.dart';
import 'tela_detalhes_disciplina_prof.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AbaTurmasProfessor extends ConsumerWidget {
  const AbaTurmasProfessor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final asyncTurmas = ref.watch(provedorStreamTurmasProfessor);
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // CORRIGIDO
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.t('prof_turmas_titulo'), // Traduzido
                    style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: textColor, height: 1.0),
                  ),
                ],
              ),
            ),
          ),

          asyncTurmas.when(
            loading: () => const SliverToBoxAdapter(child: WidgetCarregamento()),
            error: (e, st) => SliverToBoxAdapter(child: Center(child: Text('Erro: $e'))),
            data: (turmas) {
              if (turmas.isEmpty) {
                return SliverToBoxAdapter(child: Center(child: Text("Nenhuma turma criada.", style: TextStyle(color: textColor))));
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final turma = turmas[index];
                      // Cores SÓLIDAS (sem degradê)
                      final colors = [
                         AppColors.cardBlue,
                         AppColors.cardOrange,
                         AppColors.cardGreen,
                         AppColors.secondaryPurple,
                      ];
                      final color = colors[index % colors.length];

                      return _CardTurmaProfGrid(turma: turma, color: color);
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
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaCriarTurma())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CardTurmaProfGrid extends StatelessWidget {
  final TurmaProfessor turma;
  final Color color;

  const _CardTurmaProfGrid({required this.turma, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaDetalhesDisciplinaProf(turma: turma))),
      child: Container(
        decoration: BoxDecoration(
          color: color, // Cor Sólida
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))
          ]
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(turma.nome, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2),
                  const SizedBox(height: 4),
                  Text("${turma.alunosInscritos.length} alunos", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Positioned(
              bottom: 12,
              right: 12,
              child: Icon(Icons.arrow_forward, color: Colors.white54, size: 20),
            )
          ],
        ),
      ),
    );
  }
}
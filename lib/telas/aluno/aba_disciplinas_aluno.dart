// lib/telas/aluno/aba_disciplinas_aluno.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart'; // Widgetbook

// Importações internas
import '../../providers/provedores_app.dart';
import '../../models/turma_professor.dart';
import '../../services/servico_firestore.dart'; 
import 'tela_entrar_turma.dart'; // Tela para entrar com código
import 'tela_detalhes_disciplina_aluno.dart'; // Hub da disciplina
import '../../l10n/app_localizations.dart'; // Traduções
import '../../themes/app_theme.dart'; // Cores

/// Caso de uso para o Widgetbook.
/// Simula a aba de disciplinas do aluno.
@UseCase(
  name: 'Aba Disciplinas (Aluno)',
  type: AbaDisciplinasAluno,
)
Widget buildAbaDisciplinasAluno(BuildContext context) {
  return const ProviderScope(
    child: AbaDisciplinasAluno(),
  );
}

/// Provedor auxiliar para buscar as aulas de uma turma específica.
/// Usado para calcular frequência em tempo real.
final aulasStreamProvider = StreamProvider.family<QuerySnapshot, String>((ref, turmaId) {
  final servico = ref.watch(servicoFirestoreProvider);
  return servico.getAulasStream(turmaId);
});

/// Tela principal que lista as disciplinas do aluno.
/// 
/// Exibe os cartões coloridos das matérias e um botão flutuante para
/// entrar em novas turmas via código.
class AbaDisciplinasAluno extends ConsumerWidget {
  const AbaDisciplinasAluno({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observa o stream de turmas do aluno logado
    final asyncTurmas = ref.watch(provedorStreamTurmasAluno);
    
    // Configuração de Tema e Cores
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Fundo adaptável (Claro/Escuro)
      
      body: CustomScrollView(
        slivers: [
          // --- TÍTULO GRANDE ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              child: Text(
                "Minhas\nDisciplinas", // Título fixo ou pode vir do i18n se preferir
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.1
                ),
              ),
            ),
          ),
          
          // --- LISTA DE DISCIPLINAS (GRID) ---
          asyncTurmas.when(
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()), // Erro silencioso ou placeholder
            data: (turmas) {
              // Caso lista vazia
              if (turmas.isEmpty) {
                return SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Text(
                        "Sem disciplinas.", 
                        style: TextStyle(color: textColor?.withOpacity(0.6))
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaEntrarTurma())),
                        child: const Text("Entrar em uma turma"),
                      )
                    ],
                  ),
                );
              }

              // Grade de Cards
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 Colunas
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1, // Formato quase quadrado
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final turma = turmas[index];
                      
                      // Cores rotativas para dar vida à interface
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
          // Espaço extra no final para o FAB não cobrir o último item
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      
      // --- BOTÃO DE ADICIONAR (FAB) ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryPurple,
        onPressed: () {
          // Abre a tela para digitar o código da turma
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaEntrarTurma()));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

/// Widget interno para o cartão da disciplina.
/// Exibe o nome, ícone e horário da matéria.
class _CardDisciplinaSolid extends StatelessWidget {
  final TurmaProfessor turma;
  final Color color;

  const _CardDisciplinaSolid({required this.turma, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Ao clicar, vai para o Painel da Disciplina (Hub)
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => TelaDetalhesDisciplinaAluno(turma: turma))
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color, // Cor sólida definida na lista
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3), 
              blurRadius: 8, 
              offset: const Offset(0, 4)
            )
          ]
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Ícone no topo esquerdo
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
            ),
            
            // Informações no rodapé do card
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
                  // Mostra apenas o primeiro horário para não poluir (ex: "Seg 08:00")
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
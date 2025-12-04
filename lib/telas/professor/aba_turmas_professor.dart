// lib/telas/professor/aba_turmas_professor.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/turma_professor.dart';
import '../../providers/provedores_app.dart';
import '../../l10n/app_localizations.dart'; // Traduções
import '../../themes/app_theme.dart'; // Cores
import '../comum/widget_carregamento.dart'; // Loading
import '../comum/animacao_fadein_lista.dart'; // Animação
import 'tela_criar_turma.dart'; // Tela de Criação
import 'tela_detalhes_disciplina_prof.dart'; // Hub da Disciplina

/// Caso de uso para o Widgetbook.
/// Simula a aba de turmas com dados fictícios.
@UseCase(
  name: 'Aba Turmas (Professor)',
  type: AbaTurmasProfessor,
)
Widget buildAbaTurmasProfessor(BuildContext context) {
  return const ProviderScope(
    child: AbaTurmasProfessor(),
  );
}

/// Aba principal que lista as turmas do professor.
///
/// Funcionalidades:
/// - Listagem em Grade (Grid) das turmas ativas.
/// - Botão Flutuante (FAB) para criar nova turma.
/// - Navegação para o Hub da Disciplina.
class AbaTurmasProfessor extends ConsumerWidget {
  const AbaTurmasProfessor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    // Observa o stream de turmas do professor logado
    final asyncTurmas = ref.watch(provedorStreamTurmasProfessor);
    
    // Configuração de Tema
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      
      body: CustomScrollView(
        slivers: [
          // 2. Grade de Turmas
          asyncTurmas.when(
            loading: () => const SliverToBoxAdapter(child: WidgetCarregamento()),
            
            error: (e, st) => SliverToBoxAdapter(
              child: Center(child: Text('${t.t('erro_generico')}: $e', style: TextStyle(color: textColor)))
            ),
            
            data: (turmas) {
              // Caso lista vazia
              if (turmas.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.class_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          "Nenhuma turma criada.", 
                          style: TextStyle(color: textColor?.withOpacity(0.6))
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaCriarTurma())),
                          child: Text(t.t('criar_turma_titulo')),
                        )
                      ],
                    ),
                  ),
                );
              }

              // Renderiza a Grade
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 Colunas
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1, // Proporção dos cards
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final turma = turmas[index];
                      
                      // Cores sólidas rotativas para identidade visual
                      final colors = [
                         AppColors.cardBlue,
                         AppColors.cardOrange,
                         AppColors.cardGreen,
                         AppColors.secondaryPurple,
                      ];
                      final color = colors[index % colors.length];

                      // Retorna o card animado (se desejar animação individual)
                      // Aqui usamos o card direto pois o Grid já tem comportamento de scroll
                      return _CardTurmaProfGrid(turma: turma, color: color);
                    },
                    childCount: turmas.length,
                  ),
                ),
              );
            },
          ),
          
          // Espaço extra no final para o FAB não cobrir conteúdo
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      
      // Botão para Criar Nova Turma
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryPurple,
        onPressed: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => const TelaCriarTurma())
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

/// Widget interno para o cartão da turma na grade.
class _CardTurmaProfGrid extends StatelessWidget {
  final TurmaProfessor turma;
  final Color color;

  const _CardTurmaProfGrid({required this.turma, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navega para o Hub da Disciplina
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => TelaDetalhesDisciplinaProf(turma: turma))
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color, // Cor de fundo sólida
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4), 
              blurRadius: 8, 
              offset: const Offset(0, 4)
            )
          ]
        ),
        child: Stack(
          children: [
            // Conteúdo do Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Ícone no topo
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 20),
                  ),
                  
                  // Textos
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        turma.nome, 
                        style: GoogleFonts.poppins(
                          color: Colors.white, 
                          fontSize: 16, 
                          fontWeight: FontWeight.bold
                        ), 
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${turma.alunosInscritos.length} alunos", 
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Seta decorativa
            const Positioned(
              bottom: 16,
              right: 16,
              child: Icon(Icons.arrow_forward, color: Colors.white54, size: 20),
            )
          ],
        ),
      ),
    );
  }
}
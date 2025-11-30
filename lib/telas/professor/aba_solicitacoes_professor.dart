// lib/telas/professor/aba_solicitacoes_professor.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../providers/provedores_app.dart';
import '../../models/solicitacao_aluno.dart';
import '../../l10n/app_localizations.dart'; // Traduções
import '../../themes/app_theme.dart'; // Cores
import '../comum/widget_carregamento.dart'; // Loading
import 'dialog_detalhes_solicitacao.dart'; // Modal de Detalhes

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Solicitações (Professor)',
  type: AbaSolicitacoesProfessor,
)
Widget buildAbaSolicitacoesProfessor(BuildContext context) {
  return const ProviderScope(
    child: AbaSolicitacoesProfessor(),
  );
}

/// Tela que lista todas as solicitações enviadas pelos alunos para o professor logado.
///
/// Funcionalidades:
/// - Listagem por status (Pendente, Aprovada, Recusada).
/// - Visualização de detalhes (Dialog).
/// - Filtro visual (Chips).
class AbaSolicitacoesProfessor extends ConsumerStatefulWidget {
  const AbaSolicitacoesProfessor({super.key});

  @override
  ConsumerState<AbaSolicitacoesProfessor> createState() => _AbaSolicitacoesProfessorState();
}

class _AbaSolicitacoesProfessorState extends ConsumerState<AbaSolicitacoesProfessor> {
  // Filtro atual da lista (Padrão: Pendente)
  StatusSolicitacao _filtroStatus = StatusSolicitacao.pendente;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    // Observa o stream de solicitações do professor
    final asyncSolicitacoes = ref.watch(provedorStreamSolicitacoesProfessor);
    
    // Configuração de Tema
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t.t('prof_solicitacoes_titulo'), // "Solicitações de Alunos"
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          // 1. Filtros (Chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(t, StatusSolicitacao.pendente, "Pendentes"),
                const SizedBox(width: 8),
                _buildFilterChip(t, StatusSolicitacao.aprovada, "Aprovadas"),
                const SizedBox(width: 8),
                _buildFilterChip(t, StatusSolicitacao.recusada, "Recusadas"),
              ],
            ),
          ),

          // 2. Lista de Solicitações
          Expanded(
            child: asyncSolicitacoes.when(
              loading: () => const WidgetCarregamento(texto: "Carregando solicitações..."),
              error: (e, s) => Center(child: Text('${t.t('erro_generico')}: $e', style: TextStyle(color: textColor))),
              data: (solicitacoes) {
                // Filtra localmente pelo status selecionado
                final filtradas = solicitacoes.where((s) => s.status == _filtroStatus).toList();

                if (filtradas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          t.t('prof_sem_solicitacoes'), // "Nenhuma solicitação..."
                          style: TextStyle(color: textColor?.withOpacity(0.7))
                        ),
                      ],
                    ),
                  );
                }
                
                // Ordena por data (mais recente primeiro)
                filtradas.sort((a, b) => b.data.compareTo(a.data));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtradas.length,
                  itemBuilder: (context, index) {
                    final sol = filtradas[index];
                    return _buildCardSolicitacao(context, t, sol, cardColor, textColor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o botão de filtro.
  Widget _buildFilterChip(AppLocalizations t, StatusSolicitacao status, String labelPadrao) {
    final isSelected = _filtroStatus == status;
    return ChoiceChip(
      label: Text(labelPadrao), // Idealmente traduzir os status também
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() => _filtroStatus = status);
        }
      },
      selectedColor: AppColors.primaryPurple,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  /// Constrói o cartão individual da solicitação.
  Widget _buildCardSolicitacao(BuildContext context, AppLocalizations t, SolicitacaoAluno sol, Color cardColor, Color? textColor) {
    // Ícone baseado no tipo
    IconData icon;
    Color iconColor;
    
    if (sol.tipo.contains("Adaptação")) {
       icon = Icons.accessibility_new;
       iconColor = Colors.purple;
    } else if (sol.tipo.contains("Nota") || sol.tipo.contains("Revisão")) {
       icon = Icons.grade;
       iconColor = Colors.orange;
    } else {
       icon = Icons.assignment;
       iconColor = Colors.blue;
    }

    return Card(
      color: cardColor,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
           // Abre o Dialog de Detalhes
           showDialog(
             context: context,
             builder: (ctx) => DialogDetalhesSolicitacao(solicitacao: sol)
           );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              
              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sol.tipo, 
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${sol.nomeAluno} • ${sol.ra}",
                      style: TextStyle(color: textColor?.withOpacity(0.7), fontSize: 12),
                    ),
                    Text(
                      sol.disciplina,
                      style: TextStyle(color: textColor?.withOpacity(0.5), fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              
              // Data e Status Visual
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('dd/MM').format(sol.data),
                    style: TextStyle(color: textColor?.withOpacity(0.5), fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  if (sol.anexo != null)
                     const Icon(Icons.attach_file, size: 16, color: Colors.grey),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
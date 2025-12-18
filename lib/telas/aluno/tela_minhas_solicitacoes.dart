// lib/telas/aluno/tela_minhas_solicitacoes.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Importações internas
import '../../models/solicitacao_aluno.dart';
import '../../providers/provedores_app.dart'; 
import '../../providers/provedor_autenticacao.dart'; 
import '../../themes/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../comum/widget_carregamento.dart';

// Provider que filtra apenas as solicitações do aluno logado
final minhasSolicitacoesProvider = StreamProvider.autoDispose<List<SolicitacaoAluno>>((ref) {
  final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;
  if (usuario == null) return const Stream.empty();
  
  final streamGeral = ref.watch(provedorStreamSolicitacoesGeral.stream);

  return streamGeral.map((lista) {
    return lista.where((s) => s.alunoId == usuario.uid).toList();
  });
});

class TelaMinhasSolicitacoes extends ConsumerStatefulWidget {
  const TelaMinhasSolicitacoes({super.key});

  @override
  ConsumerState<TelaMinhasSolicitacoes> createState() => _TelaMinhasSolicitacoesState();
}

class _TelaMinhasSolicitacoesState extends ConsumerState<TelaMinhasSolicitacoes> {
  // Filtro atual (null = Todos)
  StatusSolicitacao? _filtroStatus;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final asyncSolicitacoes = ref.watch(minhasSolicitacoesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Minhas Solicitações",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          // --- BARRA DE FILTROS ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip("Todas", null),
                const SizedBox(width: 8),
                _buildFilterChip("Pendentes", StatusSolicitacao.pendente),
                const SizedBox(width: 8),
                _buildFilterChip("Aprovadas", StatusSolicitacao.aprovada),
                const SizedBox(width: 8),
                _buildFilterChip("Recusadas", StatusSolicitacao.recusada),
              ],
            ),
          ),

          // --- LISTA DE SOLICITAÇÕES ---
          Expanded(
            child: asyncSolicitacoes.when(
              loading: () => const WidgetCarregamento(),
              error: (e, s) => Center(child: Text("Erro: $e")),
              data: (lista) {
                // Aplica o filtro selecionado na UI
                var filtradas = lista;
                if (_filtroStatus != null) {
                  filtradas = lista.where((s) => s.status == _filtroStatus).toList();
                }

                // Ordena: Mais recentes primeiro
                filtradas.sort((a, b) => b.data.compareTo(a.data));

                if (filtradas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          "Nenhuma solicitação encontrada.", 
                          style: TextStyle(color: textColor?.withOpacity(0.5))
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtradas.length,
                  itemBuilder: (context, index) {
                    final sol = filtradas[index];
                    return _buildCardSolicitacao(context, sol, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, StatusSolicitacao? status) {
    final isSelected = _filtroStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _filtroStatus = selected ? status : null; // Se clicar de novo, remove filtro
        });
      },
      selectedColor: AppColors.primaryPurple,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.3))),
    );
  }

  Widget _buildCardSolicitacao(BuildContext context, SolicitacaoAluno sol, bool isDark) {
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    // Configuração Visual baseada no Status
    Color statusColor;
    IconData statusIcon;
    String statusTexto;

    switch (sol.status) {
      case StatusSolicitacao.aprovada:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusTexto = "Aprovada";
        break;
      case StatusSolicitacao.recusada:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusTexto = "Recusada";
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusTexto = "Pendente";
    }

    return Card(
      color: cardColor,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          sol.tipo, 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sol.disciplina, style: TextStyle(color: textColor?.withOpacity(0.7))),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(sol.data),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusTexto.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                // O que o aluno pediu
                Text("Seu pedido:", style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 12)),
                const SizedBox(height: 4),
                Text(sol.descricao, style: TextStyle(color: textColor?.withOpacity(0.8), fontStyle: FontStyle.italic)),
                
                // Resposta do Professor (se houver)
                if (sol.resposta != null && sol.resposta!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3))
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.rate_review, size: 14, color: statusColor),
                            const SizedBox(width: 6),
                            Text("Resposta do Professor:", style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(sol.resposta!, style: TextStyle(color: textColor)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }
}
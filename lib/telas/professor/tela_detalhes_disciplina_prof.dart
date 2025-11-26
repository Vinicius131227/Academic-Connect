import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/turma_professor.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../comum/aba_chat_disciplina.dart';
import 'aba_materiais_professor.dart';
// Telas de gestão
import 'tela_chamada_manual.dart';
import 'tela_presenca_nfc.dart';
import 'tela_lancar_notas.dart';
import 'tela_marcar_prova.dart';
import 'tela_cadastro_nfc_manual.dart';
import 'tela_historico_chamadas.dart';
import 'tela_editar_turma.dart';
import 'tela_visualizar_alunos.dart';
import '../../services/servico_firestore.dart'; // Para gerar planilha

class TelaDetalhesDisciplinaProf extends ConsumerWidget {
  final TurmaProfessor turma;
  const TelaDetalhesDisciplinaProf({super.key, required this.turma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor, // Cor Dinâmica
        appBar: AppBar(
          title: Text(
            turma.nome,
            style: GoogleFonts.poppins(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: textColor
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
          bottom: TabBar(
            labelColor: AppColors.primaryPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryPurple,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Gestão'),
              Tab(text: 'Chat'),
              Tab(text: 'Materiais'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ABA 1: GESTÃO (Painel de Controle)
            _AbaGestaoProfessor(turma: turma),
            
            // ABA 2: CHAT
            AbaChatDisciplina(turmaId: turma.id),
            
            // ABA 3: MATERIAIS
            AbaMateriaisProfessor(turma: turma),
          ],
        ),
      ),
    );
  }
}

class _AbaGestaoProfessor extends ConsumerWidget {
  final TurmaProfessor turma;
  const _AbaGestaoProfessor({required this.turma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;

    // Cores dos cards (Claro vs Escuro)
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.black12;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Presença", textColor),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionButton(context, "NFC", Icons.nfc, Colors.green, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaPresencaNFC(turma: turma)))),
              const SizedBox(width: 12),
              _buildActionButton(context, "Manual", Icons.list_alt, Colors.blue, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaChamadaManual(turma: turma)))),
              const SizedBox(width: 12),
              _buildActionButton(context, "Histórico", Icons.history, Colors.orange, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaHistoricoChamadas(turma: turma)))),
            ],
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle("Avaliação", textColor),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionButton(context, "Lançar Notas", Icons.grade, Colors.purple, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaLancarNotas(turma: turma)))),
              const SizedBox(width: 12),
              _buildActionButton(context, "Marcar Prova", Icons.calendar_today, Colors.red, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaMarcarProva(turma: turma)))),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionTitle("Administração", textColor),
          const SizedBox(height: 12),
           Row(
            children: [
              _buildActionButton(context, "Cadastrar NFC", Icons.person_add_alt_1, Colors.teal, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaCadastroNfcManual(turma: turma)))),
              const SizedBox(width: 12),
              _buildActionButton(context, "Ver Alunos", Icons.people, Colors.indigo, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaVisualizarAlunos(turma: turma)))),
              const SizedBox(width: 12),
              _buildActionButton(context, "Planilha (CSV)", Icons.table_chart, Colors.green.shade800, cardColor, borderColor, textColor, () async {
                  final csv = await ref.read(servicoFirestoreProvider).gerarPlanilhaTurma(turma.id);
                  showDialog(context: context, builder: (ctx) => AlertDialog(
                     title: const Text("Planilha de Presença"),
                     content: SingleChildScrollView(child: SelectableText(csv)),
                     actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Fechar"))],
                  ));
              }),
            ],
          ),
          const SizedBox(height: 12),
          
          // Botão Largo: Editar Turma
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaEditarTurma(turma: turma))),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.settings, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text("Editar Configurações da Turma", style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color? color) {
    return Text(
      title, 
      style: GoogleFonts.poppins(
        color: color, 
        fontSize: 16, 
        fontWeight: FontWeight.bold
      )
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color iconColor, Color bgColor, Color borderColor, Color? textColor, VoidCallback onTap) {
    return Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ]
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: iconColor.withOpacity(0.1), 
                child: Icon(icon, color: iconColor, size: 22)
              ),
              const SizedBox(height: 8),
              Text(
                label, 
                style: GoogleFonts.poppins(color: textColor, fontSize: 11, fontWeight: FontWeight.w500), 
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
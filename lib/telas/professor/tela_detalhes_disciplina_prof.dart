import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para Clipboard
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/turma_professor.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../comum/aba_chat_disciplina.dart';
import 'aba_materiais_professor.dart';
import 'tela_chamada_manual.dart';
import 'tela_presenca_nfc.dart';
import 'tela_lancar_notas.dart';
import 'tela_marcar_prova.dart';
import 'tela_cadastro_nfc_manual.dart';
import 'tela_historico_chamadas.dart';
import 'tela_editar_turma.dart';
import 'tela_visualizar_alunos.dart';
import '../../services/servico_firestore.dart'; 

class TelaDetalhesDisciplinaProf extends ConsumerWidget {
  final TurmaProfessor turma;
  const TelaDetalhesDisciplinaProf({super.key, required this.turma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    // Cores dinâmicas
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            turma.nome,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
          bottom: TabBar(
            labelColor: AppColors.primaryPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryPurple,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: t.t('prof_gestao')),
              Tab(text: t.t('hub_chat')),
              Tab(text: t.t('hub_materiais')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AbaGestaoProfessor(turma: turma),
            AbaChatDisciplina(turmaId: turma.id),
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    
    // Cores adaptáveis
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.black12;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- NOVO: CARD DO CÓDIGO DA TURMA ---
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: turma.turmaCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.t('prof_copiado')), backgroundColor: Colors.green),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryPurple.withOpacity(0.5), width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    t.t('prof_codigo_turma').toUpperCase(), // "CÓDIGO DA TURMA"
                    style: GoogleFonts.poppins(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      color: AppColors.primaryPurple,
                      letterSpacing: 1.2
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        turma.turmaCode,
                        style: GoogleFonts.poppins(
                          fontSize: 32, 
                          fontWeight: FontWeight.bold, 
                          color: textColor
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.copy, color: AppColors.primaryPurple),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Toque para copiar e enviar aos alunos",
                    style: TextStyle(fontSize: 12, color: textColor?.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // SEÇÃO PRESENÇA
          _buildSectionTitle(t.t('prof_presenca'), textColor),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionButton(context, t.t('prof_nfc'), Icons.nfc, Colors.green, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaPresencaNFC(turma: turma)))),
              const SizedBox(width: 12),
              _buildActionButton(context, t.t('prof_manual'), Icons.list_alt, Colors.blue, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaChamadaManual(turma: turma)))),
              const SizedBox(width: 12),
              _buildActionButton(context, t.t('prof_historico'), Icons.history, Colors.orange, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaHistoricoChamadas(turma: turma)))),
            ],
          ),
          
          const SizedBox(height: 24),

          // SEÇÃO AVALIAÇÃO
          _buildSectionTitle(t.t('prof_avaliacao'), textColor),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionButton(context, t.t('prof_lancar_notas'), Icons.grade, Colors.purple, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaLancarNotas(turma: turma)))),
              const SizedBox(width: 12),
              _buildActionButton(context, t.t('prof_marcar_prova'), Icons.calendar_today, Colors.red, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaMarcarProva(turma: turma)))),
            ],
          ),

          const SizedBox(height: 24),

          // SEÇÃO ADMINISTRAÇÃO
          _buildSectionTitle(t.t('prof_admin'), textColor),
          const SizedBox(height: 12),
           Row(
            children: [
              _buildActionButton(context, t.t('prof_cadastrar_nfc'), Icons.person_add_alt_1, Colors.teal, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaCadastroNfcManual(turma: turma)))),
              const SizedBox(width: 12),
              _buildActionButton(context, t.t('prof_ver_alunos'), Icons.people, Colors.indigo, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaVisualizarAlunos(turma: turma)))),
              const SizedBox(width: 12),
              _buildActionButton(context, t.t('prof_planilha'), Icons.table_chart, Colors.green.shade800, cardColor, borderColor, textColor, () async {
                  final csv = await ref.read(servicoFirestoreProvider).gerarPlanilhaTurma(turma.id);
                  showDialog(context: context, builder: (ctx) => AlertDialog(
                     title: Text(t.t('prof_planilha')),
                     content: SingleChildScrollView(child: SelectableText(csv)),
                     actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
                  ));
              }),
            ],
          ),
          const SizedBox(height: 12),
          
          // Botão Largo: Editar Turma
           _buildActionButton(context, t.t('prof_editar_turma'), Icons.settings, Colors.grey, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaEditarTurma(turma: turma))), isFullWidth: true),
           
           const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color? color) {
    return Text(title, style: GoogleFonts.poppins(color: color, fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color iconColor, Color bgColor, Color borderColor, Color? textColor, VoidCallback onTap, {bool isFullWidth = false}) {
    return Expanded(
      flex: isFullWidth ? 0 : 1,
      child: Container(
        width: isFullWidth ? double.infinity : null,
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
              CircleAvatar(radius: 20, backgroundColor: iconColor.withOpacity(0.1), child: Icon(icon, color: iconColor, size: 22)),
              const SizedBox(height: 8),
              Text(label, style: GoogleFonts.poppins(color: textColor, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
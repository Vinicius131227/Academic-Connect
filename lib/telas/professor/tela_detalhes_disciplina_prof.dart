// lib/telas/professor/tela_detalhes_disciplina_prof.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:intl/intl.dart';

import '../../models/turma_professor.dart';
import '../../models/solicitacao_aluno.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../../services/servico_firestore.dart'; 
import '../../providers/provedores_app.dart';
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
import 'tela_importar_alunos.dart'; 
import 'dialog_detalhes_solicitacao.dart';

@UseCase(
  name: 'Detalhes Disciplina (Prof)',
  type: TelaDetalhesDisciplinaProf,
)
Widget buildTelaDetalhesDisciplinaProf(BuildContext context) {
  return ProviderScope(
    child: TelaDetalhesDisciplinaProf(
      turma: TurmaProfessor(
        id: 'mock_prof_1',
        nome: 'Cálculo 1',
        horario: 'Seg 08:00-10:00',
        local: 'AT1 - 105',
        professorId: 'prof_123',
        turmaCode: 'CALC23',
        creditos: 4,
        alunosInscritos: [],
      ),
    ),
  );
}

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
    
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.black12;

    // OBSERVA AS SOLICITAÇÕES
    final asyncSolicitacoes = ref.watch(provedorStreamSolicitacoesProfessor);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. CARD DO CÓDIGO DA TURMA
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
                    t.t('prof_codigo_turma').toUpperCase(), 
                    style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryPurple, letterSpacing: 1.2
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SelectableText(
                        turma.turmaCode,
                        style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.copy, color: AppColors.primaryPurple),
                        tooltip: "Copiar Código",
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: turma.turmaCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t.t('prof_copiado')), backgroundColor: Colors.green),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: AppColors.primaryPurple),
                        tooltip: t.t('prof_compartilhar_convite'),
                        onPressed: () {
                          final link = "academicconnect://entrar?codigo=${turma.turmaCode}";
                          final msg = t.t('prof_msg_convite', args: [turma.nome, turma.turmaCode]) + "\n\nLink: $link";
                          Share.share(msg);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("Toque para copiar", style: TextStyle(fontSize: 12, color: textColor?.withOpacity(0.6))),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),

          // 2. SOLICITAÇÕES PENDENTES (Adaptação/Abono)
          asyncSolicitacoes.when(
            loading: () => const SizedBox.shrink(),
            error: (_,__) => const SizedBox.shrink(),
            data: (todasSolicitacoes) {
              // Filtra apenas solicitações DESTA turma que estão PENDENTES
              final pendentes = todasSolicitacoes.where((s) => 
                s.turmaId == turma.id && s.status == StatusSolicitacao.pendente
              ).toList();

              if (pendentes.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        t.t('prof_solicitacoes_titulo'), // "Solicitações"
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pendentes.length,
                    itemBuilder: (context, index) {
                      final sol = pendentes[index];
                      return Card(
                        color: cardColor,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.orange, width: 1) // Borda de destaque
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.withOpacity(0.1),
                            child: const Icon(Icons.priority_high, color: Colors.orange, size: 20),
                          ),
                          title: Text(sol.tipo, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                          subtitle: Text(
                            "${sol.nomeAluno} • ${DateFormat('dd/MM').format(sol.data)}", 
                            style: TextStyle(color: textColor?.withOpacity(0.7), fontSize: 12)
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text("Ver", style: TextStyle(color: Colors.white, fontSize: 12)),
                            onPressed: () {
                              showDialog(
                                context: context, 
                                builder: (ctx) => DialogDetalhesSolicitacao(solicitacao: sol)
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),

          // 3. SEÇÃO PRESENÇA
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

          // 4. SEÇÃO AVALIAÇÃO
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

          // 5. SEÇÃO ADMINISTRAÇÃO
          _buildSectionTitle(t.t('prof_admin'), textColor),
          const SizedBox(height: 12),
           Row(
            children: [
              _buildActionButton(context, t.t('prof_cadastrar_nfc'), Icons.person_add_alt_1, Colors.teal, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaCadastroNfcManual(turma: turma)))),
              const SizedBox(width: 12),
              _buildActionButton(context, t.t('prof_ver_alunos'), Icons.people, Colors.indigo, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaVisualizarAlunos(turma: turma)))),
              const SizedBox(width: 12),
              _buildActionButton(context, t.t('prof_editar_turma'), Icons.settings, Colors.grey, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaEditarTurma(turma: turma)))),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildActionButton(context, "Importar (CSV)", Icons.upload_file, Colors.green.shade800, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaImportarAlunos(turmaId: turma.id, nomeDisciplina: turma.nome)))),
              const SizedBox(width: 12),
              _buildActionButton(context, "Baixar Presenças", Icons.download, Colors.blue.shade800, cardColor, borderColor, textColor, () async {
                  await ref.read(servicoFirestoreProvider).compartilharPlanilhaTurma(turma.id, turma.nome);
              }),
            ],
          ),
           
           const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color? color) {
    return Text(title, style: GoogleFonts.poppins(color: color, fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color iconColor, Color bgColor, Color borderColor, Color? textColor, VoidCallback onTap) {
    return Expanded(
      flex: 1,
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
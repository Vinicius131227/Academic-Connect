// lib/telas/professor/tela_detalhes_disciplina_prof.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/turma_professor.dart';
import '../../l10n/app_localizations.dart'; // Traduções
import '../../themes/app_theme.dart'; // Cores
import '../comum/aba_chat_disciplina.dart'; // Chat
import 'aba_materiais_professor.dart'; // Materiais
import '../../services/servico_firestore.dart'; // Serviço de dados

// Telas de gestão
import 'tela_chamada_manual.dart';
import 'tela_presenca_nfc.dart';
import 'tela_lancar_notas.dart';
import 'tela_marcar_prova.dart';
import 'tela_cadastro_nfc_manual.dart';
import 'tela_historico_chamadas.dart';
import 'tela_editar_turma.dart';
import 'tela_visualizar_alunos.dart';

/// Caso de uso para o Widgetbook.
/// Simula o painel de controle de uma disciplina.
@UseCase(
  name: 'Detalhes Disciplina (Professor)',
  type: TelaDetalhesDisciplinaProf,
)
Widget buildTelaDetalhesProf(BuildContext context) {
  return ProviderScope(
    child: TelaDetalhesDisciplinaProf(
      turma: TurmaProfessor(
        id: 'mock', 
        nome: 'Cálculo 1', 
        horario: '', 
        local: '', 
        professorId: '', 
        turmaCode: '', 
        creditos: 4, 
        alunosInscritos: []
      ),
    ),
  );
}

/// Tela principal de gestão de uma disciplina pelo professor.
/// 
/// Organizada em 3 abas:
/// 1. **Gestão:** Botões de ação rápida (Chamada, Notas, Configurações).
/// 2. **Chat:** Comunicação com a turma.
/// 3. **Materiais:** Upload de arquivos e links.
class TelaDetalhesDisciplinaProf extends ConsumerWidget {
  final TurmaProfessor turma;
  
  const TelaDetalhesDisciplinaProf({
    super.key, 
    required this.turma
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    // Configuração de tema
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    
    return DefaultTabController(
      length: 3, // Número de abas
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor, // Respeita o tema
        
        appBar: AppBar(
          title: Text(
            turma.nome,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
          
          // Abas de navegação interna
          bottom: TabBar(
            labelColor: AppColors.primaryPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryPurple,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: t.t('prof_gestao')),    // "Gestão"
              Tab(text: t.t('hub_chat')),       // "Chat"
              Tab(text: t.t('hub_materiais')),  // "Materiais"
            ],
          ),
        ),
        
        // Conteúdo das abas
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

/// Aba interna com os botões de ação administrativa.
class _AbaGestaoProfessor extends ConsumerWidget {
  final TurmaProfessor turma;
  const _AbaGestaoProfessor({required this.turma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    // Tema
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    
    // Cores dos botões (Cards)
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.black12;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SEÇÃO 1: PRESENÇA ---
          _buildSectionTitle(t.t('prof_presenca'), textColor), // "Presença"
          const SizedBox(height: 12),
          Row(
            children: [
              // Chamada NFC
              _buildActionButton(context, t.t('prof_nfc'), Icons.nfc, Colors.green, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaPresencaNFC(turma: turma)))),
              const SizedBox(width: 12),
              // Chamada Manual
              _buildActionButton(context, t.t('prof_manual'), Icons.list_alt, Colors.blue, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaChamadaManual(turma: turma)))),
              const SizedBox(width: 12),
              // Histórico
              _buildActionButton(context, t.t('prof_historico'), Icons.history, Colors.orange, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaHistoricoChamadas(turma: turma)))),
            ],
          ),
          
          const SizedBox(height: 24),

          // --- SEÇÃO 2: AVALIAÇÃO ---
          _buildSectionTitle(t.t('prof_avaliacao'), textColor), // "Avaliação"
          const SizedBox(height: 12),
          Row(
            children: [
              // Lançar Notas
              _buildActionButton(context, t.t('prof_lancar_notas'), Icons.grade, Colors.purple, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaLancarNotas(turma: turma)))),
              const SizedBox(width: 12),
              // Marcar Prova
              _buildActionButton(context, t.t('prof_marcar_prova'), Icons.calendar_today, Colors.red, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaMarcarProva(turma: turma)))),
            ],
          ),

          const SizedBox(height: 24),

          // --- SEÇÃO 3: ADMINISTRAÇÃO ---
          _buildSectionTitle(t.t('prof_admin'), textColor), // "Administração"
          const SizedBox(height: 12),
           Row(
            children: [
              // Cadastrar Cartão NFC
              _buildActionButton(context, t.t('prof_cadastrar_nfc'), Icons.person_add_alt_1, Colors.teal, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaCadastroNfcManual(turma: turma)))),
              const SizedBox(width: 12),
              // Ver Alunos
              _buildActionButton(context, t.t('prof_ver_alunos'), Icons.people, Colors.indigo, cardColor, borderColor, textColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaVisualizarAlunos(turma: turma)))),
              const SizedBox(width: 12),
              // Gerar Planilha
              _buildActionButton(context, t.t('prof_planilha'), Icons.table_chart, Colors.green.shade800, cardColor, borderColor, textColor, () async {
                  // Gera o CSV
                  final csv = await ref.read(servicoFirestoreProvider).gerarPlanilhaTurma(turma.id);
                  // Mostra em um diálogo para copiar
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

  /// Widget auxiliar para títulos de seção.
  Widget _buildSectionTitle(String title, Color? color) {
    return Text(title, style: GoogleFonts.poppins(color: color, fontSize: 16, fontWeight: FontWeight.bold));
  }

  /// Widget auxiliar para criar os botões de ação quadrados ou retangulares.
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
          // Sombra sutil no modo claro
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
                overflow: TextOverflow.ellipsis
              ),
            ],
          ),
        ),
      ),
    );
  }
}
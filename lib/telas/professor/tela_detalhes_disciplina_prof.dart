// lib/telas/professor/tela_detalhes_disciplina_prof.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/turma_professor.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../comum/aba_chat_disciplina.dart';
import 'aba_materiais_professor.dart';
// Importe as telas de gestão
import 'tela_chamada_manual.dart';
import 'tela_presenca_nfc.dart';
import 'tela_lancar_notas.dart';
import 'tela_marcar_prova.dart';
import 'tela_cadastro_nfc_manual.dart';
import 'tela_historico_chamadas.dart';
import 'tela_editar_turma.dart';
import 'tela_visualizar_alunos.dart';

class TelaDetalhesDisciplinaProf extends ConsumerWidget {
  final TurmaProfessor turma;
  const TelaDetalhesDisciplinaProf({super.key, required this.turma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(turma.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: AppColors.primaryPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryPurple,
            tabs: const [
              Tab(text: 'Gestão'), // Nova aba
              Tab(text: 'Chat'),
              Tab(text: 'Materiais'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ABA 1: GESTÃO (Botões de Ação)
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

class _AbaGestaoProfessor extends StatelessWidget {
  final TurmaProfessor turma;
  const _AbaGestaoProfessor({required this.turma});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Presença"),
          Row(
            children: [
              _buildActionButton(context, "NFC", Icons.nfc, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaPresencaNFC(turma: turma)))),
              const SizedBox(width: 12),
              _buildActionButton(context, "Manual", Icons.list_alt, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaChamadaManual(turma: turma)))),
              const SizedBox(width: 12),
              _buildActionButton(context, "Histórico", Icons.history, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaHistoricoChamadas(turma: turma)))),
            ],
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle("Avaliação"),
          Row(
            children: [
              _buildActionButton(context, "Lançar Notas", Icons.grade, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaLancarNotas(turma: turma)))),
              const SizedBox(width: 12),
              _buildActionButton(context, "Marcar Prova", Icons.calendar_today, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaMarcarProva(turma: turma)))),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionTitle("Administração"),
           Row(
            children: [
              _buildActionButton(context, "Cadastrar NFC", Icons.person_add_alt_1, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaCadastroNfcManual(turma: turma)))),
              const SizedBox(width: 12),
              _buildActionButton(context, "Ver Alunos", Icons.people, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaVisualizarAlunos(turma: turma)))),
            ],
          ),
          const SizedBox(height: 12),
           _buildActionButton(context, "Editar Turma", Icons.settings, Colors.grey, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaEditarTurma(turma: turma))), isFullWidth: true),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap, {bool isFullWidth = false}) {
    return Expanded(
      flex: isFullWidth ? 0 : 1,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
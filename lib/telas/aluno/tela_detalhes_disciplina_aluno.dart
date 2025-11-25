// lib/telas/aluno/tela_detalhes_disciplina_aluno.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/turma_professor.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/provedores_app.dart';
import '../comum/widget_carregamento.dart';
import '../../themes/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart'; // --- IMPORT ADICIONADO ---

class TelaDetalhesDisciplinaAluno extends ConsumerWidget {
  final TurmaProfessor turma;
  const TelaDetalhesDisciplinaAluno({super.key, required this.turma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final asyncNotas = ref.watch(provedorStreamNotasAluno); 
    final asyncProvas = ref.watch(provedorStreamCalendario); 

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(turma.nome),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Frequência & Professor"),
            Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: AppColors.primaryPurple, child: Icon(Icons.person, color: Colors.white)),
                title: const Text("Professor Responsável", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("Frequência: 85% (Exemplo)", style: TextStyle(color: Colors.white70)), 
              ),
            ),
            
            const SizedBox(height: 24),

            _buildSectionTitle("Minhas Notas"),
            asyncNotas.when(
              loading: () => const WidgetCarregamento(),
              error: (_,__) => const Text("Erro ao carregar notas"),
              data: (notas) {
                final notasTurma = notas.where((n) => n.turmaId == turma.id).toList();
                if (notasTurma.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("Nenhuma nota lançada.", style: TextStyle(color: Colors.white54))));
                
                return Column(
                  children: notasTurma.map((disciplinaNotas) {
                      return Column(
                        children: disciplinaNotas.avaliacoes.map((av) => Card(
                          child: ListTile(
                            title: Text(av.nome, style: const TextStyle(color: Colors.white)),
                            trailing: Text(
                              av.nota?.toStringAsFixed(1) ?? '-', 
                              style: TextStyle(color: av.nota != null ? Colors.green : Colors.grey, fontWeight: FontWeight.bold, fontSize: 18)
                            ),
                          ),
                        )).toList(),
                      );
                  }).toList(),
                );
              }
            ),

            const SizedBox(height: 24),

            _buildSectionTitle("Próximas Provas"),
             asyncProvas.when(
              loading: () => const WidgetCarregamento(),
              error: (_,__) => const SizedBox.shrink(),
              data: (provas) {
                final provasTurma = provas.where((p) => p.turmaId == turma.id).toList();
                if (provasTurma.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("Nenhuma prova agendada.", style: TextStyle(color: Colors.white54))));

                return Column(
                  children: provasTurma.map((prova) => Card(
                    color: AppColors.cardBlue,
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.white),
                      title: Text(prova.titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(DateFormat('dd/MM/yyyy - HH:mm').format(prova.dataHora), style: const TextStyle(color: Colors.white70)),
                    ),
                  )).toList(),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }
}
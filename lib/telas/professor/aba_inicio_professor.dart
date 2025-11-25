// lib/telas/professor/aba_inicio_professor.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/turma_professor.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../providers/provedores_app.dart';
import '../comum/widget_carregamento.dart';
import '../../themes/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tela_criar_turma.dart';

class AbaInicioProfessor extends ConsumerWidget {
  final ValueSetter<int> onNavigateToTab;

  const AbaInicioProfessor({super.key, required this.onNavigateToTab});

  String _getDiaSemanaAtual() {
    final int weekday = DateTime.now().weekday;
    switch (weekday) {
      case DateTime.monday: return 'seg';
      case DateTime.tuesday: return 'ter';
      case DateTime.wednesday: return 'qua';
      case DateTime.thursday: return 'qui';
      case DateTime.friday: return 'sex';
      case DateTime.saturday: return 'sab';
      case DateTime.sunday: return 'dom';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final nomeProf = ref.watch(provedorNotificadorAutenticacao).usuario?.alunoInfo?.nomeCompleto.split(' ')[0] ?? 'Professor';
    final asyncTurmas = ref.watch(provedorStreamTurmasProfessor);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CABEÇALHO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("👨‍🏫 ", style: TextStyle(fontSize: 24)),
                        Text(
                          "Olá, $nomeProf",
                          style: GoogleFonts.poppins(
                            fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textWhite
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Gestão de Aulas",
                      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                  child: const Icon(Icons.school, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 2. CARD DE STATUS (Roxo/Azul)
            asyncTurmas.when(
              data: (turmas) {
                final totalAlunos = turmas.fold(0, (sum, t) => sum + t.alunosInscritos.length);
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B1FA2), Color(0xFFBA68C8)], // Roxo degradê
                      begin: Alignment.topLeft, end: Alignment.bottomRight
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusItem(icon: Icons.class_, value: turmas.length.toString(), label: "Turmas"),
                      Container(width: 1, height: 40, color: Colors.white30),
                      _buildStatusItem(icon: Icons.people, value: totalAlunos.toString(), label: "Alunos"),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (_,__) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 32),

            // 3. ATALHOS RÁPIDOS
            Text("Acesso Rápido", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCategoryItem(
                  icon: Icons.add_circle_outline,
                  label: "Criar Turma",
                  color: const Color(0xFFE3F2FD),
                  iconColor: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaCriarTurma())),
                ),
                _buildCategoryItem(
                  icon: Icons.nfc,
                  label: "Chamada NFC",
                  color: const Color(0xFFE8F5E9),
                  iconColor: Colors.green,
                  onTap: () => onNavigateToTab(1), // Vai para aba de turmas
                ),
                _buildCategoryItem(
                  icon: Icons.list_alt,
                  label: "Manual",
                  color: const Color(0xFFFFF3E0),
                  iconColor: Colors.orange,
                  onTap: () => onNavigateToTab(1),
                ),
                _buildCategoryItem(
                  icon: Icons.grade,
                  label: "Notas",
                  color: const Color(0xFFF3E5F5),
                  iconColor: Colors.purple,
                  onTap: () => onNavigateToTab(1),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 4. AULAS DE HOJE
            Text(t.t('prof_aulas_hoje'), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),

            asyncTurmas.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e,s) => const SizedBox.shrink(),
              data: (turmas) {
                final diaAtual = _getDiaSemanaAtual();
                final aulasHoje = turmas.where((turma) => turma.horario.toLowerCase().contains(diaAtual)).toList();
                
                if (aulasHoje.isEmpty) {
                   return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Text(t.t('prof_sem_aulas'), style: const TextStyle(color: Colors.grey))),
                  );
                }
                return Column(
                  children: aulasHoje.map((turma) => _buildClassCard(turma)).toList(),
                );
              },
            ),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem({required IconData icon, required String value, required String label}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryItem({required IconData icon, required String label, required Color color, required Color iconColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60, width: 60,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildClassCard(TurmaProfessor turma) {
    // Extrai hora
    final String hora = turma.horario.split(' ').length > 1 ? turma.horario.split(' ')[1] : turma.horario;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: AppColors.primaryPurple, width: 4)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hora.split('-')[0], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Início", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10)),
            ],
          ),
          const SizedBox(width: 16),
          Container(height: 40, width: 1, color: Colors.white10),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(turma.nome, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(turma.local, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
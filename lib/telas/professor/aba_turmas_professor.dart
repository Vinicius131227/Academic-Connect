// lib/telas/professor/aba_turmas_professor.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/turma_professor.dart';
import '../../providers/provedores_app.dart';
import '../comum/widget_carregamento.dart';
import 'tela_criar_turma.dart';
// Importamos as telas de ação para o menu de contexto
import 'tela_chamada_manual.dart';
import 'tela_presenca_nfc.dart';
import 'tela_lancar_notas.dart';
import 'tela_marcar_prova.dart';
import 'tela_cadastro_nfc_manual.dart';
import 'tela_historico_chamadas.dart';
import 'tela_detalhes_disciplina_prof.dart';
import 'tela_editar_turma.dart';
import 'tela_visualizar_alunos.dart';
import '../../l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class AbaTurmasProfessor extends ConsumerWidget {
  const AbaTurmasProfessor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTurmas = ref.watch(provedorStreamTurmasProfessor);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Teacher's",
                    style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0),
                  ),
                  Text(
                    "Dashboard",
                    style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0),
                  ),
                  const SizedBox(height: 20),
                  // Ilustração
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage('https://cdn3d.iconscout.com/3d/premium/thumb/teacher-standing-near-board-3d-illustration-download-in-png-blend-fbx-gltf-file-formats--blackboard-female-professor-teaching-school-education-pack-illustrations-4736487.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          asyncTurmas.when(
            loading: () => const SliverToBoxAdapter(child: WidgetCarregamento()),
            error: (err, st) => SliverToBoxAdapter(child: Center(child: Text('Erro: $err'))),
            data: (turmas) {
              if (turmas.isEmpty) {
                return const SliverToBoxAdapter(child: Center(child: Text("Nenhuma turma criada.", style: TextStyle(color: Colors.white))));
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final turma = turmas[index];
                      final gradients = [
                         [const Color(0xFF00C6FB), const Color(0xFF005BEA)],
                         [const Color(0xFFF37335), const Color(0xFFFDC830)],
                         [const Color(0xFF11998e), const Color(0xFF38ef7d)],
                         [const Color(0xFFFF5ACD), const Color(0xFFFBDA61)],
                      ];
                      final gradient = gradients[index % gradients.length];

                      return _CardTurmaProfGrid(turma: turma, gradient: gradient);
                    },
                    childCount: turmas.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaCriarTurma())),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class _CardTurmaProfGrid extends StatelessWidget {
  final TurmaProfessor turma;
  final List<Color> gradient;

  const _CardTurmaProfGrid({required this.turma, required this.gradient});

  // Menu de Opções do Professor
  void _mostrarOpcoes(BuildContext context, AppLocalizations t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(turma.nome, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.nfc, color: Colors.green),
              title: const Text("Chamada NFC", style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => TelaPresencaNFC(turma: turma))); },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: Colors.blue),
              title: const Text("Chamada Manual", style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => TelaChamadaManual(turma: turma))); },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.orange),
              title: const Text("Histórico de Chamadas", style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => TelaHistoricoChamadas(turma: turma))); },
            ),
            ListTile(
              leading: const Icon(Icons.grade, color: Colors.purple),
              title: const Text("Lançar Notas", style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => TelaLancarNotas(turma: turma))); },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: const Text("Editar Turma / Alunos", style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => TelaEditarTurma(turma: turma))); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaDetalhesDisciplinaProf(turma: turma))),
      onLongPress: () => _mostrarOpcoes(context, t), // Segurar para abrir menu de gestão
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(turma.nome, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2),
                  Text("${turma.alunosInscritos.length} alunos", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () => _mostrarOpcoes(context, t),
              ),
            )
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/turma_professor.dart';
import '../../models/usuario.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/provedores_app.dart';
import '../../providers/provedor_autenticacao.dart'; // Importante
import '../../services/servico_firestore.dart';
import '../comum/widget_carregamento.dart';
import '../../themes/app_theme.dart';

// Telas para navegação
import '../comum/aba_chat_disciplina.dart';
import 'aba_materiais_aluno.dart';

// Provider para buscar dados do professor
final professorProvider = FutureProvider.family<UsuarioApp?, String>((ref, professorId) async {
  return ref.read(servicoFirestoreProvider).getUsuario(professorId);
});

final aulasTurmaProvider = StreamProvider.family<QuerySnapshot, String>((ref, turmaId) {
  return ref.read(servicoFirestoreProvider).getAulasStream(turmaId);
});

class TelaDetalhesDisciplinaAluno extends ConsumerWidget {
  final TurmaProfessor turma;
  const TelaDetalhesDisciplinaAluno({super.key, required this.turma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    // --- CORREÇÃO AQUI ---
    // Pegamos o usuário logado do provedor de autenticação, não do serviço firestore direto
    final alunoUid = ref.watch(provedorNotificadorAutenticacao).usuario?.uid;
    
    // Streams
    final asyncNotas = ref.watch(provedorStreamNotasAluno);
    final asyncProvas = ref.watch(provedorStreamCalendario);
    final asyncProfessor = ref.watch(professorProvider(turma.professorId));
    final asyncAulas = ref.watch(aulasTurmaProvider(turma.id));

    // Tema Dinâmico
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    
    // Cores seguras
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Fundo Dinâmico
      appBar: AppBar(
        title: Text(
          turma.nome, 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BOTÕES DE ACESSO RÁPIDO (Chat e Materiais)
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context, 
                    label: t.t('hub_chat'), 
                    icon: Icons.chat_bubble_outline, 
                    color: Colors.blue, 
                    onTap: () {
                       // Abre tela de chat isolada
                       Navigator.push(context, MaterialPageRoute(builder: (_) => _TelaChatIsolada(turmaId: turma.id, nomeDisciplina: turma.nome)));
                    }
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context, 
                    label: t.t('hub_materiais'), 
                    icon: Icons.folder_copy_outlined, 
                    color: Colors.orange, 
                    onTap: () {
                       // Abre tela de materiais isolada
                       Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                         appBar: AppBar(
                           title: Text(t.t('hub_materiais'), style: TextStyle(color: textColor)), 
                           backgroundColor: theme.scaffoldBackgroundColor, 
                           iconTheme: IconThemeData(color: textColor),
                           elevation: 0
                         ),
                         backgroundColor: theme.scaffoldBackgroundColor,
                         body: AbaMateriaisAluno(turmaId: turma.id, nomeDisciplina: turma.nome),
                       )));
                    }
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // 2. CARD DE INFO (Professor e Frequência)
            _buildSectionTitle("Informações Gerais", textColor),
            Card(
              color: cardColor,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Professor
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryPurple.withOpacity(0.2),
                          child: const Icon(Icons.person, color: AppColors.primaryPurple),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Professor(a)", style: TextStyle(color: subTextColor, fontSize: 12)),
                              asyncProfessor.when(
                                data: (prof) => Text(
                                  prof?.alunoInfo?.nomeCompleto ?? "Professor",
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                loading: () => const Text("Carregando...", style: TextStyle(fontSize: 14)),
                                error: (_,__) => const Text("Indisponível", style: TextStyle(fontSize: 14)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Frequência
                    asyncAulas.when(
                      data: (snapshot) {
                        int total = snapshot.docs.length;
                        int presencas = 0;
                        
                        if (alunoUid != null) {
                          for (var doc in snapshot.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final pInicio = List<String>.from(data['presentes_inicio'] ?? []);
                            final pFim = List<String>.from(data['presentes_fim'] ?? []);
                            if (pInicio.contains(alunoUid) || pFim.contains(alunoUid)) {
                              presencas++;
                            }
                          }
                        }
                        double pct = total == 0 ? 100.0 : (presencas / total) * 100;
                        Color corFreq = pct >= 75 ? AppColors.success : AppColors.error;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Frequência", style: TextStyle(color: subTextColor, fontSize: 12)),
                                Text(
                                  "${pct.toStringAsFixed(0)}%", 
                                  style: TextStyle(color: corFreq, fontWeight: FontWeight.bold, fontSize: 24)
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("Aulas: $total", style: TextStyle(color: subTextColor, fontSize: 12)),
                                Text("Presenças: $presencas", style: TextStyle(color: textColor, fontSize: 14)),
                              ],
                            ),
                          ],
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_,__) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // 3. NOTAS
            _buildSectionTitle("Minhas Notas", textColor),
            asyncNotas.when(
              loading: () => const WidgetCarregamento(texto: ""),
              error: (_,__) => const SizedBox(),
              data: (notas) {
                final notasTurma = notas.where((n) => n.turmaId == turma.id).toList();
                if (notasTurma.isEmpty) {
                   return Card(
                     color: cardColor,
                     elevation: 2,
                     child: Padding(
                       padding: const EdgeInsets.all(16), 
                       child: Center(child: Text("Nenhuma nota lançada.", style: TextStyle(color: subTextColor)))
                     )
                   );
                }
                return Column(
                  children: notasTurma.expand((disciplinaNotas) {
                      return disciplinaNotas.avaliacoes.map((av) => Card(
                        color: cardColor,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(av.nome, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (av.nota ?? 0) >= 6 ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12)
                            ),
                            child: Text(
                              av.nota?.toStringAsFixed(1) ?? '-', 
                              style: TextStyle(
                                color: (av.nota ?? 0) >= 6 ? AppColors.success : AppColors.error, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 16
                              )
                            ),
                          ),
                        ),
                      ));
                  }).toList(),
                );
              }
            ),

            const SizedBox(height: 24),

            // 4. PRÓXIMAS PROVAS
            _buildSectionTitle("Próximas Avaliações", textColor),
             asyncProvas.when(
              loading: () => const WidgetCarregamento(texto: ""),
              error: (_,__) => const SizedBox.shrink(),
              data: (provas) {
                final provasTurma = provas.where((p) => p.turmaId == turma.id).toList();
                
                if (provasTurma.isEmpty) {
                   return Card(
                     color: cardColor,
                     elevation: 2,
                     child: Padding(
                       padding: const EdgeInsets.all(16), 
                       child: Center(child: Text("Nenhuma prova agendada.", style: TextStyle(color: subTextColor)))
                     )
                   );
                }
                return Column(
                  children: provasTurma.map((prova) => Card(
                    color: cardColor,
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.cardOrange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.calendar_today, color: AppColors.cardOrange),
                      ),
                      title: Text(prova.titulo, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy - HH:mm').format(prova.dataHora), 
                        style: TextStyle(color: subTextColor)
                      ),
                    ),
                  )).toList(),
                );
              }
            ),
            
            const SizedBox(height: 80), 
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Text(
        title, 
        style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 18)
      ),
    );
  }
  
  Widget _buildActionButton(BuildContext context, {required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? (theme.brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white);
    final textColor = theme.textTheme.bodyLarge?.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// Tela auxiliar para abrir o chat com AppBar
class _TelaChatIsolada extends StatelessWidget {
  final String turmaId;
  final String nomeDisciplina;
  
  const _TelaChatIsolada({required this.turmaId, required this.nomeDisciplina});

  @override
  Widget build(BuildContext context) {
     final theme = Theme.of(context);
     final textColor = theme.textTheme.bodyLarge?.color;

     return Scaffold(
       appBar: AppBar(
         title: Text("Chat: $nomeDisciplina", style: TextStyle(color: textColor)),
         iconTheme: IconThemeData(color: textColor),
         backgroundColor: theme.scaffoldBackgroundColor,
         elevation: 0,
       ),
       body: AbaChatDisciplina(turmaId: turmaId),
     );
  }
}
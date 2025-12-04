// lib/telas/aluno/tela_detalhes_disciplina_aluno.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/turma_professor.dart';
import '../../models/usuario.dart'; // Para o model do professor
import '../../l10n/app_localizations.dart';
import '../../providers/provedores_app.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../services/servico_firestore.dart';
import '../comum/widget_carregamento.dart';
import '../../themes/app_theme.dart';

// Telas de navegação
import '../comum/aba_chat_disciplina.dart';
import 'aba_materiais_aluno.dart';

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Detalhes Disciplina (Aluno)',
  type: TelaDetalhesDisciplinaAluno,
)
Widget buildTelaDetalhesDisciplina(BuildContext context) {
  return ProviderScope(
    child: TelaDetalhesDisciplinaAluno(
      turma: TurmaProfessor(
        id: 'mock_id',
        nome: 'Cálculo 1',
        horario: 'Seg 08:00-10:00',
        local: 'AT1 101',
        professorId: 'prof_id',
        turmaCode: 'XYZ123',
        creditos: 4,
        alunosInscritos: [],
      ),
    ),
  );
}

/// Provedor auxiliar para buscar os dados do professor pelo ID.
final professorProvider = FutureProvider.family<UsuarioApp?, String>((ref, professorId) async {
  return ref.read(servicoFirestoreProvider).getUsuario(professorId);
});

/// Provedor auxiliar para monitorar as aulas da turma (para calcular frequência).
final aulasTurmaProvider = StreamProvider.family<QuerySnapshot, String>((ref, turmaId) {
  return ref.read(servicoFirestoreProvider).getAulasStream(turmaId);
});

/// Tela principal de detalhes de uma disciplina para o aluno (Hub).
class TelaDetalhesDisciplinaAluno extends ConsumerWidget {
  final TurmaProfessor turma;
  
  const TelaDetalhesDisciplinaAluno({
    super.key, 
    required this.turma
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    // Obtém o ID do aluno logado para filtrar notas e frequência
    final alunoUid = ref.watch(provedorNotificadorAutenticacao).usuario?.uid;
    
    // Streams de dados em tempo real
    final asyncNotas = ref.watch(provedorStreamNotasAluno);
    final asyncProvas = ref.watch(provedorStreamCalendario);
    final asyncProfessor = ref.watch(professorProvider(turma.professorId));
    final asyncAulas = ref.watch(aulasTurmaProvider(turma.id));

    // Configurações de Tema
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white; // Força branco no light
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    
    // Usa a cor de fundo do scaffold definida no tema
    final bgColor = theme.scaffoldBackgroundColor; 

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          turma.nome, 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      
      // FAB para acesso rápido ao Chat
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => _TelaChatIsolada(turmaId: turma.id, nomeDisciplina: turma.nome)));
        },
        backgroundColor: AppColors.primaryPurple,
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        label: Text(t.t('hub_chat'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Botões de Ação (Materiais)
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context, 
                    label: t.t('hub_materiais'), 
                    icon: Icons.folder_copy_outlined, 
                    color: Colors.orange, 
                    cardColor: cardColor, 
                    textColor: textColor, 
                    onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                          appBar: AppBar(
                            title: Text(t.t('hub_materiais'), style: TextStyle(color: textColor)), 
                            backgroundColor: bgColor, 
                            iconTheme: IconThemeData(color: textColor), 
                            elevation: 0
                          ),
                          backgroundColor: bgColor,
                          body: AbaMateriaisAluno(turmaId: turma.id, nomeDisciplina: turma.nome),
                        )));
                    }
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Card de Informações Gerais
            _buildSectionTitle(t.t('hub_info_geral'), textColor), // "Informações Gerais"
            Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Linha do Professor
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
                              Text(t.t('hub_professor'), style: TextStyle(color: subTextColor, fontSize: 12)),
                              asyncProfessor.when(
                                data: (prof) => Text(
                                  prof?.alunoInfo?.nomeCompleto ?? "Professor", 
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)
                                ),
                                loading: () => const Text("...", style: TextStyle(fontSize: 14)),
                                error: (_,__) => const Text("-", style: TextStyle(fontSize: 14)),
                              ),
                            ]
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    
                    // Linha de Frequência
                    asyncAulas.when(
                      data: (snapshot) {
                        int total = snapshot.docs.length;
                        int presencas = 0;
                        
                        // Calcula presença baseada nos arrays de IDs
                        if (alunoUid != null) {
                          for (var doc in snapshot.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final pInicio = List.from(data['presentes_inicio']??[]);
                            final pFim = List.from(data['presentes_fim']??[]);
                            // Se marcou presença no inicio OU fim, conta como presente
                            if (pInicio.contains(alunoUid) || pFim.contains(alunoUid)) presencas++;
                          }
                        }
                        
                        double pct = total == 0 ? 100.0 : (presencas / total) * 100;
                        Color corFreq = pct >= 75 ? AppColors.success : AppColors.error;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(t.t('hub_frequencia'), style: TextStyle(color: subTextColor, fontSize: 12)),
                                Text("${pct.toStringAsFixed(0)}%", style: TextStyle(color: corFreq, fontWeight: FontWeight.bold, fontSize: 24)),
                            ]),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text("${t.t('hub_aulas_totais')}: $total", style: TextStyle(color: subTextColor, fontSize: 12)),
                                Text("${t.t('hub_presencas')}: $presencas", style: TextStyle(color: textColor, fontSize: 14)),
                            ]),
                        ]);
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_,__) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 3. Notas
            _buildSectionTitle(t.t('hub_minhas_notas'), textColor), // "Minhas Notas"
            asyncNotas.when(
              loading: () => const SizedBox(),
              error: (_,__) => const SizedBox(),
              data: (notas) {
                // Filtra apenas notas desta turma
                final notasTurma = notas.where((n) => n.turmaId == turma.id).toList();
                
                if (notasTurma.isEmpty) {
                   return Card(
                     color: cardColor, 
                     child: Padding(
                       padding: const EdgeInsets.all(16), 
                       // CORREÇÃO: Tradução inserida aqui
                       child: Center(child: Text(t.t('detalhes_sem_notas'), style: TextStyle(color: subTextColor)))
                     )
                   );
                }
                
                return Column(
                  children: notasTurma.expand((d) => d.avaliacoes.map((av) => Card(
                    color: cardColor, 
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
                            fontWeight: FontWeight.bold
                          )
                        )
                      )
                    )
                  ))).toList()
                );
              }
            ),
            
            const SizedBox(height: 24),
            
            // 4. Próximas Provas
            _buildSectionTitle(t.t('hub_proximas_provas'), textColor), // "Próximas Provas"
             asyncProvas.when(
              loading: () => const SizedBox(),
              error: (_,__) => const SizedBox(),
              data: (provas) {
                final provasTurma = provas.where((p) => p.turmaId == turma.id).toList();
                
                if (provasTurma.isEmpty) {
                   return Card(
                     color: cardColor, 
                     child: Padding(
                       padding: const EdgeInsets.all(16), 
                       // CORREÇÃO: Tradução inserida aqui
                       child: Center(child: Text(t.t('detalhes_sem_provas'), style: TextStyle(color: subTextColor)))
                     )
                   );
                }
                
                return Column(
                  children: provasTurma.map((p) => Card(
                    color: cardColor, 
                    margin: const EdgeInsets.only(bottom: 8), 
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8), 
                        decoration: BoxDecoration(color: AppColors.cardOrange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), 
                        child: const Icon(Icons.calendar_today, color: AppColors.cardOrange)
                      ), 
                      title: Text(p.titulo, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)), 
                      subtitle: Text(DateFormat('dd/MM HH:mm').format(p.dataHora), style: TextStyle(color: subTextColor))
                    )
                  )).toList()
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
      child: Text(title, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 18))
    );
  }
  
  Widget _buildActionButton(BuildContext context, {required String label, required IconData icon, required Color color, required Color cardColor, required Color? textColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
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

/// Tela auxiliar para abrir o chat com AppBar dedicada.
class _TelaChatIsolada extends StatelessWidget {
  final String turmaId;
  final String nomeDisciplina;
  
  const _TelaChatIsolada({required this.turmaId, required this.nomeDisciplina});

  @override
  Widget build(BuildContext context) {
     final theme = Theme.of(context);
     final textColor = theme.textTheme.bodyLarge?.color;
     final t = AppLocalizations.of(context)!; // Recupera traduções

     return Scaffold(
       appBar: AppBar(
         // CORREÇÃO: Título traduzido "Chat: Cálculo 1"
         title: Text(t.t('chat_titulo_sala', args: [nomeDisciplina]), style: TextStyle(color: textColor)),
         iconTheme: IconThemeData(color: textColor),
         backgroundColor: theme.scaffoldBackgroundColor,
         elevation: 0,
       ),
       body: AbaChatDisciplina(turmaId: turmaId),
     );
  }
}
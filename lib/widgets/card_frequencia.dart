import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/turma_professor.dart';
import '../models/disciplina_frequencia.dart';
import '../l10n/app_localizations.dart';
import '../providers/provedor_autenticacao.dart';
import '../services/servico_firestore.dart';
import '../telas/aluno/tela_notas_avaliacoes.dart';

/// Um stream "family" que escuta a sub-coleção 'aulas' de uma turma específica.
final aulasStreamProvider = StreamProvider.family<QuerySnapshot, String>((ref, turmaId) {
  final servico = ref.watch(servicoFirestoreProvider);
  return servico.getAulasStream(turmaId);
});

class CardFrequencia extends ConsumerWidget {
  final TurmaProfessor turma;
  const CardFrequencia({required this.turma, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    final alunoUid = ref.watch(provedorNotificadorAutenticacao).usuario?.uid;
    
    // Assiste ao stream de aulas (presença) DESTA turma
    final asyncAulas = ref.watch(aulasStreamProvider(turma.id));

    return asyncAulas.when(
      loading: () => Card(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(children: [
          Expanded(child: Text(turma.nome, style: theme.textTheme.titleLarge)),
          const SizedBox(width: 16),
          const CircularProgressIndicator(strokeWidth: 2),
        ]),
      )),
      error: (e,s) => Card(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Erro ao carregar frequência: $e'),
      )),
      data: (querySnapshot) {
        
        // --- CÁLCULO DA FREQUÊNCIA ---
        int totalAulas = querySnapshot.docs.length;
        int presencas = 0;
        
        if (alunoUid != null) {
          for (final doc in querySnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final presentesInicio = List<String>.from(data['presentes_inicio'] ?? []);
            final presentesFim = List<String>.from(data['presentes_fim'] ?? []);
            
            if (presentesInicio.contains(alunoUid) || presentesFim.contains(alunoUid)) {
              presencas++;
            }
          }
        }
        
        int faltas = totalAulas - presencas;
        double porcentagem = (totalAulas == 0) ? 100.0 : (presencas / totalAulas) * 100;
        
        final freq = DisciplinaFrequencia(
          nome: turma.nome,
          faltas: faltas,
          totalAulas: totalAulas,
          linkMateria: "https://classroom.google.com/", // TODO: Adicionar 'linkMateria' no model da Turma
        );
        // --- FIM DO CÁLCULO ---
        
        final bool aprovado = freq.estaAprovado;
        final Color corPrincipal = aprovado ? Colors.green : Colors.red;

        return Card(
          color: theme.brightness == Brightness.dark
              ? theme.cardTheme.color 
              : corPrincipal.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(freq.nome, style: theme.textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            '${freq.faltas} ${t.t('aluno_disciplinas_faltas')} • ${freq.totalAulas} ${t.t('aluno_disciplinas_aulas')}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      aprovado ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                      color: corPrincipal,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(t.t('aluno_disciplinas_frequencia'), style: theme.textTheme.bodyMedium),
                    const Spacer(),
                    Text(
                      '${freq.porcentagem.toStringAsFixed(0)}%',
                      style: theme.textTheme.bodyLarge?.copyWith(
                              color: corPrincipal,
                              fontWeight: FontWeight.bold,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: freq.porcentagem / 100,
                    backgroundColor: corPrincipal.withOpacity(0.2),
                    color: corPrincipal,
                    minHeight: 12,
                  ),
                ),
                
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.school_outlined, size: 18),
                        label: Text(t.t('aluno_disciplinas_ver_notas')),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TelaNotasAvaliacoes(disciplinaInicial: freq.nome),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.link, size: 18),
                        label: Text(t.t('aluno_disciplinas_acessar_materia')),
                        onPressed: () async {
                          final url = Uri.parse(freq.linkMateria);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Não foi possível abrir o link: ${freq.linkMateria}')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
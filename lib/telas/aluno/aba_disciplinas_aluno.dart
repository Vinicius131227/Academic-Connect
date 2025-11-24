// lib/telas/aluno/aba_disciplinas_aluno.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provedores_app.dart';
import '../../providers/provedor_autenticacao.dart';
import '../comum/widget_carregamento.dart';
import '../../models/turma_professor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/servico_firestore.dart'; 
import 'tela_entrar_turma.dart';
import '../../models/disciplina_frequencia.dart';
import 'tela_notas_avaliacoes.dart'; 
import 'tela_detalhes_disciplina_aluno.dart'; // Importante
import 'package:url_launcher/url_launcher.dart'; 
import '../../l10n/app_localizations.dart';
import '../comum/animacao_fadein_lista.dart'; 

final aulasStreamProvider = StreamProvider.family<QuerySnapshot, String>((ref, turmaId) {
  final servico = ref.watch(servicoFirestoreProvider);
  return servico.getAulasStream(turmaId);
});

class AbaDisciplinasAluno extends ConsumerWidget {
  const AbaDisciplinasAluno({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final asyncTurmas = ref.watch(provedorStreamTurmasAluno);
    final theme = Theme.of(context);

    return Scaffold(
      body: asyncTurmas.when(
        loading: () => const WidgetCarregamento(),
        error: (e, s) => Center(child: Text('Erro ao carregar disciplinas: $e')),
        data: (turmas) {
          final widgets = <Widget>[
            Card(
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.onSecondaryContainer, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.t('aluno_disciplinas_aviso'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (turmas.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40.0),
                child: Center(child: Text('Nenhuma disciplina. Clique no + para entrar em uma turma.')),
              ),

            ...turmas.map((turma) => _CardFrequencia(turma: turma)),
          ];

          return FadeInListAnimation(children: widgets);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaEntrarTurma()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CardFrequencia extends ConsumerWidget {
  final TurmaProfessor turma;
  const _CardFrequencia({required this.turma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    final alunoUid = ref.watch(provedorNotificadorAutenticacao).usuario?.uid;
    final asyncAulas = ref.watch(aulasStreamProvider(turma.id));

    return asyncAulas.when(
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
      error: (e,s) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Erro: $e'))),
      data: (querySnapshot) {
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
          linkMateria: "", 
        );
        final bool aprovado = freq.estaAprovado;
        final Color corPrincipal = aprovado ? Colors.green : Colors.red;

        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), 
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(freq.nome, style: theme.textTheme.titleLarge),
                          Text('${freq.faltas} faltas • ${freq.totalAulas} aulas', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Text('${freq.porcentagem.toStringAsFixed(0)}%', style: theme.textTheme.bodyLarge?.copyWith(color: corPrincipal, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(value: freq.porcentagem / 100, color: corPrincipal, minHeight: 8),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.school_outlined, size: 18),
                        label: const Text('Notas'),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => TelaNotasAvaliacoes(disciplinaInicial: freq.nome)));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('Acessar Sala'),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => TelaDetalhesDisciplinaAluno(turma: turma)));
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
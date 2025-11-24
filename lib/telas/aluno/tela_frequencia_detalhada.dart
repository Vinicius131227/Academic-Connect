import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// --- IMPORTES ATUALIZADOS ---
import '../../providers/provedores_app.dart';
import '../../widgets/card_frequencia.dart'; // <-- CORREÇÃO AQUI
import '../comum/widget_carregamento.dart';
// --- FIM IMPORTES ATUALIZADOS ---
import '../../l10n/app_localizations.dart';
import '../comum/animacao_fadein_lista.dart'; 

class TelaFrequenciaDetalhada extends ConsumerWidget {
  const TelaFrequenciaDetalhada({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    // --- ATUALIZADO: Assiste ao stream de turmas ---
    final asyncTurmas = ref.watch(provedorStreamTurmasAluno);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('aluno_disciplinas_titulo')),
      ),
      body: asyncTurmas.when(
        loading: () => const WidgetCarregamento(),
        error: (e, s) => Center(child: Text('Erro ao carregar disciplinas: $e')),
        data: (turmas) {
          if (turmas.isEmpty) {
             return Center(child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Nenhuma disciplina encontrada. Entre em uma turma usando o código do professor na aba "Disciplinas".',
                     textAlign: TextAlign.center,
                     style: theme.textTheme.titleMedium,
                  ),
             ),
            );
          }

          final widgets = <Widget>[
            // Aviso
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
            
            // --- ATUALIZADO: Usa o widget público ---
            ...turmas.map((turma) => CardFrequencia(turma: turma)),
          ];

          return FadeInListAnimation(children: widgets);
        },
      ),
    );
  }
}
// lib/telas/aluno/tela_frequencia_detalhada.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../providers/provedores_app.dart';
import '../comum/card_frequencia.dart'; // Widget reutilizável de frequência
import '../comum/widget_carregamento.dart';
import '../../l10n/app_localizations.dart'; // Traduções
import '../comum/animacao_fadein_lista.dart'; // Animação de lista

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Lista de Frequências',
  type: TelaFrequenciaDetalhada,
)
Widget buildTelaFrequencia(BuildContext context) {
  return const ProviderScope(
    child: TelaFrequenciaDetalhada(),
  );
}

/// Tela que exibe a lista de todas as disciplinas do aluno com o detalhe de frequência.
/// É acessada pelo botão "Ver Detalhes" no card de Frequência da Home.
class TelaFrequenciaDetalhada extends ConsumerWidget {
  const TelaFrequenciaDetalhada({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    // Observa o stream de turmas do aluno logado
    final asyncTurmas = ref.watch(provedorStreamTurmasAluno);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.t('aluno_disciplinas_titulo')), // "Minhas Disciplinas"
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Ícone do botão voltar adaptado ao tema
        iconTheme: IconThemeData(color: theme.textTheme.bodyLarge?.color),
        titleTextStyle: theme.textTheme.titleLarge,
      ),
      
      // Gerencia o estado do carregamento de dados
      body: asyncTurmas.when(
        loading: () => const WidgetCarregamento(texto: "Carregando turmas..."),
        error: (e, s) => Center(child: Text('Erro ao carregar disciplinas: $e')),
        data: (turmas) {
          // Caso lista vazia
          if (turmas.isEmpty) {
             return Center(
               child: Padding(
                 padding: const EdgeInsets.all(20.0),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Icon(Icons.class_outlined, size: 64, color: Colors.grey),
                     const SizedBox(height: 16),
                     Text(
                       'Nenhuma disciplina encontrada.\nEntre em uma turma usando o código do professor.',
                       textAlign: TextAlign.center,
                       style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                     ),
                   ],
                 ),
               ),
            );
          }

          // Lista de widgets a serem exibidos
          final widgets = <Widget>[
            // Card de Aviso (Regras de Frequência)
            Card(
              color: theme.colorScheme.secondaryContainer,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.onSecondaryContainer, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.t('aluno_disciplinas_aviso'), // "Frequência mínima: 75%"
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Mapeia cada turma para o widget CardFrequencia
            ...turmas.map((turma) => CardFrequencia(turma: turma)),
          ];

          // Retorna a lista com animação de entrada
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: FadeInListAnimation(children: widgets),
          );
        },
      ),
    );
  }
}
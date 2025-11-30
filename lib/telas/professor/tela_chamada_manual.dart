// lib/telas/professor/tela_chamada_manual.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/turma_professor.dart';
import '../../providers/provedor_professor.dart'; // Notificador de chamada
import '../../l10n/app_localizations.dart'; // Traduções
import '../comum/widget_carregamento.dart'; // Loading visual

/// Caso de uso para o Widgetbook.
/// Simula a tela de chamada manual com uma turma fictícia.
@UseCase(
  name: 'Chamada Manual',
  type: TelaChamadaManual,
)
Widget buildTelaChamadaManual(BuildContext context) {
  return ProviderScope(
    child: TelaChamadaManual(
      turma: TurmaProfessor(
        id: 'mock_id', 
        nome: 'Cálculo 1', 
        horario: 'Seg 08:00', 
        local: 'Sala 10', 
        professorId: 'prof_id', 
        turmaCode: 'A1B2C3', 
        creditos: 4, 
        alunosInscritos: []
      ),
    ),
  );
}

/// Tela que permite ao professor registrar presença manualmente.
/// 
/// Funcionalidades:
/// - Listagem de todos os alunos inscritos.
/// - Checkbox para marcar presença/falta.
/// - Botão de "Marcar Todos" / "Limpar Todos".
/// - Seleção do tipo de chamada (Início ou Fim) ao salvar.
class TelaChamadaManual extends ConsumerStatefulWidget { 
  final TurmaProfessor turma;
  const TelaChamadaManual({super.key, required this.turma});

  @override
  ConsumerState<TelaChamadaManual> createState() => _TelaChamadaManualState(); 
}

class _TelaChamadaManualState extends ConsumerState<TelaChamadaManual> { 
  bool _isLoading = false; // Estado local de salvamento

  /// Abre o diálogo para confirmar o tipo de chamada e salva.
  Future<void> _onSalvar(BuildContext context, int presentesCount) async {
    final t = AppLocalizations.of(context)!;
    
    // Diálogo de seleção (Início ou Fim)
    final String? tipoChamada = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.t('prof_chamada_tipo_titulo')), // "Tipo de Chamada"
        content: Text(t.t('prof_chamada_tipo_desc')), // "Esta é a primeira (início) ou segunda (fim)?"
        actions: [
          TextButton(
            child: Text(t.t('prof_chamada_tipo_inicio')), // "Início"
            onPressed: () => Navigator.pop(ctx, 'inicio'),
          ),
          ElevatedButton(
            child: Text(t.t('prof_chamada_tipo_fim')), // "Fim"
            onPressed: () => Navigator.pop(ctx, 'fim'),
          ),
        ],
      ),
    );

    // Se cancelou o diálogo
    if (tipoChamada == null || !context.mounted) return; 

    setState(() => _isLoading = true);
    
    try {
      // Chama o notificador para salvar no Firebase
      await ref.read(provedorChamadaManual(widget.turma.id).notifier).salvarChamada(
        tipoChamada, 
        DateTime.now()
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.t('ca_presenca_salva_sucesso')} ($presentesCount presentes)'), 
            backgroundColor: Colors.green
          ),
        );
        Navigator.pop(context); // Volta para o hub
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('${t.t('erro_generico')}: $e'), backgroundColor: Colors.red),
         );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    // Acessa o estado da chamada (lista de alunos e status)
    final estadoChamada = ref.watch(provedorChamadaManual(widget.turma.id));
    final notifierChamada = ref.read(provedorChamadaManual(widget.turma.id).notifier);
    
    final presentesCount = estadoChamada.presentesCount;
    final totalAlunos = estadoChamada.totalAlunos;
    
    // Verifica se há algum bloqueio de horário (Apenas aviso visual)
    final asyncPreChamada = ref.watch(provedorPreChamada(widget.turma));

    return Scaffold(
      appBar: AppBar(title: Text(t.t('prof_chamada_manual_titulo'))), // "Chamada Manual"
      body: Column(
        children: [
          // Aviso de Bloqueio (se houver)
          asyncPreChamada.when(
            data: (estado) {
              if (!estado.podeChamar && estado.bloqueioMensagem != null) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.redAccent,
                  child: Text(
                    estado.bloqueioMensagem!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const LinearProgressIndicator(),
            error: (_,__) => const SizedBox.shrink(),
          ),

          // Cabeçalho com Contadores e Botões de Ação em Massa
          Container(
            padding: const EdgeInsets.all(16.0),
            color: theme.colorScheme.primary, 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.t('prof_presenca_presentes'), // "Presentes"
                      style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.8)),
                    ),
                    Text(
                      '$presentesCount / $totalAlunos',
                      style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Botão Marcar Todos
                    TextButton.icon(
                      icon: const Icon(Icons.check_box_outlined), 
                      label: Text(t.t('prof_chamada_manual_todos')), // "Todos"
                      onPressed: notifierChamada.toggleTodos, 
                      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onPrimary)
                    ),
                    const SizedBox(width: 8),
                    // Botão Limpar
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline), 
                      label: Text(t.t('prof_chamada_manual_limpar')), // "Limpar"
                      onPressed: notifierChamada.limparTodos, 
                      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onPrimary)
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Lista de Alunos (Checkboxes)
          Expanded(
            child: Builder(
              builder: (context) {
                // Verifica o status de carregamento
                if (estadoChamada.status == StatusChamadaManual.ocioso || estadoChamada.status == StatusChamadaManual.carregando) {
                   return const WidgetCarregamento(texto: 'Carregando alunos...');
                }
                
                if (estadoChamada.status == StatusChamadaManual.erro) {
                   return const Center(child: Text('Erro ao carregar lista de alunos.'));
                }

                // Lista carregada
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: estadoChamada.alunos.length,
                  itemBuilder: (context, index) {
                    final aluno = estadoChamada.alunos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: CheckboxListTile(
                        title: Text(aluno.nome),
                        subtitle: Text('RA: ${aluno.ra}'),
                        value: aluno.isPresente,
                        onChanged: (bool? value) {
                          notifierChamada.toggleAluno(aluno.id);
                        },
                        secondary: Icon(
                          aluno.isPresente ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: aluno.isPresente ? Colors.green : Colors.grey,
                        ),
                      ),
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
      
      // Botão Inferior de Salvar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        color: theme.cardTheme.color, 
        child: ElevatedButton.icon(
          icon: _isLoading 
              ? Container(width: 20, height: 20, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save),
          label: Text(_isLoading ? t.t('carregando') : t.t('prof_chamada_manual_salvar')), // "Salvar Chamada"
          onPressed: _isLoading ? null : () => _onSalvar(context, presentesCount),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}
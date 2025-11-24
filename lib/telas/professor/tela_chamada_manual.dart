// lib/telas/professor/tela_chamada_manual.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/turma_professor.dart';
import '../../providers/provedor_professor.dart';
import '../../l10n/app_localizations.dart';
import '../comum/widget_carregamento.dart';

class TelaChamadaManual extends ConsumerStatefulWidget { 
  final TurmaProfessor turma;
  const TelaChamadaManual({super.key, required this.turma});

  @override
  ConsumerState<TelaChamadaManual> createState() => _TelaChamadaManualState(); 
}

class _TelaChamadaManualState extends ConsumerState<TelaChamadaManual> { 
  bool _isLoading = false; 

  Future<void> _onSalvar(BuildContext context, int presentesCount) async {
    final t = AppLocalizations.of(context)!;
    
    final String? tipoChamada = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.t('prof_chamada_tipo_titulo')),
        content: Text(t.t('prof_chamada_tipo_desc')),
        actions: [
          TextButton(
            child: Text(t.t('prof_chamada_tipo_inicio')),
            onPressed: () => Navigator.pop(ctx, 'inicio'),
          ),
          ElevatedButton(
            child: Text(t.t('prof_chamada_tipo_fim')),
            onPressed: () => Navigator.pop(ctx, 'fim'),
          ),
        ],
      ),
    );

    if (tipoChamada == null || !context.mounted) return; 

    setState(() => _isLoading = true);
    
    try {
      await ref.read(provedorChamadaManual(widget.turma.id).notifier).salvarChamada(
        tipoChamada, 
        DateTime.now()
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chamada ($tipoChamada) salva! $presentesCount alunos presentes.'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
      );
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
    
    final estadoChamada = ref.watch(provedorChamadaManual(widget.turma.id));
    final notifierChamada = ref.read(provedorChamadaManual(widget.turma.id).notifier);
    final presentesCount = estadoChamada.presentesCount;
    final totalAlunos = estadoChamada.totalAlunos;
    
    // AVISO DE BLOQUEIO
    final asyncPreChamada = ref.watch(provedorPreChamada(widget.turma));

    return Scaffold(
      appBar: AppBar(title: Text(t.t('prof_chamada_manual_titulo'))),
      body: Column(
        children: [
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
                      t.t('prof_presenca_presentes'),
                      style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onPrimary.withOpacity(0.8),
                            ),
                    ),
                    Text(
                      '$presentesCount / $totalAlunos',
                      style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.check_box_outlined),
                      label: Text(t.t('prof_chamada_manual_todos')),
                      onPressed: notifierChamada.toggleTodos,
                      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onPrimary),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: Text(t.t('prof_chamada_manual_limpar')),
                      onPressed: notifierChamada.limparTodos,
                      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (estadoChamada.status) {
              StatusChamadaManual.ocioso || StatusChamadaManual.carregando =>
                const WidgetCarregamento(texto: 'Carregando alunos...'),
              
              StatusChamadaManual.erro =>
                const Center(child: Text('Erro ao carregar lista de alunos.')),
              
              StatusChamadaManual.pronto =>
                ListView.builder(
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
                ),
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        color: theme.cardTheme.color, 
        child: ElevatedButton.icon(
          icon: _isLoading 
              ? Container(width: 20, height: 20, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save),
          label: Text(_isLoading ? 'Verificando...' : t.t('prof_chamada_manual_salvar')), 
          onPressed: _isLoading ? null : () => _onSalvar(context, presentesCount),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}
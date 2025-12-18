// lib/telas/professor/tela_historico_chamadas.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../../models/turma_professor.dart';
import '../../models/aluno_chamada.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../comum/widget_carregamento.dart';

@UseCase(
  name: 'Histórico de Chamadas',
  type: TelaHistoricoChamadas,
)
Widget buildTelaHistoricoChamadas(BuildContext context) {
  return ProviderScope(
    child: TelaHistoricoChamadas(
      turma: TurmaProfessor(
        id: 'mock', nome: 'Mock', horario: '', local: '', 
        professorId: '', turmaCode: '', creditos: 4, alunosInscritos: []
      )
    ),
  );
}

// =============================================================================
// PROVIDERS CORRIGIDOS
// =============================================================================

// 1. FUTUREProvider para garantir que complete e não fique esperando stream
final historicoDatasProvider = FutureProvider.family<List<String>, String>((ref, turmaId) async {
  // Chama o serviço. Se der erro, o Provider captura.
  return await ref.read(servicoFirestoreProvider).getDatasChamadas(turmaId);
});

// 2. Busca os detalhes de um dia específico
final detalhesChamadaProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, Map<String, String>>((ref, args) async {
  final servico = ref.read(servicoFirestoreProvider);
  final turmaId = args['turmaId']!;
  final dataId = args['dataId']!;

  try {
    final results = await Future.wait([
      servico.getAlunosDaTurma(turmaId),
      servico.getDadosChamada(turmaId, dataId),
    ]);

    return {
      'alunos': results[0] as List<AlunoChamada>,
      'presenca': results[1] as Map<String, dynamic>,
    };
  } catch (e) {
    debugPrint("Erro ao carregar detalhes: $e");
    // Retorna vazio para não travar a UI
    return {'alunos': <AlunoChamada>[], 'presenca': <String, dynamic>{}};
  }
});

// =============================================================================
// TELA PRINCIPAL (LISTA DE DATAS)
// =============================================================================

class TelaHistoricoChamadas extends ConsumerWidget {
  final TurmaProfessor turma;
  const TelaHistoricoChamadas({super.key, required this.turma});

  void _mostrarDetalhesChamada(BuildContext context, String dataId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SheetDetalhesChamadaEditavel(turmaId: turma.id, dataId: dataId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final asyncDatas = ref.watch(historicoDatasProvider(turma.id));
    
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t.t('prof_historico'), 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: asyncDatas.when(
        loading: () => const WidgetCarregamento(texto: "Carregando histórico..."),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text("${t.t('erro_generico')}: $e", textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (datas) {
          if (datas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(t.t('prof_historico_vazio'), style: TextStyle(color: textColor?.withOpacity(0.7))),
                ],
              ),
            );
          }
          
          final listaOrdenada = List<String>.from(datas);
          listaOrdenada.sort((a, b) => b.compareTo(a)); // Decrescente

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listaOrdenada.length,
            itemBuilder: (context, index) {
              final dataString = listaOrdenada[index];
              String labelData = dataString;
              
              try {
                final dt = DateFormat('yyyy-MM-dd').parse(dataString);
                labelData = DateFormat('dd ' 'MMMM' ' yyyy', 'pt_BR').format(dt);
              } catch (_) {}

              return Card(
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_calendar, color: AppColors.primaryPurple),
                  ),
                  title: Text(labelData.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () => _mostrarDetalhesChamada(context, dataString),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =============================================================================
// SHEET DE DETALHES EDITÁVEL
// =============================================================================

class _SheetDetalhesChamadaEditavel extends ConsumerStatefulWidget {
  final String turmaId;
  final String dataId;

  const _SheetDetalhesChamadaEditavel({required this.turmaId, required this.dataId});

  @override
  ConsumerState<_SheetDetalhesChamadaEditavel> createState() => _SheetDetalhesChamadaEditavelState();
}

class _SheetDetalhesChamadaEditavelState extends ConsumerState<_SheetDetalhesChamadaEditavel> {
  final Set<String> _presentesIds = {};
  bool _isInit = true;
  bool _isSaving = false;
  bool _hasChanges = false; 

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    final asyncDetalhes = ref.watch(detalhesChamadaProvider({'turmaId': widget.turmaId, 'dataId': widget.dataId}));

    String tituloData = widget.dataId;
    try {
      final dt = DateFormat('yyyy-MM-dd').parse(widget.dataId);
      tituloData = DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {}

    return Container(
      height: MediaQuery.of(context).size.height * 0.85, 
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Puxador visual
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${t.t('prof_presenca')} - $tituloData", 
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              if (_hasChanges)
                const Chip(label: Text("Editado", style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.orange),
            ],
          ),
          const SizedBox(height: 4),
          const Text("Toque para alterar presença", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          
          // Conteúdo da Lista
          Expanded(
            child: asyncDetalhes.when(
              loading: () => const WidgetCarregamento(),
              error: (e, _) => Center(child: Text("Erro: $e")),
              data: (data) {
                final alunos = data['alunos'] as List<AlunoChamada>;
                final dadosPresenca = data['presenca'] as Map<String, dynamic>;
                
                // Inicializa o Set local apenas uma vez
                if (_isInit) {
                  final pInicio = List<String>.from(dadosPresenca['presentes_inicio'] ?? []);
                  // Ignora 'fim' para simplificar a edição visual, foca no principal
                  _presentesIds.addAll(pInicio);
                  _isInit = false;
                }

                if (alunos.isEmpty) {
                  return Center(child: Text(t.t('prof_sem_alunos')));
                }

                return ListView.separated(
                  itemCount: alunos.length,
                  separatorBuilder: (_,__) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final aluno = alunos[index];
                    final isPresent = _presentesIds.contains(aluno.id);

                    return SwitchListTile(
                      activeColor: AppColors.success,
                      contentPadding: EdgeInsets.zero,
                      title: Text(aluno.nome, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                      subtitle: Text("RA: ${aluno.ra}", style: TextStyle(color: textColor?.withOpacity(0.6), fontSize: 12)),
                      secondary: CircleAvatar(
                        backgroundColor: isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        child: Icon(isPresent ? Icons.check : Icons.close, color: isPresent ? Colors.green : Colors.red, size: 20),
                      ),
                      value: isPresent,
                      onChanged: (val) {
                        setState(() {
                          if (val) _presentesIds.add(aluno.id);
                          else _presentesIds.remove(aluno.id);
                          _hasChanges = true;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Botão Salvar
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasChanges ? AppColors.primaryPurple : Colors.grey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                t.t('prof_historico_salvar'), 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
              ),
              onPressed: (_hasChanges && !_isSaving) ? () async {
                setState(() => _isSaving = true);
                try {
                  DateTime dataParaSalvar = DateTime.now();
                  try {
                     dataParaSalvar = DateFormat('yyyy-MM-dd').parse(widget.dataId);
                  } catch (_) {}

                  await ref.read(servicoFirestoreProvider).salvarPresenca(
                    widget.turmaId, 
                    'inicio', // Salva como inicio (padrão)
                    _presentesIds.toList(), 
                    dataParaSalvar // Usa a data original do histórico, não HOJE
                  );
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.t('prof_historico_sucesso')), backgroundColor: Colors.green)
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
                  }
                }
              } : null,
            ),
          )
        ],
      ),
    );
  }
}
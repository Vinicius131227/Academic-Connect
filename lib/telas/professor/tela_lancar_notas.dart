// lib/telas/professor/tela_lancar_notas.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../../models/turma_professor.dart';
import '../../models/aluno_chamada.dart'; 
import '../../models/prova_agendada.dart'; 
import '../../providers/provedor_professor.dart';
import '../../services/servico_firestore.dart'; 
import '../comum/widget_carregamento.dart'; 
import '../../l10n/app_localizations.dart';

@UseCase(
  name: 'Lançar Notas',
  type: TelaLancarNotas,
)
Widget buildTelaLancarNotas(BuildContext context) {
  return ProviderScope(
    child: TelaLancarNotas(
      turma: TurmaProfessor(
        id: 'mock', 
        nome: 'Cálculo 1', 
        horario: '', 
        local: '', 
        professorId: '', 
        turmaCode: '', 
        creditos: 4, 
        alunosInscritos: []
      ),
    ),
  );
}

class TelaLancarNotas extends ConsumerStatefulWidget {
  final TurmaProfessor turma;
  
  const TelaLancarNotas({
    super.key, 
    required this.turma
  });

  @override
  ConsumerState<TelaLancarNotas> createState() => _TelaLancarNotasState();
}

class _TelaLancarNotasState extends ConsumerState<TelaLancarNotas> {
  String? _avaliacaoSelecionada;
  bool _isSaving = false;
  bool _isLoadingNotas = false;
  
  final Map<String, TextEditingController> _controllers = {};
  List<ProvaAgendada> _provasDisponiveis = []; 
  bool _isLoadingProvas = true;

  @override
  void initState() {
    super.initState();
    _carregarProvasDaTurma();
  }

  Future<void> _carregarProvasDaTurma() async {
    final servico = ref.read(servicoFirestoreProvider);
    try {
      final snapshot = await servico.getCalendarioDeProvas().first; 
      
      if (mounted) {
        setState(() {
          _provasDisponiveis = snapshot.where((p) => p.turmaId == widget.turma.id).toList();
          _isLoadingProvas = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProvas = false);
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  void _inicializarControllers(List<AlunoChamada> alunos) {
    if (_controllers.isNotEmpty) return; 
    for (var aluno in alunos) {
      _controllers[aluno.id] = TextEditingController();
    }
  }

  Future<void> _carregarNotasExistentes(String avaliacao, List<AlunoChamada> alunos) async {
    setState(() {
      _avaliacaoSelecionada = avaliacao;
      _isLoadingNotas = true; 
    });

    await ref.read(provedorNotas.notifier).carregarNotas(widget.turma.id, avaliacao);
    final notas = ref.read(provedorNotas);
    
    for (var aluno in alunos) {
      final nota = notas[aluno.id];
      _controllers[aluno.id]?.text = nota?.toString() ?? '';
    }

    if (mounted) setState(() => _isLoadingNotas = false);
  }

  Future<void> _salvarNotas() async {
    if (_avaliacaoSelecionada == null) return;
    
    setState(() => _isSaving = true);
    final notifier = ref.read(provedorNotas.notifier);
    final t = AppLocalizations.of(context)!;
    
    _controllers.forEach((alunoId, controller) {
      final nota = double.tryParse(controller.text.replaceAll(',', '.')); 
      notifier.atualizarNota(alunoId, nota);
    });
    
    try {
      await notifier.salvarNotas(widget.turma.id, _avaliacaoSelecionada!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('ca_presenca_salva_sucesso')), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('${t.t('erro_generico')}: $e'), backgroundColor: Colors.red)
         );
       }
    } finally {
       if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final estadoAlunos = ref.watch(provedorChamadaManual(widget.turma.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('prof_lancar_notas')),
      ),
      body: _isLoadingProvas 
        ? const WidgetCarregamento(texto: "Buscando avaliações...")
        : _provasDisponiveis.isEmpty
            // --- BLOCO "SEM PROVAS" ---
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_late_outlined, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 20),
                      Text(
                        "Nenhuma avaliação encontrada",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Você precisa agendar uma prova ou criar uma atividade no calendário antes de lançar notas.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text("Voltar"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    ],
                  ),
                ),
              )
            // -------------------------------------------
            : Column(
                children: [
                  // 1. SELETOR DE AVALIAÇÃO
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DropdownButtonFormField<String>(
                      value: _avaliacaoSelecionada,
                      hint: Text(t.t('notas_avaliacao')),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: _provasDisponiveis.map((prova) {
                        return DropdownMenuItem<String>(
                          value: prova.titulo, 
                          child: Text(prova.titulo),
                        );
                      }).toList(),
                      onChanged: (_isSaving || estadoAlunos.status == StatusChamadaManual.carregando) 
                          ? null 
                          : (newValue) {
                              if (newValue != null) _carregarNotasExistentes(newValue, estadoAlunos.alunos);
                            },
                    ),
                  ),
                  
                  // 2. LISTA DE ALUNOS
                  if (_avaliacaoSelecionada != null)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          if (estadoAlunos.status == StatusChamadaManual.carregando || _isLoadingNotas) {
                            return const WidgetCarregamento();
                          }
                          if (estadoAlunos.status == StatusChamadaManual.erro) {
                            return const Center(child: Text('Erro ao carregar alunos.'));
                          }

                          _inicializarControllers(estadoAlunos.alunos);
                          
                          if (estadoAlunos.alunos.isEmpty) {
                            return Center(child: Text(t.t('prof_presenca_nfc_vazio')));
                          }
                          
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: estadoAlunos.alunos.length,
                            itemBuilder: (context, index) {
                              final aluno = estadoAlunos.alunos[index];
                              return Card(
                                child: ListTile(
                                  title: Text(aluno.nome),
                                  subtitle: Text(aluno.ra),
                                  trailing: SizedBox(
                                    width: 80,
                                    child: TextFormField(
                                      controller: _controllers[aluno.id],
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(hintText: '0.0'),
                                    ),
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
      
      // 3. BOTÃO SALVAR (Só aparece se tiver provas e uma selecionada)
      bottomNavigationBar: (_avaliacaoSelecionada == null || _provasDisponiveis.isEmpty) 
          ? null 
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Icon(Icons.save),
                label: Text(_isSaving ? t.t('carregando') : t.t('salvar')),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _isSaving ? null : _salvarNotas,
              ),
            ),
    );
  }
}
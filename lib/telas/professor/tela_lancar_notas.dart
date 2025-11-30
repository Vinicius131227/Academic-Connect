// lib/telas/professor/tela_lancar_notas.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/turma_professor.dart';
import '../../models/aluno_chamada.dart'; 
import '../../models/prova_agendada.dart'; 
import '../../providers/provedor_professor.dart'; // Contém o provedor de Notas e Chamada
import '../../services/servico_firestore.dart'; 
import '../comum/widget_carregamento.dart'; 
import '../../l10n/app_localizations.dart';

/// Caso de uso para o Widgetbook.
/// Simula a tela de lançamento de notas.
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

/// Tela para lançamento de notas em lote.
/// 
/// O professor seleciona uma avaliação (criada na tela de marcar prova)
/// e preenche as notas de cada aluno.
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
  
  // Controladores para os campos de nota de cada aluno (Map<AlunoID, Controller>)
  final Map<String, TextEditingController> _controllers = {};
  
  // Lista de provas disponíveis para lançar nota
  List<ProvaAgendada> _provasDisponiveis = []; 
  bool _isLoadingProvas = true;

  @override
  void initState() {
    super.initState();
    _carregarProvasDaTurma();
  }

  /// Busca as provas cadastradas para popular o Dropdown.
  Future<void> _carregarProvasDaTurma() async {
    final servico = ref.read(servicoFirestoreProvider);
    try {
      // Busca todas as provas do sistema e filtra localmente (MVP)
      // Em produção, usaria uma query específica .where('turmaId', ...)
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

  /// Cria um controlador de texto para cada aluno se ainda não existir.
  void _inicializarControllers(List<AlunoChamada> alunos) {
    if (_controllers.isNotEmpty) return; 
    for (var aluno in alunos) {
      _controllers[aluno.id] = TextEditingController();
    }
  }

  /// Carrega as notas que já foram lançadas para a avaliação selecionada.
  Future<void> _carregarNotasExistentes(String avaliacao, List<AlunoChamada> alunos) async {
    setState(() {
      _avaliacaoSelecionada = avaliacao;
      _isLoadingNotas = true; 
    });

    await ref.read(provedorNotas.notifier).carregarNotas(widget.turma.id, avaliacao);
    final notas = ref.read(provedorNotas);
    
    // Preenche os campos de texto com os valores do banco
    for (var aluno in alunos) {
      final nota = notas[aluno.id];
      _controllers[aluno.id]?.text = nota?.toString() ?? '';
    }

    if (mounted) setState(() => _isLoadingNotas = false);
  }

  /// Salva as notas digitadas no Firestore.
  Future<void> _salvarNotas() async {
    if (_avaliacaoSelecionada == null) return;
    
    setState(() => _isSaving = true);
    final notifier = ref.read(provedorNotas.notifier);
    final t = AppLocalizations.of(context)!;
    
    // Atualiza o estado do provedor com os valores dos controllers
    _controllers.forEach((alunoId, controller) {
      final nota = double.tryParse(controller.text.replaceAll(',', '.')); 
      notifier.atualizarNota(alunoId, nota);
    });
    
    try {
      await notifier.salvarNotas(widget.turma.id, _avaliacaoSelecionada!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('ca_presenca_salva_sucesso')), backgroundColor: Colors.green) // "Salvo com sucesso"
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
    
    // Obtém a lista de alunos da turma
    final estadoAlunos = ref.watch(provedorChamadaManual(widget.turma.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('prof_lancar_notas')), // "Lançar Notas"
      ),
      body: Column(
        children: [
          // 1. SELETOR DE AVALIAÇÃO
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoadingProvas 
              ? const LinearProgressIndicator()
              : DropdownButtonFormField<String>(
                  value: _avaliacaoSelecionada,
                  hint: Text(t.t('notas_avaliacao')), // "Avaliação"
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: _provasDisponiveis.map((prova) {
                    return DropdownMenuItem<String>(
                      value: prova.titulo, 
                      child: Text(prova.titulo),
                    );
                  }).toList(),
                  // Bloqueia se estiver carregando alunos ou salvando
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
                  // Verifica estado da lista de alunos
                  if (estadoAlunos.status == StatusChamadaManual.carregando || _isLoadingNotas) {
                    return const WidgetCarregamento();
                  }
                  if (estadoAlunos.status == StatusChamadaManual.erro) {
                    return const Center(child: Text('Erro ao carregar alunos.'));
                  }

                  _inicializarControllers(estadoAlunos.alunos);
                  
                  if (estadoAlunos.alunos.isEmpty) {
                    return Center(child: Text(t.t('prof_presenca_nfc_vazio'))); // "Nenhum aluno..."
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
      
      // 3. BOTÃO SALVAR
      bottomNavigationBar: _avaliacaoSelecionada == null ? null : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
              : const Icon(Icons.save),
          label: Text(_isSaving ? t.t('carregando') : t.t('salvar')), // "Salvando..." / "Salvar"
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: _isSaving ? null : _salvarNotas,
        ),
      ),
    );
  }
}
// lib/telas/professor/tela_lancar_notas.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/turma_professor.dart';
import '../../models/aluno_chamada.dart'; 
import '../../models/prova_agendada.dart'; // Import do model de prova
import '../../providers/provedor_professor.dart';
import '../../services/servico_firestore.dart'; // Para buscar as provas
import '../comum/widget_carregamento.dart'; 

class TelaLancarNotas extends ConsumerStatefulWidget {
  final TurmaProfessor turma;
  const TelaLancarNotas({super.key, required this.turma});

  @override
  ConsumerState<TelaLancarNotas> createState() => _TelaLancarNotasState();
}

class _TelaLancarNotasState extends ConsumerState<TelaLancarNotas> {
  String? _avaliacaoSelecionada;
  bool _isSaving = false;
  bool _isLoadingNotas = false;
  
  Map<String, TextEditingController> _controllers = {};
  List<ProvaAgendada> _provasDisponiveis = []; // Lista dinâmica
  bool _isLoadingProvas = true;

  @override
  void initState() {
    super.initState();
    _carregarProvasDaTurma();
  }

  // Busca as provas cadastradas para popular o Dropdown
  Future<void> _carregarProvasDaTurma() async {
    final servico = ref.read(servicoFirestoreProvider);
    // Precisamos criar um método simples no serviço para isso ou usar um stream existente
    // Aqui vamos reusar o stream de calendario, mas filtrando, ou fazer um get direto.
    // Para simplificar e evitar criar mais metodos agora, vamos fazer uma query direta aqui.
    // O ideal seria mover para o provider.
    try {
      final snapshot = await servico.getCalendarioDeProvas().first; // Pega o primeiro valor do stream
      setState(() {
        _provasDisponiveis = snapshot.where((p) => p.turmaId == widget.turma.id).toList();
        _isLoadingProvas = false;
      });
    } catch (e) {
      setState(() => _isLoadingProvas = false);
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  void _inicializarControllers(List<AlunoChamada> alunos) {
    if (_controllers.isNotEmpty) return; // Evita recriar
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
    
    _controllers.forEach((alunoId, controller) {
      final nota = double.tryParse(controller.text.replaceAll(',', '.')); // Suporte a vírgula
      notifier.atualizarNota(alunoId, nota);
    });
    
    try {
      await notifier.salvarNotas(widget.turma.id, _avaliacaoSelecionada!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notas salvas!'), backgroundColor: Colors.green));
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    } finally {
       if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoAlunos = ref.watch(provedorChamadaManual(widget.turma.id));

    return Scaffold(
      appBar: AppBar(title: Text('Lançar Notas - ${widget.turma.nome}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoadingProvas 
              ? const LinearProgressIndicator()
              : DropdownButtonFormField<String>(
                  value: _avaliacaoSelecionada,
                  hint: const Text('Selecione uma avaliação'),
                  decoration: const InputDecoration(labelText: 'Avaliação', border: OutlineInputBorder()),
                  items: _provasDisponiveis.map((prova) {
                    return DropdownMenuItem<String>(
                      value: prova.titulo, // Usa o título da prova
                      child: Text(prova.titulo),
                    );
                  }).toList(),
                  onChanged: (_isSaving || estadoAlunos.status != StatusChamadaManual.pronto) ? null : (newValue) {
                    if (newValue != null) _carregarNotasExistentes(newValue, estadoAlunos.alunos);
                  },
                ),
          ),
          
          if (_avaliacaoSelecionada != null)
            Expanded(
              child: switch (estadoAlunos.status) {
                StatusChamadaManual.ocioso || StatusChamadaManual.carregando => const WidgetCarregamento(),
                StatusChamadaManual.erro => const Center(child: Text('Erro ao carregar alunos.')),
                StatusChamadaManual.pronto => _isLoadingNotas 
                  ? const WidgetCarregamento()
                  : Builder(
                      builder: (context) {
                        _inicializarControllers(estadoAlunos.alunos);
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
              },
            ),
        ],
      ),
      bottomNavigationBar: _avaliacaoSelecionada == null ? null : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
          label: Text(_isSaving ? 'Salvando...' : 'Salvar Notas'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: _isSaving ? null : _salvarNotas,
        ),
      ),
    );
  }
}
// lib/telas/professor/tela_editar_turma.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/turma_professor.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../comum/overlay_carregamento.dart';

class TelaEditarTurma extends ConsumerStatefulWidget {
  final TurmaProfessor turma;
  const TelaEditarTurma({super.key, required this.turma});

  @override
  ConsumerState<TelaEditarTurma> createState() => _TelaEditarTurmaState();
}

class _HorarioItem {
  String dia;
  TimeOfDay inicio;
  TimeOfDay fim;
  _HorarioItem({required this.dia, required this.inicio, required this.fim});
}

class _TelaEditarTurmaState extends ConsumerState<TelaEditarTurma> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _salaController;
  
  String? _predioSelecionado;
  final List<_HorarioItem> _horarios = [];
  final List<String> _diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.turma.nome);
    
    // Parse do local (Ex: "AT1 - 102")
    final localParts = widget.turma.local.split(' - ');
    if (localParts.length > 1) {
      _predioSelecionado = AppLocalizations.predios.contains(localParts[0]) ? localParts[0] : null;
      _salaController = TextEditingController(text: localParts[1]);
    } else {
      _salaController = TextEditingController(text: widget.turma.local);
    }

    // Parse dos horários (Ex: "Seg 08:00-10:00, Qua 14:00-16:00")
    final horariosStr = widget.turma.horario.split(', ');
    for (var h in horariosStr) {
      try {
        // Formato esperado: "Seg 08:00-10:00"
        final parts = h.split(' ');
        final dia = parts[0];
        final times = parts[1].split('-');
        final start = times[0].split(':');
        final end = times[1].split(':');
        
        _horarios.add(_HorarioItem(
          dia: dia,
          inicio: TimeOfDay(hour: int.parse(start[0]), minute: int.parse(start[1])),
          fim: TimeOfDay(hour: int.parse(end[0]), minute: int.parse(end[1])),
        ));
      } catch (e) {
        // Ignora erros de parse
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _salaController.dispose();
    super.dispose();
  }

  String _gerarStringHorario() {
    return _horarios.map((h) {
      final inicio = '${h.inicio.hour.toString().padLeft(2,'0')}:${h.inicio.minute.toString().padLeft(2,'0')}';
      final fim = '${h.fim.hour.toString().padLeft(2,'0')}:${h.fim.minute.toString().padLeft(2,'0')}';
      return '${h.dia} $inicio-$fim';
    }).join(', ');
  }

  int _calcularCreditosAuto() {
    int minutosTotais = 0;
    for (var h in _horarios) {
      final inicio = h.inicio.hour * 60 + h.inicio.minute;
      final fim = h.fim.hour * 60 + h.fim.minute;
      minutosTotais += (fim - inicio);
    }
    return (minutosTotais / 60).round();
  }

  void _adicionarHorario() {
    setState(() {
      _horarios.add(_HorarioItem(
        dia: 'Seg', 
        inicio: const TimeOfDay(hour: 8, minute: 0), 
        fim: const TimeOfDay(hour: 10, minute: 0)
      ));
    });
  }

  void _removerHorario(int index) {
    setState(() {
      _horarios.removeAt(index);
    });
  }

  Future<void> _salvarTurma() async {
    if (!_formKey.currentState!.validate() || _predioSelecionado == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Preencha todos os campos e selecione o prédio.'), backgroundColor: Colors.red),
       );
       return;
    }
    if (_horarios.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Adicione pelo menos um horário.'), backgroundColor: Colors.red),
       );
       return;
    }

    ref.read(provedorCarregando.notifier).state = true;
    
    try {
      // Cria um novo objeto com os dados atualizados, mantendo ID e Código
      final turmaAtualizada = TurmaProfessor(
        id: widget.turma.id,
        nome: _nomeController.text.trim(),
        horario: _gerarStringHorario(),
        local: '$_predioSelecionado - ${_salaController.text}',
        professorId: widget.turma.professorId,
        turmaCode: widget.turma.turmaCode,
        creditos: _calcularCreditosAuto(),
        alunosInscritos: widget.turma.alunosInscritos,
      );

      await ref.read(servicoFirestoreProvider).atualizarTurma(turmaAtualizada);

      if (mounted) {
        ref.read(provedorCarregando.notifier).state = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turma atualizada com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ref.read(provedorCarregando.notifier).state = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estaCarregando = ref.watch(provedorCarregando);
    final t = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Turma')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: t.t('criar_turma_nome'),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              
              // Local
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _predioSelecionado,
                      decoration: const InputDecoration(labelText: 'Prédio', border: OutlineInputBorder()),
                      items: AppLocalizations.predios.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: estaCarregando ? null : (v) => setState(() => _predioSelecionado = v),
                      validator: (v) => v == null ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _salaController,
                      decoration: const InputDecoration(labelText: 'Sala', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Horários
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Horários das Aulas', style: Theme.of(context).textTheme.titleMedium),
                  IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: _adicionarHorario),
                ],
              ),
              const Divider(),
              
              ..._horarios.asMap().entries.map((entry) {
                int index = entry.key;
                _HorarioItem item = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        DropdownButton<String>(
                          value: item.dia,
                          items: _diasSemana.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (v) => setState(() => item.dia = v!),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          child: Text('${item.inicio.format(context)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () async {
                            final t = await showTimePicker(context: context, initialTime: item.inicio);
                            if (t != null) setState(() => item.inicio = t);
                          },
                        ),
                        const Text(' - '),
                        InkWell(
                          child: Text('${item.fim.format(context)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () async {
                            final t = await showTimePicker(context: context, initialTime: item.fim);
                            if (t != null) setState(() => item.fim = t);
                          },
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removerHorario(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: estaCarregando 
                  ? Container(width: 20, height: 20, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
                label: const Text('Salvar Alterações'), 
                onPressed: estaCarregando ? null : _salvarTurma,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
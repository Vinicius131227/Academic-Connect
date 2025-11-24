// lib/telas/professor/tela_criar_turma.dart
import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/turma_professor.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../comum/overlay_carregamento.dart';

class TelaCriarTurma extends ConsumerStatefulWidget {
  const TelaCriarTurma({super.key});

  @override
  ConsumerState<TelaCriarTurma> createState() => _TelaCriarTurmaState();
}

class _HorarioItem {
  String dia;
  TimeOfDay inicio;
  TimeOfDay fim;
  _HorarioItem({required this.dia, required this.inicio, required this.fim});
}

class _TelaCriarTurmaState extends ConsumerState<TelaCriarTurma> {
  final _formKey = GlobalKey<FormState>();
  
  final _nomeController = TextEditingController();
  final _localController = TextEditingController(); 
  final _salaController = TextEditingController(); 
  
  String? _predioSelecionado;
  int _creditosSelecionados = 4; 

  // Lista de horários
  final List<_HorarioItem> _horarios = [];
  final List<String> _diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];

  @override
  void dispose() {
    _nomeController.dispose();
    _localController.dispose();
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

  // --- NOVA LÓGICA: VALIDAÇÃO DE HORÁRIO ---
  bool _isHorarioAlmoco(TimeOfDay time) {
    // Intervalo proibido: 12:00 até 13:59 (Basicamente, não pode ter aula entre 12 e 14)
    // Se começar às 12:00 -> Erro
    // Se terminar às 12:00 -> OK
    // Se começar às 14:00 -> OK
    // Se terminar às 13:30 -> Erro
    double t = time.hour + (time.minute / 60.0);
    return t > 12.0 && t < 14.0; // Bloqueia estritamente DENTRO do intervalo
  }
  
  // Verifica se o intervalo cruza o almoço (ex: 11:00 as 15:00)
  bool _cruzaAlmoco(TimeOfDay inicio, TimeOfDay fim) {
      double start = inicio.hour + (inicio.minute / 60.0);
      double end = fim.hour + (fim.minute / 60.0);
      return start < 12.0 && end > 14.0;
  }

  void _adicionarHorario() {
    // REGRA: Máximo 2 dias
    if (_horarios.length >= 2) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Máximo de 2 dias por disciplina permitido.'), backgroundColor: Colors.orange),
       );
       return;
    }

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
  
  Future<void> _pickTime(int index, bool isInicio) async {
    final item = _horarios[index];
    final initial = isInicio ? item.inicio : item.fim;
    
    final t = await showTimePicker(context: context, initialTime: initial);
    if (t == null) return;

    // VALIDAÇÃO DE ALMOÇO
    if ((t.hour >= 12 && t.hour < 14)) { 
         // Permite exatamento 14:00 como inicio ou 12:00 como fim?
         // Regra pedida: "nao pode escolher das 12 as 14"
         bool invalido = true;
         if (isInicio && t.hour == 14 && t.minute == 0) invalido = false; // Pode começar 14:00
         if (!isInicio && t.hour == 12 && t.minute == 0) invalido = false; // Pode terminar 12:00
         
         if (invalido) {
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Horário de almoço (12:00 - 14:00) não permitido.'), backgroundColor: Colors.red),
                );
            }
            return;
         }
    }

    setState(() {
      if (isInicio) {
        item.inicio = t;
      } else {
        item.fim = t;
      }
    });
  }

  String _gerarCodigoAleatorio({int length = 6}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  void _mostrarDialogCodigo(BuildContext context, String codigo) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(t.t('criar_turma_sucesso')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.t('criar_turma_codigo_desc')),
            const SizedBox(height: 16),
            Center(
              child: SelectableText(
                codigo,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            child: Text(t.t('criar_turma_ok')),
            onPressed: () {
              Navigator.pop(ctx); 
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _salvarTurma() async {
    if (!_formKey.currentState!.validate() || _predioSelecionado == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Por favor, preencha todos os campos e selecione o prédio.'), backgroundColor: Colors.red),
       );
       return;
    }
    if (_horarios.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Adicione pelo menos um horário.'), backgroundColor: Colors.red),
       );
       return;
    }
    
    // Validação final de almoço
    for (var h in _horarios) {
        if (_cruzaAlmoco(h.inicio, h.fim)) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Uma das aulas cruza o horário de almoço (12-14h). Ajuste.'), backgroundColor: Colors.red),
             );
             return;
        }
    }

    final professorId = ref.read(provedorNotificadorAutenticacao).usuario?.uid;
    if (professorId == null) return;

    ref.read(provedorCarregando.notifier).state = true;
    
    try {
      final novaTurma = TurmaProfessor(
        id: '',
        nome: _nomeController.text,
        horario: _gerarStringHorario(),
        local: '$_predioSelecionado - ${_salaController.text}',
        professorId: professorId,
        turmaCode: '',
        creditos: _creditosSelecionados,
        alunosInscritos: [],
      );

      final String codigoGerado = await ref.read(servicoFirestoreProvider).criarTurma(novaTurma);

      if (mounted) {
        ref.read(provedorCarregando.notifier).state = false;
        _mostrarDialogCodigo(context, codigoGerado);
      }
    } catch (e) {
      if (mounted) {
        ref.read(provedorCarregando.notifier).state = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar turma: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final estaCarregando = ref.watch(provedorCarregando);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('criar_turma_titulo')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        value: _creditosSelecionados,
                        decoration: const InputDecoration(labelText: 'Créditos da Disciplina *'),
                        items: [4, 2].map((int value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value Créditos'),
                        )).toList(),
                        onChanged: estaCarregando ? null : (v) => setState(() => _creditosSelecionados = v!),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nomeController,
                        decoration: InputDecoration(
                          labelText: t.t('criar_turma_nome'),
                          hintText: t.t('criar_turma_nome_hint'),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // O campo de horário manual foi removido em favor da lista dinâmica abaixo
                      
                      // Local (Prédio e Sala)
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _predioSelecionado,
                              decoration: const InputDecoration(labelText: 'Prédio *'),
                              items: AppLocalizations.predios.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                              onChanged: estaCarregando ? null : (v) => setState(() => _predioSelecionado = v),
                              validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _salaController,
                              decoration: const InputDecoration(
                                labelText: 'Sala *',
                                hintText: 'Ex: 105',
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Seção de Horários Dinâmicos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Horários das Aulas (Max 2 dias)', style: Theme.of(context).textTheme.titleMedium),
                  // Só permite adicionar se tiver menos de 2
                  IconButton(
                    icon: Icon(Icons.add_circle, color: _horarios.length < 2 ? Colors.green : Colors.grey), 
                    onPressed: _horarios.length < 2 ? _adicionarHorario : null
                  ),
                ],
              ),
              const Divider(),
              
              if (_horarios.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text('Adicione os dias e horários.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),

              ..._horarios.asMap().entries.map((entry) {
                int index = entry.key;
                _HorarioItem item = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Dia da Semana
                        DropdownButton<String>(
                          value: item.dia,
                          items: _diasSemana.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (v) => setState(() => item.dia = v!),
                        ),
                        const SizedBox(width: 16),
                        // Hora Início
                        InkWell(
                          child: Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                             child: Text('${item.inicio.format(context)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          onTap: () => _pickTime(index, true),
                        ),
                        const Text(' às '),
                        // Hora Fim
                        InkWell(
                          child: Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                             child: Text('${item.fim.format(context)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          onTap: () => _pickTime(index, false),
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
                label: Text(estaCarregando ? 'Salvando...' : t.t('criar_turma_botao')), 
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
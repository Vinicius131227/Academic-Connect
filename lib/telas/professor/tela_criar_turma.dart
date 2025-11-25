// lib/telas/professor/tela_criar_turma.dart
import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../../models/turma_professor.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../comum/overlay_carregamento.dart';
import '../../themes/app_theme.dart'; 

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

  final List<_HorarioItem> _horarios = [];
  final List<String> _diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];

  @override
  void dispose() {
    _nomeController.dispose();
    _localController.dispose();
    _salaController.dispose();
    super.dispose();
  }
  
  // --- FUNÇÕES LÓGICAS QUE FALTAVAM ---

  String _gerarStringHorario() {
    return _horarios.map((h) {
      final inicio = '${h.inicio.hour.toString().padLeft(2,'0')}:${h.inicio.minute.toString().padLeft(2,'0')}';
      final fim = '${h.fim.hour.toString().padLeft(2,'0')}:${h.fim.minute.toString().padLeft(2,'0')}';
      return '${h.dia} $inicio-$fim';
    }).join(', ');
  }

  bool _isHorarioValido(TimeOfDay time) {
    if (time.hour < 8) return false;
    if (time.hour > 18) return false; 
    if (time.hour == 18 && time.minute > 0) return false; 
    return true;
  }

  int _duracaoHoras(TimeOfDay inicio, TimeOfDay fim) {
    final minutosInicio = inicio.hour * 60 + inicio.minute;
    final minutosFim = fim.hour * 60 + fim.minute;
    return ((minutosFim - minutosInicio) / 60).round();
  }

  void _adicionarHorario() {
    if (_horarios.length >= 2) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Máximo de 2 dias por disciplina.'), backgroundColor: Colors.orange),
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

    if (!_isHorarioValido(t) && !(t.hour == 18 && t.minute == 0)) { 
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Horário permitido: 08:00 às 18:00.'), backgroundColor: Colors.red));
       return;
    }

    if ((t.hour == 12 && t.minute > 0) || t.hour == 13 || (t.hour == 12 && isInicio)) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Horário de almoço (12h-14h) bloqueado.'), backgroundColor: Colors.red));
       return;
    }

    TimeOfDay tempInicio = isInicio ? t : item.inicio;
    TimeOfDay tempFim = isInicio ? item.fim : t;
    
    if ((tempFim.hour * 60 + tempFim.minute) <= (tempInicio.hour * 60 + tempInicio.minute)) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hora fim deve ser maior que início.'), backgroundColor: Colors.red));
       return;
    }

    int duracao = _duracaoHoras(tempInicio, tempFim);
    
    if (_creditosSelecionados == 2 && duracao > 2) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disciplina de 2 créditos: Máx 2 horas.'), backgroundColor: Colors.red));
       return;
    }
    if (duracao > 4) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aula muito longa (Máx 4h).'), backgroundColor: Colors.red));
       return;
    }

    setState(() {
      if (isInicio) item.inicio = t; else item.fim = t;
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
   
   InputDecoration _inputDecor(String label, {String? hint}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: TextStyle(color: Colors.grey[400]),
        hintStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primaryPurple)),
      );
   }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final estaCarregando = ref.watch(provedorCarregando);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.t('criar_turma_titulo'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Dados Básicos", style: GoogleFonts.poppins(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nomeController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecor(t.t('criar_turma_nome'), hint: 'Ex: Cálculo 1'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: _creditosSelecionados,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecor('Créditos'),
                items: [4, 2].map((int value) => DropdownMenuItem(
                  value: value,
                  child: Text('$value Créditos'),
                )).toList(),
                onChanged: estaCarregando ? null : (v) => setState(() => _creditosSelecionados = v!),
              ),
              
              const SizedBox(height: 24),
              Text("Localização", style: GoogleFonts.poppins(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _predioSelecionado,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecor('Prédio'),
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
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecor('Sala', hint: 'Ex: 102'),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Horários', style: GoogleFonts.poppins(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                      child: Icon(Icons.add, color: _horarios.length < 2 ? AppColors.success : Colors.grey)
                    ), 
                    onPressed: _horarios.length < 2 ? _adicionarHorario : null
                  ),
                ],
              ),
              
              if (_horarios.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white12),
                    borderRadius: BorderRadius.circular(16)
                  ),
                  child: const Center(child: Text('Clique no + para adicionar horários.', style: TextStyle(color: Colors.grey))),
                ),

              ..._horarios.asMap().entries.map((entry) {
                int index = entry.key;
                _HorarioItem item = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: item.dia,
                        underline: const SizedBox(),
                        dropdownColor: AppColors.background,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        items: _diasSemana.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) => setState(() => item.dia = v!),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => _pickTime(index, true),
                              child: Text(item.inicio.format(context), style: const TextStyle(color: Colors.white, fontSize: 16)),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                            ),
                            GestureDetector(
                              onTap: () => _pickTime(index, false),
                              child: Text(item.fim.format(context), style: const TextStyle(color: Colors.white, fontSize: 16)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () => _removerHorario(index),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: estaCarregando ? null : _salvarTurma,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                  ),
                  child: Text(estaCarregando ? 'Salvando...' : 'Criar Turma', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
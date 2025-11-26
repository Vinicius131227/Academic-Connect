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
  final _salaController = TextEditingController(); 
  
  String? _predioSelecionado;
  int _creditosSelecionados = 4; 

  final List<_HorarioItem> _horarios = [];
  final List<String> _diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];

  @override
  void dispose() {
    _nomeController.dispose();
    _salaController.dispose();
    super.dispose();
  }
  
  // --- LÓGICA DE VALIDAÇÃO E CÁLCULO ---

  String _gerarStringHorario() {
    return _horarios.map((h) {
      final inicio = '${h.inicio.hour.toString().padLeft(2,'0')}:${h.inicio.minute.toString().padLeft(2,'0')}';
      final fim = '${h.fim.hour.toString().padLeft(2,'0')}:${h.fim.minute.toString().padLeft(2,'0')}';
      return '${h.dia} $inicio-$fim';
    }).join(', ');
  }

  // Valida se o horário está entre 08:00 e 18:00
  bool _isHorarioValido(TimeOfDay time) {
    if (time.hour < 8) return false;
    if (time.hour > 18) return false; 
    if (time.hour == 18 && time.minute > 0) return false; 
    return true;
  }

  // Valida duração do slot específico
  int _duracaoHoras(TimeOfDay inicio, TimeOfDay fim) {
    final minutosInicio = inicio.hour * 60 + inicio.minute;
    final minutosFim = fim.hour * 60 + fim.minute;
    return ((minutosFim - minutosInicio) / 60).round();
  }

  // Valida o total de horas acumuladas
  int _calcularHorasTotaisAtuais() {
    int minutosTotais = 0;
    for (var h in _horarios) {
       final start = h.inicio.hour * 60 + h.inicio.minute;
       final end = h.fim.hour * 60 + h.fim.minute;
       minutosTotais += (end - start);
    }
    return (minutosTotais / 60).round();
  }

  // Verifica sobreposição de horários na mesma disciplina
  bool _verificarSobreposicao(String dia, TimeOfDay novoInicio, TimeOfDay novoFim, {int? ignorarIndex}) {
    final double novoInicioDouble = novoInicio.hour + novoInicio.minute / 60.0;
    final double novoFimDouble = novoFim.hour + novoFim.minute / 60.0;

    for (int i = 0; i < _horarios.length; i++) {
      if (ignorarIndex != null && i == ignorarIndex) continue; // Ignora o item que está sendo editado
      
      final item = _horarios[i];
      if (item.dia == dia) {
        final double itemInicio = item.inicio.hour + item.inicio.minute / 60.0;
        final double itemFim = item.fim.hour + item.fim.minute / 60.0;

        // Lógica de colisão: (StartA < EndB) and (EndA > StartB)
        if (novoInicioDouble < itemFim && novoFimDouble > itemInicio) {
          return true; // Tem sobreposição
        }
      }
    }
    return false;
  }

  void _adicionarHorario() {
    // Verifica se já atingiu o limite de créditos antes de adicionar
    int horasAtuais = _calcularHorasTotaisAtuais();
    if (horasAtuais >= _creditosSelecionados) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Limite de $_creditosSelecionados horas atingido.'), backgroundColor: Colors.orange),
       );
       return;
    }
    
    if (_horarios.length >= 2) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Máximo de 2 dias por disciplina.'), backgroundColor: Colors.orange),
       );
       return;
    }
    
    // Adiciona um padrão seguro que não conflite (se possível)
    // Vamos adicionar vazio ou padrão e deixar o usuário ajustar
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

    // 1. VALIDAÇÃO COMERCIAL (08-18)
    if (!_isHorarioValido(t) && !(t.hour == 18 && t.minute == 0)) { 
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Horário permitido: 08:00 às 18:00.'), backgroundColor: Colors.red));
       return;
    }

    // 2. VALIDAÇÃO ALMOÇO (12-14)
    if ((t.hour == 12 && t.minute > 0) || t.hour == 13 || (t.hour == 12 && isInicio)) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Horário de almoço (12h-14h) bloqueado.'), backgroundColor: Colors.red));
       return;
    }

    TimeOfDay tempInicio = isInicio ? t : item.inicio;
    TimeOfDay tempFim = isInicio ? item.fim : t;
    
    // Validação Básica: Fim > Início
    if ((tempFim.hour * 60 + tempFim.minute) <= (tempInicio.hour * 60 + tempInicio.minute)) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hora fim deve ser maior que início.'), backgroundColor: Colors.red));
       return;
    }

    // 3. VALIDAÇÃO DE SOBREPOSIÇÃO
    if (_verificarSobreposicao(item.dia, tempInicio, tempFim, ignorarIndex: index)) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conflito de horário com outra aula desta disciplina.'), backgroundColor: Colors.red));
       return;
    }

    // 4. VALIDAÇÃO TOTAL DE CRÉDITOS
    // Calcula quanto tempo essa aula vai ter
    int duracaoAula = _duracaoHoras(tempInicio, tempFim);
    
    // Calcula o total das OUTRAS aulas já cadastradas
    int totalOutrasAulas = 0;
    for (int i = 0; i < _horarios.length; i++) {
      if (i != index) {
        totalOutrasAulas += _duracaoHoras(_horarios[i].inicio, _horarios[i].fim);
      }
    }
    
    int totalPrevisto = totalOutrasAulas + duracaoAula;
    
    if (totalPrevisto > _creditosSelecionados) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Total de horas ($totalPrevisto) excede os créditos ($_creditosSelecionados).'), backgroundColor: Colors.red));
       return;
    }

    setState(() {
      if (isInicio) item.inicio = t; else item.fim = t;
    });
  }
  
  // Atualiza o dia e verifica sobreposição
  void _mudarDia(int index, String novoDia) {
    final item = _horarios[index];
    
    if (_verificarSobreposicao(novoDia, item.inicio, item.fim, ignorarIndex: index)) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conflito de horário neste dia.'), backgroundColor: Colors.red));
       return; // Não muda se der conflito
    }
    
    setState(() {
      item.dia = novoDia;
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
    
    // Validação final de créditos
    if (_calcularHorasTotaisAtuais() != _creditosSelecionados) {
        // Opcional: Pode ser flexível ou rígido. Vamos ser rígidos.
        ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('A carga horária total deve ser de $_creditosSelecionados horas.'), backgroundColor: Colors.orange),
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
          backgroundColor: AppColors.surface,
          title: Text(t.t('criar_turma_sucesso'), style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.t('criar_turma_codigo_desc'), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              Center(
                child: SelectableText(
                  codigo,
                  style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
              child: Text(t.t('criar_turma_ok'), style: const TextStyle(color: Colors.white)),
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
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: isDark ? BorderSide.none : const BorderSide(color: Colors.black12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primaryPurple)),
      );
   }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final estaCarregando = ref.watch(provedorCarregando);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.t('criar_turma_titulo'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
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
                style: TextStyle(color: textColor),
                decoration: _inputDecor(t.t('criar_turma_nome'), hint: 'Ex: Cálculo 1'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: _creditosSelecionados,
                dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                style: TextStyle(color: textColor),
                decoration: _inputDecor('Créditos'),
                items: [4, 2].map((int value) => DropdownMenuItem(
                  value: value,
                  child: Text('$value Créditos'),
                )).toList(),
                onChanged: estaCarregando ? null : (v) {
                   setState(() {
                     _creditosSelecionados = v!;
                     // Se diminuir os créditos, limpa horários para evitar inconsistência
                     _horarios.clear();
                   });
                },
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
                      dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                      style: TextStyle(color: textColor),
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
                      style: TextStyle(color: textColor),
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
                      decoration: BoxDecoration(color: isDark ? AppColors.surface : Colors.grey[200], shape: BoxShape.circle),
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
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                    borderRadius: BorderRadius.circular(16)
                  ),
                  child: Center(child: Text('Clique no + para adicionar horários.', style: TextStyle(color: isDark ? Colors.grey : Colors.black54))),
                ),

              ..._horarios.asMap().entries.map((entry) {
                int index = entry.key;
                _HorarioItem item = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                    border: isDark ? null : Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: item.dia,
                        underline: const SizedBox(),
                        dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        items: _diasSemana.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) => _mudarDia(index, v!),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => _pickTime(index, true),
                              child: Text(item.inicio.format(context), style: TextStyle(color: textColor, fontSize: 16)),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                            ),
                            GestureDetector(
                              onTap: () => _pickTime(index, false),
                              child: Text(item.fim.format(context), style: TextStyle(color: textColor, fontSize: 16)),
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
                  child: Text(estaCarregando ? 'Salvando...' : 'Criar Turma', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
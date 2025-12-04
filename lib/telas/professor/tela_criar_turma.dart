// lib/telas/professor/tela_criar_turma.dart

import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/turma_professor.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../comum/overlay_carregamento.dart';
import '../../themes/app_theme.dart'; 

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Criar Turma',
  type: TelaCriarTurma,
)
Widget buildTelaCriarTurma(BuildContext context) {
  return const ProviderScope(
    child: TelaCriarTurma(),
  );
}

/// Modelo local para gerenciar múltiplos horários na tela de criação.
class _HorarioItem {
  String dia;
  TimeOfDay inicio;
  TimeOfDay fim;
  _HorarioItem({required this.dia, required this.inicio, required this.fim});
}

class TelaCriarTurma extends ConsumerStatefulWidget {
  const TelaCriarTurma({super.key});

  @override
  ConsumerState<TelaCriarTurma> createState() => _TelaCriarTurmaState();
}

class _TelaCriarTurmaState extends ConsumerState<TelaCriarTurma> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores de texto
  final _nomeController = TextEditingController();
  final _salaController = TextEditingController(); 
  
  // Estado dos campos
  String? _predioSelecionado;
  int _creditosSelecionados = 4; 

  // Lista dinâmica de horários
  final List<_HorarioItem> _horarios = [];
  final List<String> _diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];

  @override
  void dispose() {
    _nomeController.dispose();
    _salaController.dispose();
    super.dispose();
  }
  
  // --- LÓGICA DE NEGÓCIO ---

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
    final t = AppLocalizations.of(context)!;
    // Regra: Máximo de 2 encontros semanais
    if (_horarios.length >= 2) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(t.t('erro_max_dias')), backgroundColor: Colors.orange),
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
    final tLoc = AppLocalizations.of(context)!;
    final item = _horarios[index];
    final initial = isInicio ? item.inicio : item.fim;
    
    final t = await showTimePicker(context: context, initialTime: initial);
    if (t == null) return;

    // 1. Validação de Horário Comercial
    if (!_isHorarioValido(t) && !(t.hour == 18 && t.minute == 0)) { 
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tLoc.t('erro_horario_comercial')), backgroundColor: Colors.red));
       return;
    }

    // 2. Validação de Almoço (12h - 14h Bloqueado)
    if ((t.hour == 12 && t.minute > 0) || t.hour == 13 || (t.hour == 12 && isInicio)) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tLoc.t('erro_almoco')), backgroundColor: Colors.red));
       return;
    }

    TimeOfDay tempInicio = isInicio ? t : item.inicio;
    TimeOfDay tempFim = isInicio ? item.fim : t;
    
    // 3. Validação de Ordem (Fim deve ser depois do Início)
    if ((tempFim.hour * 60 + tempFim.minute) <= (tempInicio.hour * 60 + tempInicio.minute)) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tLoc.t('erro_fim_inicio')), backgroundColor: Colors.red));
       return;
    }

    // 4. Validação de Créditos
    int duracao = _duracaoHoras(tempInicio, tempFim);
    
    if (_creditosSelecionados == 2 && duracao > 2) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tLoc.t('erro_creditos_tempo_2')), backgroundColor: Colors.red));
       return;
    }
    if (duracao > 4) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tLoc.t('erro_max_tempo')), backgroundColor: Colors.red));
       return;
    }

    setState(() {
      if (isInicio) item.inicio = t; else item.fim = t;
    });
  }

  Future<void> _salvarTurma() async {
    final t = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate() || _predioSelecionado == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(t.t('erro_preencher_tudo')), backgroundColor: Colors.red),
       );
       return;
    }
    if (_horarios.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(t.t('erro_sem_horario')), backgroundColor: Colors.red),
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
        _mostrarDialogCodigo(context, codigoGerado, t);
      }
    } catch (e) {
      if (mounted) {
        ref.read(provedorCarregando.notifier).state = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.t('erro_generico')}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarDialogCodigo(BuildContext context, String codigo, AppLocalizations t) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final bg = isDark ? AppColors.surfaceDark : Colors.white;
          final text = isDark ? Colors.white : Colors.black;

          return AlertDialog(
            backgroundColor: bg,
            title: Text(t.t('criar_turma_sucesso'), style: TextStyle(color: text)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.t('criar_turma_codigo_desc'), style: TextStyle(color: text.withOpacity(0.7))),
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
          );
        },
      );
    }
   
   InputDecoration _inputDecor(BuildContext context, String label, {String? hint}) {
     final theme = Theme.of(context);
     final isDark = theme.brightness == Brightness.dark;
     final fillColor = isDark ? AppColors.surfaceDark : Colors.white;
     final hintColor = isDark ? Colors.grey[400] : Colors.grey[600];
     
     return InputDecoration(
       labelText: label,
       hintText: hint,
       filled: true,
       fillColor: fillColor,
       labelStyle: TextStyle(color: hintColor),
       hintStyle: TextStyle(color: hintColor?.withOpacity(0.7)),
       border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
       enabledBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(16), 
           borderSide: isDark ? BorderSide.none : const BorderSide(color: Colors.black12)
       ),
       focusedBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(16), 
           borderSide: const BorderSide(color: AppColors.primaryPurple)
       ),
     );
   }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final estaCarregando = ref.watch(provedorCarregando);
    
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final isDark = theme.brightness == Brightness.dark;
    final dropdownColor = isDark ? AppColors.surfaceDark : Colors.white;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.t('criar_turma_titulo'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seção Dados (TRADUZIDO)
              Text(t.t('criar_turma_dados_basicos'), style: GoogleFonts.poppins(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              
              // Nome
              TextFormField(
                controller: _nomeController,
                style: TextStyle(color: textColor),
                decoration: _inputDecor(context, t.t('criar_turma_nome'), hint: t.t('criar_turma_nome_hint')),
                validator: (v) => v!.isEmpty ? t.t('erro_obrigatorio') : null,
              ),
              const SizedBox(height: 16),

              // Créditos (TRADUZIDO)
              DropdownButtonFormField<int>(
                value: _creditosSelecionados,
                dropdownColor: dropdownColor,
                style: TextStyle(color: textColor),
                decoration: _inputDecor(context, t.t('criar_turma_creditos')),
                items: [4, 2].map((int value) => DropdownMenuItem(
                  value: value,
                  child: Text(t.t('criar_turma_creditos_item', args: [value.toString()]), style: TextStyle(color: textColor)),
                )).toList(),
                onChanged: estaCarregando ? null : (v) {
                   setState(() {
                     _creditosSelecionados = v!;
                     _horarios.clear(); 
                   });
                },
              ),
              
              const SizedBox(height: 24),
              // Seção Local (TRADUZIDO)
              Text(t.t('criar_turma_localizacao_titulo'), style: GoogleFonts.poppins(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _predioSelecionado,
                      dropdownColor: dropdownColor,
                      style: TextStyle(color: textColor),
                      decoration: _inputDecor(context, t.t('criar_turma_local')),
                      items: AppLocalizations.of(context)!.predios.map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: textColor)))).toList(),
                      onChanged: estaCarregando ? null : (v) => setState(() => _predioSelecionado = v),
                      validator: (v) => v == null ? t.t('erro_obrigatorio') : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _salaController,
                      style: TextStyle(color: textColor),
                      // TRADUZIDO: "Sala"
                      decoration: _inputDecor(context, t.t('criar_turma_sala'), hint: t.t('criar_turma_local_hint')),
                      validator: (v) => v!.isEmpty ? t.t('erro_obrigatorio') : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Seção Horários (TRADUZIDO)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t.t('criar_turma_horario'), style: GoogleFonts.poppins(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 16)),
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
                  // TRADUZIDO: Texto de ajuda
                  child: Center(child: Text(t.t('criar_turma_hint_horario'), style: TextStyle(color: isDark ? Colors.grey : Colors.black54))),
                ),

              // Lista de Horários
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
                        dropdownColor: dropdownColor,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
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
              
              // Botão Salvar
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
                  child: Text(estaCarregando ? t.t('carregando') : t.t('criar_turma_botao'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
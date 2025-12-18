// lib/telas/professor/tela_criar_turma.dart

import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../../models/turma_professor.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../comum/widget_carregamento.dart';
import '../../themes/app_theme.dart'; 

@UseCase(
  name: 'Criar Turma',
  type: TelaCriarTurma,
)
Widget buildTelaCriarTurma(BuildContext context) {
  return const ProviderScope(
    child: TelaCriarTurma(),
  );
}

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
  
  final _nomeController = TextEditingController();
  final _salaController = TextEditingController(); 
  
  String? _predioSelecionado;
  int _creditosSelecionados = 4; 
  bool _isLoading = false;

  final List<_HorarioItem> _horarios = [];
  
  @override
  void dispose() {
    _nomeController.dispose();
    _salaController.dispose();
    super.dispose();
  }

  // --- HELPER PARA PEGAR DIAS TRADUZIDOS ---
  List<String> _getDiasTraduzidos(AppLocalizations t) {
    return [
      t.t('dia_seg'),
      t.t('dia_ter'),
      t.t('dia_qua'),
      t.t('dia_qui'),
      t.t('dia_sex'),
      t.t('dia_sab'),
    ];
  }
  
  String _gerarStringHorario() {
    return _horarios.map((h) {
      final inicio = '${h.inicio.hour.toString().padLeft(2,'0')}:${h.inicio.minute.toString().padLeft(2,'0')}';
      final fim = '${h.fim.hour.toString().padLeft(2,'0')}:${h.fim.minute.toString().padLeft(2,'0')}';
      return '${h.dia} $inicio-$fim';
    }).join(' / ');
  }

  // --- NOVA LÓGICA DE VALIDAÇÃO RESTRITA ---
  String? _validarHorariosLogica() {
    if (_horarios.isEmpty) return "Adicione pelo menos um horário.";

    int minutosTotais = 0;
    
    // Intervalo permitido geral: 08:00 às 18:00
    const int minGlobal = 8 * 60;  // 480 min
    const int maxGlobal = 18 * 60; // 1080 min
    
    // Intervalo de almoço proibido: 12:00 às 14:00
    const int inicioAlmoco = 12 * 60; // 720 min
    const int fimAlmoco = 14 * 60;    // 840 min

    for (var h in _horarios) {
      final minutosInicio = h.inicio.hour * 60 + h.inicio.minute;
      final minutosFim = h.fim.hour * 60 + h.fim.minute;
      final duracaoMinutos = minutosFim - minutosInicio;

      // 1. Validação Básica
      if (duracaoMinutos <= 0) return "A hora final deve ser maior que a inicial.";
      
      // 2. Validação Global (08:00 - 18:00)
      if (minutosInicio < minGlobal || minutosFim > maxGlobal) {
        return "O horário deve estar entre 08:00 e 18:00.";
      }

      // 3. Validação Almoço (12:00 - 14:00)
      // Se começa DENTRO do almoço OU termina DENTRO do almoço OU atravessa o almoço
      bool comecaNoAlmoco = minutosInicio >= inicioAlmoco && minutosInicio < fimAlmoco;
      bool terminaNoAlmoco = minutosFim > inicioAlmoco && minutosFim <= fimAlmoco;
      bool atravessaAlmoco = minutosInicio < inicioAlmoco && minutosFim > fimAlmoco;

      if (comecaNoAlmoco || terminaNoAlmoco || atravessaAlmoco) {
        return "Não é permitido aulas durante o horário de almoço (12:00 às 14:00).";
      }

      minutosTotais += duracaoMinutos;

      if (_creditosSelecionados == 4 && _horarios.length > 1) {
        if (duracaoMinutos > 120) {
          return "Para 4 créditos divididos, cada aula deve ter no máximo 2 horas.";
        }
      }
    }

    if (_creditosSelecionados == 2) {
        if (_horarios.length > 1) return "Disciplinas de 2 créditos devem ter apenas 1 horário.";
        if (minutosTotais < 100 || minutosTotais > 140) return "Para 2 créditos, a duração deve ser de aprox. 2 horas.";
    }
    
    if (_creditosSelecionados == 4) {
        if (minutosTotais < 200 || minutosTotais > 260) return "Para 4 créditos, a duração total deve ser de aprox. 4 horas.";
    }

    return null;
  }

  void _adicionarHorario() {
    final t = AppLocalizations.of(context)!;
    
    if (_creditosSelecionados == 2 && _horarios.isNotEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("2 Créditos permitem apenas 1 horário."), backgroundColor: Colors.orange));
       return;
    }
    if (_horarios.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.t('erro_max_dias')), backgroundColor: Colors.orange));
      return;
    }
    
    final dias = _getDiasTraduzidos(t);
    
    setState(() {
      _horarios.add(_HorarioItem(
        dia: dias[0], 
        // Padrão inicial seguro: 08:00 - 10:00
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
    
    final t = await showTimePicker(
      context: context, 
      initialTime: initial,
      builder: (BuildContext context, Widget? child) {
        // Opcional: Força tema claro/escuro no picker se precisar
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (t == null) return;

    // --- Validação Imediata ao Selecionar ---
    final int minutos = t.hour * 60 + t.minute;
    
    // Verifica limites globais (08:00 - 18:00)
    if (minutos < 480 || minutos > 1080) { // 8*60 e 18*60
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Horário inválido. Escolha entre 08:00 e 18:00."), backgroundColor: Colors.red));
       return; // Não atualiza o estado
    }

    // Verifica almoço (12:00 - 14:00)
    // Permite "terminar" às 12:00 (720) ou "começar" às 14:00 (840)
    // Mas não pode selecionar algo DENTRO desse intervalo
    if (minutos > 720 && minutos < 840) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Horário de almoço (12:00 - 14:00) não permitido."), backgroundColor: Colors.red));
       return; 
    }

    setState(() {
      if (isInicio) item.inicio = t; else item.fim = t;
    });
  }

  Future<void> _salvarTurma() async {
    final t = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate() || _predioSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.t('erro_preencher_tudo')), backgroundColor: Colors.red));
      return;
    }
    
    String? erroHorario = _validarHorariosLogica();
    if (erroHorario != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erroHorario), backgroundColor: Colors.red));
      return;
    }
    
    final professorId = ref.read(provedorNotificadorAutenticacao).usuario?.uid;
    if (professorId == null) return;

    setState(() => _isLoading = true);
    
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
        setState(() => _isLoading = false);
        _mostrarDialogCodigo(context, codigoGerado, t);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final isDark = theme.brightness == Brightness.dark;
    final dropdownColor = isDark ? AppColors.surfaceDark : Colors.white;
    
    final diasTraduzidos = _getDiasTraduzidos(t);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.t('criar_turma_titulo'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: _isLoading 
        ? const WidgetCarregamento(texto: "Criando turma...")
        : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.t('criar_turma_dados_basicos'), style: GoogleFonts.poppins(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nomeController,
                style: TextStyle(color: textColor),
                decoration: _inputDecor(context, t.t('criar_turma_nome'), hint: t.t('criar_turma_nome_hint')),
                validator: (v) => v!.isEmpty ? t.t('erro_obrigatorio') : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: _creditosSelecionados,
                dropdownColor: dropdownColor,
                style: TextStyle(color: textColor),
                decoration: _inputDecor(context, t.t('criar_turma_creditos')),
                items: [4, 2].map((int value) => DropdownMenuItem(
                  value: value,
                  child: Text(t.t('criar_turma_creditos_item', args: [value.toString()]), style: TextStyle(color: textColor)),
                )).toList(),
                onChanged: (v) {
                   setState(() {
                     _creditosSelecionados = v!;
                     _horarios.clear(); 
                   });
                },
              ),
              
              const SizedBox(height: 24),
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
                      items: ['AT1', 'AT2', 'AT3', 'AT4', 'AT5', 'AT6', 'AT7', 'AT8', 'AT9', 'Laboratórios'].map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: textColor)))).toList(),
                      onChanged: (v) => setState(() => _predioSelecionado = v),
                      validator: (v) => v == null ? t.t('erro_obrigatorio') : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _salaController,
                      style: TextStyle(color: textColor),
                      decoration: _inputDecor(context, t.t('criar_turma_sala'), hint: t.t('criar_turma_local_hint')),
                      validator: (v) => v!.isEmpty ? t.t('erro_obrigatorio') : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
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
                  child: Center(child: Text(t.t('criar_turma_hint_horario'), style: TextStyle(color: isDark ? Colors.grey : Colors.black54))),
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
                        dropdownColor: dropdownColor,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        items: diasTraduzidos.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
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
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _salvarTurma,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                  ),
                  child: Text(t.t('criar_turma_botao'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
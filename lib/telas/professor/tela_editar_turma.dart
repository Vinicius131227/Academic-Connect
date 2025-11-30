// lib/telas/professor/tela_editar_turma.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/turma_professor.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart'; // Traduções
import '../comum/overlay_carregamento.dart';
import '../../themes/app_theme.dart'; // Cores e Temas

/// Caso de uso para o Widgetbook.
/// Simula a tela de edição de turma.
@UseCase(
  name: 'Editar Turma',
  type: TelaEditarTurma,
)
Widget buildTelaEditarTurma(BuildContext context) {
  return ProviderScope(
    child: TelaEditarTurma(
      turma: TurmaProfessor(
        id: 'mock',
        nome: 'Cálculo 1',
        horario: 'Seg 08:00-10:00',
        local: 'AT1 - 105',
        professorId: '',
        turmaCode: 'X1Y2Z3',
        creditos: 4,
        alunosInscritos: [],
      ),
    ),
  );
}

/// Modelo local para manipular a lista de horários na tela.
class _HorarioItem {
  String dia;
  TimeOfDay inicio;
  TimeOfDay fim;
  _HorarioItem({required this.dia, required this.inicio, required this.fim});
}

/// Tela para edição de dados de uma turma existente.
class TelaEditarTurma extends ConsumerStatefulWidget {
  final TurmaProfessor turma;
  
  const TelaEditarTurma({
    super.key, 
    required this.turma
  });

  @override
  ConsumerState<TelaEditarTurma> createState() => _TelaEditarTurmaState();
}

class _TelaEditarTurmaState extends ConsumerState<TelaEditarTurma> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _salaController;
  
  String? _predioSelecionado;
  int _creditosSelecionados = 4; 
  
  // Lista dinâmica de horários
  final List<_HorarioItem> _horarios = [];
  final List<String> _diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];

  @override
  void initState() {
    super.initState();
    // Inicializa os campos com os dados atuais da turma
    _nomeController = TextEditingController(text: widget.turma.nome);
    _creditosSelecionados = widget.turma.creditos;
    
    // Parse do local (Ex: "AT1 - 102")
    // Tenta separar prédio e sala para preencher o formulário
    final localParts = widget.turma.local.split(' - ');
    if (localParts.length > 1 && AppLocalizations.predios.contains(localParts[0])) {
      _predioSelecionado = localParts[0];
      _salaController = TextEditingController(text: localParts[1]);
    } else {
      // Se não estiver no formato padrão, coloca tudo na sala
      _salaController = TextEditingController(text: widget.turma.local);
    }

    // Parse dos horários (Ex: "Seg 08:00-10:00, Qua 14:00-16:00")
    if (widget.turma.horario.isNotEmpty) {
      final horariosStr = widget.turma.horario.split(', ');
      for (var h in horariosStr) {
        try {
          // Tenta extrair dia, inicio e fim
          final parts = h.split(' '); // ["Seg", "08:00-10:00"]
          final dia = parts[0];
          final times = parts[1].split('-'); // ["08:00", "10:00"]
          final start = times[0].split(':');
          final end = times[1].split(':');
          
          _horarios.add(_HorarioItem(
            dia: dia,
            inicio: TimeOfDay(hour: int.parse(start[0]), minute: int.parse(start[1])),
            fim: TimeOfDay(hour: int.parse(end[0]), minute: int.parse(end[1])),
          ));
        } catch (e) {
          // Ignora erros de parse se o formato estiver corrompido
        }
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _salaController.dispose();
    super.dispose();
  }

  /// Recria a string de horário a partir da lista editada.
  String _gerarStringHorario() {
    return _horarios.map((h) {
      final inicio = '${h.inicio.hour.toString().padLeft(2,'0')}:${h.inicio.minute.toString().padLeft(2,'0')}';
      final fim = '${h.fim.hour.toString().padLeft(2,'0')}:${h.fim.minute.toString().padLeft(2,'0')}';
      return '${h.dia} $inicio-$fim';
    }).join(', ');
  }

  /// Adiciona um novo slot de horário.
  void _adicionarHorario() {
    if (_horarios.length >= 2) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Máx: 2 dias/aula'), backgroundColor: Colors.orange),
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
  
  /// Abre seletor de hora.
  Future<void> _pickTime(int index, bool isInicio) async {
    final item = _horarios[index];
    final initial = isInicio ? item.inicio : item.fim;
    
    final t = await showTimePicker(context: context, initialTime: initial);
    if (t == null) return;
    
    // Validações básicas
    if (isInicio && t.hour >= item.fim.hour && t.minute >= item.fim.minute) {
       // Aviso simples
    }

    setState(() {
      if (isInicio) item.inicio = t; else item.fim = t;
    });
  }

  /// Salva as alterações no Firestore.
  Future<void> _salvarTurma() async {
    // 1. Validações
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

    // 2. Loading
    ref.read(provedorCarregando.notifier).state = true;
    final t = AppLocalizations.of(context)!;
    
    try {
      // 3. Cria objeto atualizado
      final turmaAtualizada = TurmaProfessor(
        id: widget.turma.id,
        nome: _nomeController.text.trim(),
        horario: _gerarStringHorario(),
        local: '$_predioSelecionado - ${_salaController.text}',
        professorId: widget.turma.professorId,
        turmaCode: widget.turma.turmaCode,
        creditos: _creditosSelecionados,
        alunosInscritos: widget.turma.alunosInscritos,
      );

      // 4. Chama o serviço
      await ref.read(servicoFirestoreProvider).atualizarTurma(turmaAtualizada);

      if (mounted) {
        ref.read(provedorCarregando.notifier).state = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('aluno_perfil_edit_sucesso')), backgroundColor: Colors.green), // "Sucesso"
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
  
  // Helper para input decoration com tema
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
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: isDark ? BorderSide.none : const BorderSide(color: Colors.black12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primaryPurple)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final estaCarregando = ref.watch(provedorCarregando);
    final t = AppLocalizations.of(context)!;
    
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final isDark = theme.brightness == Brightness.dark;
    final dropdownColor = isDark ? AppColors.surfaceDark : Colors.white;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t.t('prof_editar_turma'), // "Editar Turma"
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campo Nome
              TextFormField(
                controller: _nomeController,
                style: TextStyle(color: textColor),
                decoration: _inputDecor(context, t.t('criar_turma_nome')),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              
              // Campo Local (Prédio + Sala)
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _predioSelecionado,
                      dropdownColor: dropdownColor,
                      style: TextStyle(color: textColor),
                      decoration: _inputDecor(context, t.t('criar_turma_local')),
                      items: AppLocalizations.predios.map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: textColor)))).toList(),
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
                      decoration: _inputDecor(context, 'Sala', hint: t.t('criar_turma_local_hint')),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              // Lista de Horários
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t.t('criar_turma_horario'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green), 
                    onPressed: _adicionarHorario
                  ),
                ],
              ),
              const Divider(),
              
              ..._horarios.asMap().entries.map((entry) {
                int index = entry.key;
                _HorarioItem item = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                     color: isDark ? AppColors.surface : Colors.white,
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
                      InkWell(
                        child: Text('${item.inicio.format(context)}', style: TextStyle(color: textColor, fontSize: 16)),
                        onTap: () => _pickTime(index, true),
                      ),
                      const Text(' - '),
                      InkWell(
                        child: Text('${item.fim.format(context)}', style: TextStyle(color: textColor, fontSize: 16)),
                        onTap: () => _pickTime(index, false),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
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
                  ),
                  child: Text(
                    estaCarregando ? t.t('carregando') : t.t('salvar'), 
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
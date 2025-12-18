// lib/telas/professor/tela_marcar_prova.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../../models/turma_professor.dart';
import '../../models/prova_agendada.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Marcar Prova',
  type: TelaMarcarProva,
)
Widget buildTelaMarcarProva(BuildContext context) {
  return ProviderScope(
    child: TelaMarcarProva(
      turma: TurmaProfessor(
        id: 'mock',
        nome: 'Cálculo 1',
        horario: '',
        local: '',
        professorId: '',
        turmaCode: '',
        creditos: 4,
        alunosInscritos: [],
      ),
    ),
  );
}

/// Tela onde o professor agenda avaliações.
class TelaMarcarProva extends ConsumerStatefulWidget {
  final TurmaProfessor turma;
  
  const TelaMarcarProva({
    super.key, 
    required this.turma
  });

  @override
  ConsumerState<TelaMarcarProva> createState() => _TelaMarcarProvaState();
}

class _TelaMarcarProvaState extends ConsumerState<TelaMarcarProva> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Controladores
  final _tituloController = TextEditingController();
  final _salaController = TextEditingController(); 
  final _conteudoController = TextEditingController();
  
  // Estados locais
  DateTime? _dataSelecionada;
  TimeOfDay? _horaSelecionada;
  String? _predioSelecionado;

  @override
  void dispose() {
    _tituloController.dispose();
    _salaController.dispose(); 
    _conteudoController.dispose();
    super.dispose();
  }

  /// Abre o calendário para escolher a data.
  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030), 
    );
    if (data != null) {
      setState(() => _dataSelecionada = data);
    }
  }

  /// Abre o relógio para escolher a hora.
  Future<void> _selecionarHora(BuildContext context) async {
    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: _horaSelecionada ?? TimeOfDay.now(),
    );
    if (hora != null) {
      setState(() => _horaSelecionada = hora);
    }
  }

  /// Valida e salva a prova no Firestore.
  Future<void> _salvarProva() async {
    final t = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate() || _dataSelecionada == null || _horaSelecionada == null || _predioSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.t('erro_preencher_tudo_prova')), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Combina Data e Hora num único objeto DateTime
    final dataHoraCompleta = DateTime(
      _dataSelecionada!.year,
      _dataSelecionada!.month,
      _dataSelecionada!.day,
      _horaSelecionada!.hour,
      _horaSelecionada!.minute,
    );

    final novaProva = ProvaAgendada(
      id: '', 
      turmaId: widget.turma.id,
      titulo: _tituloController.text,
      disciplina: widget.turma.nome, 
      dataHora: dataHoraCompleta,
      predio: _predioSelecionado!,
      sala: _salaController.text, 
      conteudo: _conteudoController.text,
    );

    try {
      await ref.read(servicoFirestoreProvider).adicionarProva(novaProva);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('marcar_prova_sucesso')), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.t('erro_generico')}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final isDark = theme.brightness == Brightness.dark;
    
    final dataFormatada = _dataSelecionada == null 
        ? t.t('marcar_prova_selecionar_data')
        : DateFormat('dd/MM/yyyy').format(_dataSelecionada!);
        
    final horaFormatada = _horaSelecionada == null 
        ? t.t('marcar_prova_selecionar_hora')
        : _horaSelecionada!.format(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.t('marcar_prova_titulo_screen', args: [widget.turma.nome]), style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título da Prova
              TextFormField(
                controller: _tituloController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: t.t('marcar_prova_titulo_label'),
                  hintText: t.t('marcar_prova_titulo_hint'),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                ),
                validator: (v) => (v == null || v.isEmpty) ? t.t('campo_obrigatorio') : null,
              ),
              const SizedBox(height: 16),
              
              // Seletores de Data e Hora
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(dataFormatada),
                      onPressed: () => _selecionarData(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: textColor
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.schedule),
                      label: Text(horaFormatada),
                      onPressed: () => _selecionarHora(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: textColor
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _predioSelecionado,
                style: TextStyle(color: textColor),
                dropdownColor: theme.cardColor,
                decoration: InputDecoration(
                  labelText: t.t('marcar_prova_predio'), 
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                ),
                items: t.predios.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _predioSelecionado = v),
                validator: (v) => (v == null || v.isEmpty) ? t.t('campo_obrigatorio') : null,
              ),
              const SizedBox(height: 16),
              
              // Sala
              TextFormField(
                controller: _salaController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: t.t('marcar_prova_sala'),
                  hintText: t.t('marcar_prova_sala_hint'),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                ),
                validator: (v) => (v == null || v.isEmpty) ? t.t('campo_obrigatorio') : null,
              ),
              const SizedBox(height: 16),
              
              // Conteúdo
              TextFormField(
                controller: _conteudoController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: t.t('marcar_prova_conteudo'),
                  hintText: t.t('marcar_prova_conteudo_hint'),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                ),
                maxLines: 3,
                validator: (v) => (v == null || v.isEmpty) ? t.t('campo_obrigatorio') : null,
              ),
              
              const SizedBox(height: 24),
              
              // Botão Salvar
              ElevatedButton.icon(
                icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Icon(Icons.save),
                label: Text(_isLoading ? t.t('marcar_prova_salvando') : t.t('marcar_prova_salvar_btn')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16)
                ),
                onPressed: _isLoading ? null : _salvarProva,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
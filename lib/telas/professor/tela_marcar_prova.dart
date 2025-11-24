// lib/telas/professor/tela_marcar_prova.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/turma_professor.dart';
import '../../models/prova_agendada.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class TelaMarcarProva extends ConsumerStatefulWidget {
  final TurmaProfessor turma;
  const TelaMarcarProva({super.key, required this.turma});

  @override
  ConsumerState<TelaMarcarProva> createState() => _TelaMarcarProvaState();
}

class _TelaMarcarProvaState extends ConsumerState<TelaMarcarProva> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  final _tituloController = TextEditingController();
  final _salaController = TextEditingController(); 
  final _conteudoController = TextEditingController();
  
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

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );
    if (data != null) {
      setState(() => _dataSelecionada = data);
    }
  }

  Future<void> _selecionarHora(BuildContext context) async {
    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: _horaSelecionada ?? TimeOfDay.now(),
    );
    if (hora != null) {
      setState(() => _horaSelecionada = hora);
    }
  }

  Future<void> _salvarProva() async {
    if (!_formKey.currentState!.validate() || _dataSelecionada == null || _horaSelecionada == null || _predioSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos, incluindo data, hora e prédio.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

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
      final servico = ref.read(servicoFirestoreProvider);
      await servico.adicionarProva(novaProva);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prova marcada com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
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
    final dataFormatada = _dataSelecionada == null ? t.t('ca_eventos_criar_data') : DateFormat('dd/MM/yyyy').format(_dataSelecionada!);
    final horaFormatada = _horaSelecionada == null ? 'Selecionar Hora *' : _horaSelecionada!.format(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Marcar Prova - ${widget.turma.nome}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título da Avaliação *',
                  hintText: 'Ex: P1 - Prova N1',
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(dataFormatada),
                      onPressed: () => _selecionarData(context), // CORRIGIDO
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.schedule),
                      label: Text(horaFormatada),
                      onPressed: () => _selecionarHora(context), // CORRIGIDO
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _predioSelecionado,
                decoration: InputDecoration(labelText: 'Prédio *', border: const OutlineInputBorder()),
                items: AppLocalizations.predios.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _predioSelecionado = v),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salaController,
                decoration: const InputDecoration(
                  labelText: 'Sala *',
                  hintText: 'Ex: 105 ou Lab 3',
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _conteudoController,
                decoration: const InputDecoration(
                  labelText: 'Conteúdo Abordado *',
                  hintText: 'Ex: Capítulos 1-3, Funções e Laços',
                ),
                maxLines: 3,
                validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                label: Text(_isLoading ? 'Salvando...' : 'Salvar Prova'),
                onPressed: _isLoading ? null : _salvarProva,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
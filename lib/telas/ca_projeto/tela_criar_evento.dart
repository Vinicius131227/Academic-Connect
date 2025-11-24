import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/evento_ca.dart';
// --- IMPORTES ATUALIZADOS ---
import '../../services/servico_firestore.dart';
import '../../providers/provedor_autenticacao.dart';
// --- FIM IMPORTES ATUALIZADOS ---
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';

class TelaCriarEvento extends ConsumerStatefulWidget {
  const TelaCriarEvento({super.key});

  @override
  ConsumerState<TelaCriarEvento> createState() => _TelaCriarEventoState();
}

class _TelaCriarEventoState extends ConsumerState<TelaCriarEvento> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  final _nomeController = TextEditingController();
  final _localController = TextEditingController();
  final _participantesController = TextEditingController();
  DateTime? _dataSelecionada;

  @override
  void dispose() {
    _nomeController.dispose();
    _localController.dispose();
    _participantesController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );
    if (data != null) {
      setState(() => _dataSelecionada = data);
    }
  }

  // --- LÓGICA DE SALVAR ATUALIZADA ---
  Future<void> _salvarEvento() async {
    if (!_formKey.currentState!.validate() || _dataSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Pega o ID do C.A. logado
    final organizadorId = ref.read(provedorNotificadorAutenticacao).usuario?.uid;
    if (organizadorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não autenticado.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() => _isLoading = true);

    // Cria o objeto EventoCA correto
    final novoEvento = EventoCA(
      id: '', // Firestore vai gerar o ID
      nome: _nomeController.text,
      data: _dataSelecionada!, // Salva como DateTime
      local: _localController.text,
      totalParticipantes: int.tryParse(_participantesController.text) ?? 0,
      organizadorId: organizadorId,
      participantesInscritos: [], // Começa vazio
    );

    try {
      // Chama o serviço do Firestore
      await ref.read(servicoFirestoreProvider).adicionarEvento(novoEvento);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento criado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar evento: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  // --- FIM LÓGICA ATUALIZADA ---

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('ca_eventos_criar_titulo')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                      TextFormField(
                        controller: _nomeController,
                        decoration: InputDecoration(
                          labelText: t.t('ca_eventos_criar_nome'),
                          hintText: 'Ex: Semana da Computação',
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _localController,
                        decoration: InputDecoration(
                          labelText: t.t('ca_eventos_criar_local'),
                          hintText: 'Ex: Anfiteatro B',
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _participantesController,
                        decoration: InputDecoration(
                          labelText: t.t('ca_eventos_criar_participantes'),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_dataSelecionada == null 
                          ? t.t('ca_eventos_criar_data')
                          : DateFormat('dd/MM/yyyy').format(_dataSelecionada!)),
                        onPressed: () => _selecionarData(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 48), 
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                label: Text(_isLoading ? 'Salvando...' : t.t('ca_eventos_criar_salvar')),
                onPressed: _isLoading ? null : _salvarEvento,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// lib/telas/ca_projeto/tela_criar_evento.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:intl/intl.dart';

// Importações internas
import '../../models/evento_ca.dart';
import '../../services/servico_firestore.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart'; // Cores e Temas

/// Caso de uso para o Widgetbook.
/// Permite visualizar a tela de criação de evento isoladamente.
@UseCase(
  name: 'Criar Evento',
  type: TelaCriarEvento,
)
Widget buildTelaCriarEvento(BuildContext context) {
  // Envolvemos em ProviderScope para simular o ambiente do Riverpod
  return const ProviderScope(
    child: TelaCriarEvento(),
  );
}

/// Tela para criação de novos eventos pelo C.A.
///
/// Permite definir:
/// - Nome do evento
/// - Data principal
/// - Local
/// - Número estimado de participantes
class TelaCriarEvento extends ConsumerStatefulWidget {
  const TelaCriarEvento({super.key});

  @override
  ConsumerState<TelaCriarEvento> createState() => _TelaCriarEventoState();
}

class _TelaCriarEventoState extends ConsumerState<TelaCriarEvento> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Controladores de texto
  final _nomeController = TextEditingController();
  final _localController = TextEditingController();
  final _participantesController = TextEditingController();
  
  // Estado local para a data
  DateTime? _dataSelecionada;

  @override
  void dispose() {
    _nomeController.dispose();
    _localController.dispose();
    _participantesController.dispose();
    super.dispose();
  }

  /// Abre o seletor de data nativo.
  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030), // Permite agendar para anos futuros
    );
    if (data != null) {
      setState(() => _dataSelecionada = data);
    }
  }

  /// Valida e salva o evento no Firestore.
  Future<void> _salvarEvento() async {
    // 1. Validação de campos
    if (!_formKey.currentState!.validate() || _dataSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // 2. Pega o ID do organizador (Usuário Logado)
    final organizadorId = ref.read(provedorNotificadorAutenticacao).usuario?.uid;
    if (organizadorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não autenticado.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() => _isLoading = true);

    // 3. Cria o objeto EventoCA
    final novoEvento = EventoCA(
      id: '', // O ID será gerado automaticamente pelo Firestore
      nome: _nomeController.text,
      data: _dataSelecionada!,
      local: _localController.text,
      totalParticipantes: int.tryParse(_participantesController.text) ?? 0,
      organizadorId: organizadorId,
      participantesInscritos: [], // Inicia sem participantes
    );

    try {
      // 4. Chama o serviço para salvar
      await ref.read(servicoFirestoreProvider).adicionarEvento(novoEvento);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento criado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); // Fecha a tela e volta para a lista
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    // Configuração de Tema (Claro/Escuro)
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final inputFill = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade300;

    // Estilo comum para os inputs
    InputDecoration _inputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        filled: true,
        fillColor: inputFill,
        labelStyle: TextStyle(color: isDark ? Colors.grey : Colors.black54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryPurple)),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Respeita o tema
      appBar: AppBar(
        title: Text(
          t.t('ca_eventos_criar_titulo'), 
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho Visual
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_note, color: AppColors.primaryPurple, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Preencha os dados para divulgar um novo evento no campus.",
                        style: TextStyle(color: textColor?.withOpacity(0.8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Campo Nome
              TextFormField(
                controller: _nomeController,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration(t.t('ca_eventos_criar_nome')),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              
              // Campo Local
              TextFormField(
                controller: _localController,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration(t.t('ca_eventos_criar_local')),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              
              // Campo Participantes (Estimativa)
              TextFormField(
                controller: _participantesController,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration(t.t('ca_eventos_criar_participantes')),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Seletor de Data
              InkWell(
                onTap: () => _selecionarData(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dataSelecionada == null 
                          ? t.t('ca_eventos_criar_data') 
                          : DateFormat('dd/MM/yyyy').format(_dataSelecionada!),
                        style: TextStyle(
                          color: _dataSelecionada == null ? (isDark ? Colors.grey : Colors.black54) : textColor
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: AppColors.primaryPurple),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

              // Botão Salvar
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _salvarEvento,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Salvando...' : t.t('ca_eventos_criar_salvar'),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
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
// lib/telas/aluno/tela_solicitar_adaptacao.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provedores_app.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../services/servico_firestore.dart';
import '../../models/solicitacao_aluno.dart';
import '../../models/turma_professor.dart';
import '../comum/widget_carregamento.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io'; 
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../comum/animacao_fadein_lista.dart';

class TelaSolicitarAdaptacao extends ConsumerStatefulWidget {
  const TelaSolicitarAdaptacao({super.key});

  @override
  ConsumerState<TelaSolicitarAdaptacao> createState() => _TelaSolicitarAdaptacaoState();
}

class _TelaSolicitarAdaptacaoState extends ConsumerState<TelaSolicitarAdaptacao> {
  final _formKey = GlobalKey<FormState>();
  TurmaProfessor? _turmaSelecionada;
  final _descricaoController = TextEditingController();
  bool _isLoading = false;
  File? _arquivoSelecionado;

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  // --- FUNÇÕES LÓGICAS QUE FALTAVAM ---

  Future<void> _pegarArquivo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
      );
      if (result != null) {
        setState(() {
          // Correção para Web: Em Web o path pode ser nulo, mas bytes não.
          // Mas para este exemplo vamos assumir mobile ou tratar no serviço
          if (result.files.single.path != null) {
             _arquivoSelecionado = File(result.files.single.path!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
        );
      }
    }
  }

  Future<void> _enviarSolicitacao() async {
    if (!_formKey.currentState!.validate() || _turmaSelecionada == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final usuario = ref.read(provedorNotificadorAutenticacao).usuario;
    if (usuario == null || usuario.alunoInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Não foi possível identificar o aluno.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    String? nomeAnexo;
    try {
      if (_arquivoSelecionado != null) {
        nomeAnexo = _arquivoSelecionado!.path.split(Platform.pathSeparator).last;
      }

      final novaSolicitacao = SolicitacaoAluno(
        id: '', 
        nomeAluno: usuario.alunoInfo!.nomeCompleto,
        ra: usuario.alunoInfo!.ra,
        disciplina: _turmaSelecionada!.nome,
        tipo: 'Adaptação de Prova', 
        data: DateTime.now(),
        descricao: _descricaoController.text,
        anexo: nomeAnexo, 
        status: StatusSolicitacao.pendente,
        alunoId: usuario.uid,
        professorId: _turmaSelecionada!.professorId, 
        turmaId: _turmaSelecionada!.id,
        respostaProfessor: null, 
      );

      await ref.read(servicoFirestoreProvider).adicionarSolicitacao(novaSolicitacao);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitação enviada com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
       if (mounted) {
         setState(() => _isLoading = false);
       }
    }
  }
  // --- FIM DAS FUNÇÕES ---

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final asyncTurmas = ref.watch(provedorStreamTurmasAluno);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.t('adaptacao_titulo'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Aviso
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primaryPurple),
                    const SizedBox(width: 12),
                    Expanded(child: Text(t.t('adaptacao_aviso'), style: const TextStyle(color: Colors.white70))),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dropdown Turma
              asyncTurmas.when(
                loading: () => const LinearProgressIndicator(),
                error: (_,__) => const Text("Erro ao carregar"),
                data: (turmas) => DropdownButtonFormField<TurmaProfessor>(
                  value: _turmaSelecionada,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: t.t('adaptacao_disciplina'),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  items: turmas.map((t) => DropdownMenuItem(value: t, child: Text(t.nome))).toList(),
                  onChanged: (v) => setState(() => _turmaSelecionada = v),
                ),
              ),
              const SizedBox(height: 16),

              // Descrição
              TextFormField(
                controller: _descricaoController,
                style: const TextStyle(color: Colors.white),
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: t.t('adaptacao_descricao'),
                  filled: true,
                  fillColor: AppColors.surface,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),

              // Botão Anexo
              OutlinedButton.icon(
                icon: Icon(_arquivoSelecionado == null ? Icons.attach_file : Icons.check_circle, color: _arquivoSelecionado == null ? Colors.white : AppColors.success),
                label: Text(
                  _arquivoSelecionado == null ? t.t('adaptacao_anexar') : 'Arquivo Selecionado',
                  style: const TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _pegarArquivo, 
              ),
              
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _enviarSolicitacao, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(t.t('adaptacao_enviar'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
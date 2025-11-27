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

  Future<void> _pegarArquivo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
      if (result != null) {
        setState(() {
          // Workaround seguro para web/mobile
          if (result.files.single.path != null) _arquivoSelecionado = File(result.files.single.path!);
        });
      }
    } catch (e) { /* Ignora */ }
  }

  Future<void> _enviarSolicitacao() async {
    if (!_formKey.currentState!.validate() || _turmaSelecionada == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha os campos.'), backgroundColor: Colors.red));
       return;
    }
    
    final usuario = ref.read(provedorNotificadorAutenticacao).usuario;
    if (usuario == null) return;

    setState(() => _isLoading = true);
    
    String? nomeAnexo;
    try {
      if (_arquivoSelecionado != null) nomeAnexo = _arquivoSelecionado!.path.split(Platform.pathSeparator).last;

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enviado com sucesso!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final asyncTurmas = ref.watch(provedorStreamTurmasAluno);
    
    // TEMA
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final isDark = theme.brightness == Brightness.dark;
    final inputFill = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.black12;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.t('adaptacao_titulo'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    Expanded(child: Text(t.t('adaptacao_aviso'), style: TextStyle(color: textColor?.withOpacity(0.8)))),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dropdown
              asyncTurmas.when(
                loading: () => const LinearProgressIndicator(),
                error: (_,__) => const Text("Erro ao carregar"),
                data: (turmas) => DropdownButtonFormField<TurmaProfessor>(
                  value: _turmaSelecionada,
                  dropdownColor: inputFill,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: t.t('adaptacao_disciplina'),
                    filled: true,
                    fillColor: inputFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                  ),
                  items: turmas.map((t) => DropdownMenuItem(value: t, child: Text(t.nome, style: TextStyle(color: textColor)))).toList(),
                  onChanged: (v) => setState(() => _turmaSelecionada = v),
                ),
              ),
              const SizedBox(height: 16),

              // Descrição
              TextFormField(
                controller: _descricaoController,
                style: TextStyle(color: textColor),
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: t.t('adaptacao_descricao'),
                  filled: true,
                  fillColor: inputFill,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                ),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),

              // Botão Anexo
              OutlinedButton.icon(
                icon: Icon(_arquivoSelecionado == null ? Icons.attach_file : Icons.check_circle, color: _arquivoSelecionado == null ? textColor : AppColors.success),
                label: Text(
                  _arquivoSelecionado == null ? t.t('adaptacao_anexar') : 'Arquivo Selecionado',
                  style: TextStyle(color: textColor),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: borderColor),
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
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(t.t('adaptacao_enviar'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
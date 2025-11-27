// lib/telas/aluno/tela_editar_perfil.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../models/aluno_info.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../comum/overlay_carregamento.dart';

class TelaEditarPerfil extends ConsumerStatefulWidget {
  final bool isFromSignUp; 
  const TelaEditarPerfil({super.key, this.isFromSignUp = false});

  @override
  ConsumerState<TelaEditarPerfil> createState() => _TelaEditarPerfilState();
}

class _TelaEditarPerfilState extends ConsumerState<TelaEditarPerfil> {
  final _formKey = GlobalKey<FormState>();
  late final AlunoInfo _alunoInfoOriginal;

  final _nomeController = TextEditingController();
  final _raController = TextEditingController();
  String? _cursoSelecionado;
  DateTime? _dataNascimento;
  String? _statusSelecionado;

  final List<String> _statusOpcoes = ['Regular', 'Trancado', 'Jubilado', 'Concluído'];
  bool _controllersInicializados = false;
  bool _isAluno = true; // Flag para saber se mostra campos de aluno

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controllersInicializados) {
      final usuario = ref.read(provedorNotificadorAutenticacao).usuario;
      final alunoInfo = usuario?.alunoInfo;
      
      // Verifica se é aluno
      _isAluno = usuario?.papel == 'aluno';

      _nomeController.text = alunoInfo?.nomeCompleto ?? '';
      _raController.text = alunoInfo?.ra ?? '';
      
      if (alunoInfo != null && AppLocalizations.cursos.contains(alunoInfo.curso)) {
        _cursoSelecionado = alunoInfo.curso;
      }
      _dataNascimento = alunoInfo?.dataNascimento;
      _statusSelecionado = alunoInfo?.status ?? 'Regular';
      
      if (alunoInfo != null) {
         _alunoInfoOriginal = alunoInfo;
      } else {
         _alunoInfoOriginal = AlunoInfo(nomeCompleto: '', ra: '', curso: '', cr: 0.0, status: 'Regular', dataNascimento: DateTime.now());
      }
      _controllersInicializados = true;
    }
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Se for aluno, valida campos extras
    if (_isAluno && (_dataNascimento == null || _cursoSelecionado == null)) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos.'), backgroundColor: AppColors.error));
       return;
    }

    ref.read(provedorCarregando.notifier).state = true;

    final novoAlunoInfo = AlunoInfo(
      nomeCompleto: _nomeController.text.trim(),
      ra: _raController.text.trim(),
      curso: _isAluno ? _cursoSelecionado! : '', // Prof/CA não tem curso
      dataNascimento: _isAluno ? _dataNascimento : null,
      cr: _alunoInfoOriginal.cr, 
      status: _isAluno ? _statusSelecionado! : '',
    );

    try {
      await ref.read(provedorNotificadorAutenticacao.notifier).salvarPerfilAluno(novoAlunoInfo);
      if (widget.isFromSignUp) {
          await ref.read(provedorNotificadorAutenticacao.notifier).selecionarPapel(ref.read(provedorNotificadorAutenticacao).usuario!.papel);
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Error
    } finally {
      if (mounted) ref.read(provedorCarregando.notifier).state = false;
    }
  }
  
  void _selecionarDataNascimento() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (data != null) setState(() => _dataNascimento = data);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.t('editar_perfil_titulo'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _salvarPerfil,
            child: Text('Salvar', style: GoogleFonts.poppins(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("NOME COMPLETO"),
              TextFormField(
                controller: _nomeController,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(hintText: "Digite seu nome"),
              ),
              const SizedBox(height: 20),

              _buildLabel(_isAluno ? "RA (MATRÍCULA)" : "ID / SIAPE"),
              TextFormField(
                controller: _raController,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(hintText: "Digite o número"),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),

              // CAMPOS SÓ PARA ALUNO
              if (_isAluno) ...[
                _buildLabel("CURSO"),
                DropdownButtonFormField<String>(
                  value: _cursoSelecionado,
                  style: TextStyle(color: textColor),
                  decoration: const InputDecoration(hintText: "Selecione o curso"),
                  items: AppLocalizations.cursos.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _cursoSelecionado = v),
                ),
                const SizedBox(height: 20),

                _buildLabel("DATA DE NASCIMENTO"),
                InkWell(
                  onTap: _selecionarDataNascimento,
                  child: InputDecorator(
                    decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today)),
                    child: Text(
                      _dataNascimento == null ? 'Selecionar Data' : DateFormat('dd/MM/yyyy').format(_dataNascimento!),
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                _buildLabel("STATUS"),
                DropdownButtonFormField<String>(
                  value: _statusSelecionado,
                  style: TextStyle(color: textColor),
                  decoration: const InputDecoration(),
                  items: _statusOpcoes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _statusSelecionado = v),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          color: Colors.grey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
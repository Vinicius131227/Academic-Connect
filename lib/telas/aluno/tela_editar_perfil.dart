// lib/telas/aluno/tela_editar_perfil.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../providers/provedor_autenticacao.dart';
import '../../models/aluno_info.dart';
import '../../l10n/app_localizations.dart'; // Traduções
import '../../themes/app_theme.dart'; // Cores e Temas
import '../comum/overlay_carregamento.dart'; // Loading

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Editar Perfil',
  type: TelaEditarPerfil,
)
Widget buildTelaEditarPerfil(BuildContext context) {
  return const ProviderScope(
    child: TelaEditarPerfil(),
  );
}

/// Tela que permite ao usuário editar suas informações de perfil.
class TelaEditarPerfil extends ConsumerStatefulWidget {
  final bool isFromSignUp; 
  
  const TelaEditarPerfil({
    super.key, 
    this.isFromSignUp = false
  });

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
  bool _isAluno = true; 

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Movemos a inicialização para cá para ter acesso seguro ao contexto e traduções
    if (!_controllersInicializados) {
      final t = AppLocalizations.of(context);
      // Se por algum motivo as traduções não carregarem, aborta (segurança)
      if (t == null) return; 

      final usuario = ref.read(provedorNotificadorAutenticacao).usuario;
      final alunoInfo = usuario?.alunoInfo;
      
      _isAluno = usuario?.papel == 'aluno';

      _nomeController.text = alunoInfo?.nomeCompleto ?? '';
      _raController.text = alunoInfo?.ra ?? '';
      
      // CORREÇÃO 1: Usando t.cursos (instância) em vez de AppLocalizations.cursos (estático)
      if (alunoInfo != null && t.cursos.contains(alunoInfo.curso)) {
        _cursoSelecionado = alunoInfo.curso;
      }
      _dataNascimento = alunoInfo?.dataNascimento;
      _statusSelecionado = alunoInfo?.status ?? 'Regular';
      
      if (alunoInfo != null) {
         _alunoInfoOriginal = alunoInfo;
      } else {
         _alunoInfoOriginal = AlunoInfo(
           nomeCompleto: '', 
           ra: '', 
           curso: '', 
           cr: 0.0, 
           status: 'Regular', 
           dataNascimento: DateTime.now()
         );
      }
      _controllersInicializados = true;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _raController.dispose();
    super.dispose();
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isAluno && (_dataNascimento == null || _cursoSelecionado == null)) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Preencha todos os campos.'), backgroundColor: AppColors.error)
       );
       return;
    }

    ref.read(provedorCarregando.notifier).state = true;

    final novoAlunoInfo = AlunoInfo(
      nomeCompleto: _nomeController.text.trim(),
      ra: _raController.text.trim(),
      curso: _isAluno ? _cursoSelecionado! : '', 
      dataNascimento: _isAluno ? _dataNascimento : null,
      cr: _alunoInfoOriginal.cr, 
      status: _isAluno ? _statusSelecionado! : '',
    );

    try {
      await ref.read(provedorNotificadorAutenticacao.notifier).salvarPerfilAluno(novoAlunoInfo);
      
      if (widget.isFromSignUp) {
          await ref.read(provedorNotificadorAutenticacao.notifier).selecionarPapel(
            ref.read(provedorNotificadorAutenticacao).usuario!.papel
          );
      }
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
       // Erro
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
    final isDark = theme.brightness == Brightness.dark;
    
    final inputLabelColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t.t('editar_perfil_titulo'), 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _salvarPerfil,
            child: Text(
              t.t('salvar'), 
              style: GoogleFonts.poppins(
                color: AppColors.primaryPurple, 
                fontWeight: FontWeight.bold, 
                fontSize: 16
              )
            ),
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
              // --- 1. CAMPO NOME ---
              _buildLabel(t.t('cadastro_nome_label'), inputLabelColor),
              TextFormField(
                controller: _nomeController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(hintText: "Digite seu nome"),
                validator: (v) => v!.isEmpty ? t.t('campo_obrigatorio') : null,
              ),
              const SizedBox(height: 20),

              // --- 2. CAMPO ID ---
              _buildLabel(_isAluno ? t.t('cadastro_ra_label') : t.t('cadastro_num_prof'), inputLabelColor),
              TextFormField(
                controller: _raController,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(hintText: "Digite o número"),
                keyboardType: TextInputType.text,
                validator: (v) => v!.isEmpty ? t.t('campo_obrigatorio') : null,
              ),
              const SizedBox(height: 20),

              // --- 3. CAMPOS ALUNO ---
              if (_isAluno) ...[
                // Curso
                _buildLabel(t.t('cadastro_curso'), inputLabelColor),
                DropdownButtonFormField<String>(
                  value: _cursoSelecionado,
                  style: TextStyle(color: textColor),
                  dropdownColor: theme.cardTheme.color, 
                  decoration: const InputDecoration(hintText: "Selecione o curso"),
                  // CORREÇÃO 2: Usando t.cursos
                  items: t.cursos.map((c) => DropdownMenuItem(
                    value: c, 
                    child: Text(c)
                  )).toList(),
                  onChanged: (v) => setState(() => _cursoSelecionado = v),
                ),
                const SizedBox(height: 20),

                // Data de Nascimento
                _buildLabel(t.t('cadastro_data_nasc_label'), inputLabelColor),
                InkWell(
                  onTap: _selecionarDataNascimento,
                  child: InputDecorator(
                    decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today)),
                    child: Text(
                      _dataNascimento == null 
                          ? 'Selecionar Data' 
                          : DateFormat('dd/MM/yyyy').format(_dataNascimento!),
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Status
                _buildLabel(t.t('aluno_perfil_status'), inputLabelColor),
                DropdownButtonFormField<String>(
                  value: _statusSelecionado,
                  style: TextStyle(color: textColor),
                  dropdownColor: theme.cardTheme.color,
                  decoration: const InputDecoration(),
                  items: _statusOpcoes.map((c) => DropdownMenuItem(
                    value: c, 
                    child: Text(c)
                  )).toList(),
                  onChanged: (v) => setState(() => _statusSelecionado = v),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
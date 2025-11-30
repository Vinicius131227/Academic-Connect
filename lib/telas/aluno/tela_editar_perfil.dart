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
/// Simula a tela de edição de perfil.
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
///
/// O formulário se adapta automaticamente ao tipo de usuário (Aluno vs Outros).
class TelaEditarPerfil extends ConsumerStatefulWidget {
  /// Define se a tela foi aberta durante o fluxo de cadastro inicial (pós-login social).
  /// Se verdadeiro, ao salvar, o usuário é redirecionado para a Home.
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
  
  // Armazena os dados originais para manter campos que não são editáveis nesta tela (ex: CR)
  late final AlunoInfo _alunoInfoOriginal;

  // Controladores de texto
  final _nomeController = TextEditingController();
  final _raController = TextEditingController();
  
  // Estado dos campos de seleção
  String? _cursoSelecionado;
  DateTime? _dataNascimento;
  String? _statusSelecionado;

  // Opções fixas para o status do aluno
  final List<String> _statusOpcoes = ['Regular', 'Trancado', 'Jubilado', 'Concluído'];
  
  // Flags de controle
  bool _controllersInicializados = false;
  bool _isAluno = true; // Define quais campos mostrar

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inicializa os controladores apenas uma vez, usando os dados do provedor
    if (!_controllersInicializados) {
      final usuario = ref.read(provedorNotificadorAutenticacao).usuario;
      final alunoInfo = usuario?.alunoInfo;
      
      // Verifica o papel do usuário para ajustar a UI
      _isAluno = usuario?.papel == 'aluno';

      _nomeController.text = alunoInfo?.nomeCompleto ?? '';
      _raController.text = alunoInfo?.ra ?? '';
      
      // Preenche dropdowns se os dados existirem
      if (alunoInfo != null && AppLocalizations.cursos.contains(alunoInfo.curso)) {
        _cursoSelecionado = alunoInfo.curso;
      }
      _dataNascimento = alunoInfo?.dataNascimento;
      _statusSelecionado = alunoInfo?.status ?? 'Regular';
      
      // Salva o objeto original ou cria um padrão
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

  /// Salva as alterações no Firestore.
  Future<void> _salvarPerfil() async {
    // 1. Valida formulário básico
    if (!_formKey.currentState!.validate()) return;
    
    // 2. Validação extra apenas para alunos (campos obrigatórios)
    if (_isAluno && (_dataNascimento == null || _cursoSelecionado == null)) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Preencha todos os campos.'), backgroundColor: AppColors.error)
       );
       return;
    }

    // 3. Ativa loading
    ref.read(provedorCarregando.notifier).state = true;

    // 4. Cria o novo objeto de informações
    final novoAlunoInfo = AlunoInfo(
      nomeCompleto: _nomeController.text.trim(),
      ra: _raController.text.trim(),
      // Se não for aluno, salva vazio ou mantém compatibilidade
      curso: _isAluno ? _cursoSelecionado! : '', 
      dataNascimento: _isAluno ? _dataNascimento : null,
      cr: _alunoInfoOriginal.cr, // Mantém o CR original (não editável)
      status: _isAluno ? _statusSelecionado! : '',
    );

    try {
      // 5. Chama o provedor para salvar
      await ref.read(provedorNotificadorAutenticacao.notifier).salvarPerfilAluno(novoAlunoInfo);
      
      // Se for fluxo de cadastro inicial, confirma o papel
      if (widget.isFromSignUp) {
          await ref.read(provedorNotificadorAutenticacao.notifier).selecionarPapel(
            ref.read(provedorNotificadorAutenticacao).usuario!.papel
          );
      }
      
      // 6. Fecha a tela com sucesso
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
       // Erros são tratados pelo provedor, mas podemos adicionar snackbar aqui se necessário
    } finally {
      // 7. Desativa loading
      if (mounted) ref.read(provedorCarregando.notifier).state = false;
    }
  }
  
  /// Abre o seletor de data nativo.
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
    
    // Configuração de Tema (Claro/Escuro)
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final isDark = theme.brightness == Brightness.dark;
    
    // Cor dos labels (cinza suave)
    final inputLabelColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Fundo dinâmico
      appBar: AppBar(
        title: Text(
          t.t('editar_perfil_titulo'), // "Editar Perfil"
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
          // Botão Salvar na AppBar
          TextButton(
            onPressed: _salvarPerfil,
            child: Text(
              t.t('salvar'), // "Salvar"
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
                // InputDecoration vem do tema global (app_theme.dart)
                decoration: InputDecoration(hintText: "Digite seu nome"),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 20),

              // --- 2. CAMPO ID (RA ou SIAPE) ---
              // O rótulo muda dependendo do tipo de usuário
              _buildLabel(_isAluno ? t.t('cadastro_ra_label') : t.t('cadastro_num_prof'), inputLabelColor),
              TextFormField(
                controller: _raController,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(hintText: "Digite o número"),
                keyboardType: TextInputType.text,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 20),

              // --- 3. CAMPOS ESPECÍFICOS DE ALUNO ---
              if (_isAluno) ...[
                // Curso
                _buildLabel(t.t('cadastro_curso'), inputLabelColor),
                DropdownButtonFormField<String>(
                  value: _cursoSelecionado,
                  style: TextStyle(color: textColor),
                  dropdownColor: theme.cardTheme.color, // Fundo do menu
                  decoration: const InputDecoration(hintText: "Selecione o curso"),
                  items: AppLocalizations.cursos.map((c) => DropdownMenuItem(
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
                
                // Status (Regular, Trancado...)
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

  /// Widget auxiliar para criar os rótulos dos campos (Labels).
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
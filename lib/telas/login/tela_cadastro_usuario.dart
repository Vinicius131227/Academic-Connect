// lib/telas/login/tela_cadastro_usuario.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../providers/provedor_autenticacao.dart';
import '../../models/aluno_info.dart';
import '../../l10n/app_localizations.dart';
import '../comum/overlay_carregamento.dart';
import '../../themes/app_theme.dart';
import 'portao_autenticacao.dart';

@UseCase(
  name: 'Cadastro de Usuário',
  type: TelaCadastroUsuario,
)
Widget buildTelaCadastro(BuildContext context) {
  return const ProviderScope(
    child: TelaCadastroUsuario(),
  );
}

class TelaCadastroUsuario extends ConsumerStatefulWidget {
  final bool isInitialSetup;
  final String email;
  final String password;

  const TelaCadastroUsuario({
    super.key,
    this.isInitialSetup = false,
    this.email = '',
    this.password = '',
  });

  @override
  ConsumerState<TelaCadastroUsuario> createState() => _TelaCadastroUsuarioState();
}

class _TelaCadastroUsuarioState extends ConsumerState<TelaCadastroUsuario> {
  final _formKey = GlobalKey<FormState>();

  String _papelSelecionado = 'aluno';
  final _nomeController = TextEditingController();
  final _raOuIdController = TextEditingController();
  final _cursoController = TextEditingController();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  final _dataNascimentoController = TextEditingController();

  DateTime? _dataNascimento;
  String? _tipoIdentificacao; 

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    _passwordController = TextEditingController(text: widget.password);
    _confirmPasswordController = TextEditingController(text: widget.password);
    
    // Reseta o loading assim que a tela abre. 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(provedorCarregando.notifier).state = false;
    });

    if (widget.isInitialSetup) {
      final user = ref.read(provedorNotificadorAutenticacao).usuario;
      if (user != null) {
         _emailController.text = user.email;
         // Tenta preencher o nome se o Google já forneceu
         if (user.alunoInfo?.nomeCompleto != null) {
            _nomeController.text = user.alunoInfo!.nomeCompleto;
         }
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _raOuIdController.dispose();
    _cursoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dataNascimentoController.dispose();
    super.dispose();
  }

  void _selecionarDataNascimento() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (data != null) {
      setState(() {
        _dataNascimento = data;
        _dataNascimentoController.text = DateFormat('dd/MM/yyyy').format(data);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_papelSelecionado == 'aluno' && _dataNascimento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data de nascimento obrigatória'), backgroundColor: Colors.redAccent)
      );
      return;
    }

    // Ativa loading apenas para o processo de SALVAR
    ref.read(provedorCarregando.notifier).state = true;
    final t = AppLocalizations.of(context)!;

    try {
      if (widget.isInitialSetup) {
        // Completar Cadastro (vindo do Google)
        if (_papelSelecionado == 'aluno') {
          final info = AlunoInfo(
            nomeCompleto: _nomeController.text.trim(),
            ra: _raOuIdController.text.trim(),
            curso: _cursoController.text.trim(),
            dataNascimento: _dataNascimento!,
            cr: 0.0,
            status: 'Regular',
          );
          await ref.read(provedorNotificadorAutenticacao.notifier).salvarPerfilAluno(info);
          await ref.read(provedorNotificadorAutenticacao.notifier).selecionarPapel('aluno');
        } else {
          // Professor
          await ref.read(provedorNotificadorAutenticacao.notifier).selecionarPapel(
            _papelSelecionado, 
            tipoIdentificacao: _tipoIdentificacao ?? 'N/A',
            numIdentificacao: _raOuIdController.text.trim()
          );
        }
      } else {
        // Cadastro Novo (Email/Senha)
        if (_papelSelecionado == 'aluno') {
          await ref.read(provedorNotificadorAutenticacao.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            nomeCompleto: _nomeController.text.trim(),
            ra: _raOuIdController.text.trim(),
            curso: _cursoController.text.trim(),
            dataNascimento: _dataNascimento!,
          );
        } else {
          // Professor
          await ref.read(provedorNotificadorAutenticacao.notifier).signUpComIdentificacao(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            papel: _papelSelecionado,
            nomeCompleto: _nomeController.text.trim(),
            identificacao: _raOuIdController.text.trim(),
            tipoIdentificacao: _tipoIdentificacao ?? 'N/A',
          );
        }
      }
      
      if (mounted) {
        // Desativa loading antes de navegar
        ref.read(provedorCarregando.notifier).state = false;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('cadastro_sucesso')), backgroundColor: Colors.green)
        );
        
        // Força a navegação para o Portão
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PortaoAutenticacao()), 
          (route) => false
        );
      }

    } catch (e) {
      if (mounted) {
        ref.read(provedorCarregando.notifier).state = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<void> _googleSignUp() async {
    ref.read(provedorCarregando.notifier).state = true;
    try {
       await ref.read(provedorNotificadorAutenticacao.notifier).loginComGoogle();
    } catch (e) {
       ref.read(provedorCarregando.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final estaCarregando = ref.watch(provedorCarregando);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color fillColor = isDark ? AppColors.surfaceDark : Colors.white;
    final Color dropdownColor = isDark ? AppColors.surfaceDark : Colors.white;
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.t('cadastro_titulo'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Row(
        children: [
          // --- LADO ESQUERDO: FORMULÁRIO ---
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(t.t('cadastro_subtitulo'), style: GoogleFonts.poppins(fontSize: 14, color: subTextColor), textAlign: TextAlign.center),
                        const SizedBox(height: 30),

                        _buildStyledDropdown(
                          context,
                          label: t.t('cadastro_universidade'),
                          value: 'UFSCar - Campus Sorocaba',
                          items: const ['UFSCar - Campus Sorocaba'],
                          onChanged: null,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          fillColor: fillColor,
                          dropdownColor: dropdownColor,
                        ),
                        const SizedBox(height: 20),

                        _buildStyledDropdown(
                          context,
                          label: t.t('cadastro_papel_label'),
                          value: _papelSelecionado,
                          items: ['aluno', 'professor'], 
                          displayItems: [t.t('papel_aluno'), t.t('papel_professor')],
                          onChanged: estaCarregando ? null : (v) {
                            if (v != null) {
                              setState(() {
                                _papelSelecionado = v;
                                _raOuIdController.clear();
                                _cursoController.clear();
                                _dataNascimento = null;
                                _dataNascimentoController.clear();
                                _tipoIdentificacao = null;
                              });
                            }
                          },
                          textColor: textColor,
                          subTextColor: subTextColor,
                          fillColor: fillColor,
                          dropdownColor: dropdownColor,
                        ),
                        const SizedBox(height: 20),

                        // Nome
                        _buildStyledTextField(
                          context, 
                          controller: _nomeController, 
                          label: t.t('cadastro_nome_label'), 
                          hint: 'John Doe', 
                          enabled: !estaCarregando, 
                          textColor: textColor, 
                          subTextColor: subTextColor, 
                          fillColor: fillColor
                        ),
                        const SizedBox(height: 20),

                        // Campos extras apenas se NÃO for initial setup (não veio do Google)
                        if (!widget.isInitialSetup) ...[
                          _buildStyledTextField(context, controller: _emailController, label: t.t('login_email'), hint: 'user@email.com', enabled: !estaCarregando, inputType: TextInputType.emailAddress, textColor: textColor, subTextColor: subTextColor, fillColor: fillColor),
                          const SizedBox(height: 20),
                          _buildStyledTextField(context, controller: _passwordController, label: t.t('login_senha'), hint: '••••••••', isObscure: true, enabled: !estaCarregando, validator: (v) => (v == null || v.length < 6) ? t.t('dica_senha_curta') : null, textColor: textColor, subTextColor: subTextColor, fillColor: fillColor),
                          const SizedBox(height: 20),
                          _buildStyledTextField(context, controller: _confirmPasswordController, label: t.t('cadastro_confirmar_senha'), hint: '••••••••', isObscure: true, enabled: !estaCarregando, validator: (v) => (v != _passwordController.text) ? t.t('cadastro_erro_senha') : null, textColor: textColor, subTextColor: subTextColor, fillColor: fillColor),
                          const SizedBox(height: 20),
                        ],

                        // Campos específicos ALUNO vs PROFESSOR
                        if (_papelSelecionado == 'aluno') ...[
                          _buildStyledDropdown(
                            context,
                            label: t.t('cadastro_curso'),
                            value: _cursoController.text.isEmpty ? null : _cursoController.text,
                            items: t.cursos, 
                            onChanged: estaCarregando ? null : (v) { if (v != null) setState(() => _cursoController.text = v); },
                            textColor: textColor,
                            subTextColor: subTextColor,
                            fillColor: fillColor,
                            dropdownColor: dropdownColor,
                          ),
                          const SizedBox(height: 20),
                          _buildStyledTextField(context, controller: _raOuIdController, label: t.t('cadastro_ra_label'), hint: '123456', inputType: TextInputType.number, enabled: !estaCarregando, textColor: textColor, subTextColor: subTextColor, fillColor: fillColor),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: estaCarregando ? null : _selecionarDataNascimento,
                            child: AbsorbPointer(child: _buildStyledTextField(context, controller: _dataNascimentoController, label: t.t('cadastro_data_nasc_label'), hint: 'dd/mm/aaaa', suffixIcon: Icon(Icons.calendar_today, color: subTextColor, size: 18), textColor: textColor, subTextColor: subTextColor, fillColor: fillColor)),
                          ),
                        ] else ...[
                           _buildStyledTextField(
                             context, 
                             controller: _raOuIdController, 
                             label: t.t('cadastro_num_prof'), 
                             hint: '123456', 
                             enabled: !estaCarregando, 
                             textColor: textColor, 
                             subTextColor: subTextColor, 
                             fillColor: fillColor
                           ),
                        ],

                        const SizedBox(height: 40),

                        // Botão Cadastrar/Salvar
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: estaCarregando ? null : _submit,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 5),
                            child: estaCarregando ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(widget.isInitialSetup ? t.t('aluno_perfil_salvar') : t.t('cadastro_botao'), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        
                        // Botão Google (Só aparece se for cadastro do zero, não se for completar cadastro)
                        if (!widget.isInitialSetup) ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: estaCarregando ? null : _googleSignUp,
                              style: OutlinedButton.styleFrom(side: BorderSide(color: subTextColor.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), foregroundColor: textColor),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Image.asset(
                                  'assets/images/google_logo.png', 
                                  height: 24,
                                  errorBuilder: (c,e,s) => const Icon(Icons.g_mobiledata, size: 24),
                                ), 
                                const SizedBox(width: 12), 
                                Text(t.t('login_google_btn') ?? 'Google', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500))
                              ]),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          if (isDesktop)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF8C52FF),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF9D5CFF), Color(0xFF8C52FF)]),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Join the\nCommunity', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                      const SizedBox(height: 40),
                      ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400), child: const Icon(Icons.group_add_rounded, size: 200, color: Colors.white24)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildStyledTextField(BuildContext context, {required TextEditingController controller, required String label, String hint = '', bool isObscure = false, bool enabled = true, TextInputType? inputType, Widget? suffixIcon, String? Function(String?)? validator, required Color textColor, required Color subTextColor, required Color fillColor}) {
    final t = AppLocalizations.of(context)!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller, 
        obscureText: isObscure, 
        keyboardType: inputType, 
        enabled: enabled, 
        style: TextStyle(color: textColor),
        validator: validator ?? (v) => (v == null || v.isEmpty) ? t.t('campo_obrigatorio') ?? 'Obrigatório' : null,
        decoration: InputDecoration(
          hintText: hint, 
          hintStyle: TextStyle(color: subTextColor.withOpacity(0.5)),
          filled: true, 
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: subTextColor.withOpacity(0.3))),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryPurple)),
          errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
          suffixIcon: suffixIcon
        ),
      ),
    ]);
  }

  Widget _buildStyledDropdown(BuildContext context, {required String label, required String? value, required List<String> items, List<String>? displayItems, required void Function(String?)? onChanged, required Color textColor, required Color subTextColor, required Color fillColor, required Color dropdownColor}) {
    final t = AppLocalizations.of(context)!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: value,
        items: List.generate(items.length, (index) => DropdownMenuItem(value: items[index], child: Text(displayItems != null ? displayItems[index] : items[index], style: TextStyle(color: textColor)))),
        onChanged: onChanged,
        dropdownColor: dropdownColor,
        style: TextStyle(color: textColor),
        iconEnabledColor: subTextColor,
        decoration: InputDecoration(
          filled: true, 
          fillColor: fillColor, 
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), 
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: subTextColor.withOpacity(0.3))), 
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryPurple)), 
          errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent))
        ),
        validator: (v) => v == null ? t.t('campo_obrigatorio') ?? 'Obrigatório' : null
      ),
    ]);
  }
}
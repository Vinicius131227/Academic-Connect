import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../models/aluno_info.dart';
import '../../l10n/app_localizations.dart';
import '../comum/overlay_carregamento.dart';
import '../../themes/app_theme.dart';

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
  String? _universidadeSelecionada = 'UFSCar - Campus Sorocaba';
  String? _tipoIdentificacao;

  final List<String> _opcoesIdentificacao = ['Matrícula', 'SIAPE', 'Outro'];

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    _passwordController = TextEditingController(text: widget.password);
    _confirmPasswordController = TextEditingController(text: widget.password);
    
    if (widget.isInitialSetup) {
      final user = ref.read(provedorNotificadorAutenticacao).usuario;
      if (user != null) _emailController.text = user.email;
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data de nascimento obrigatória'), backgroundColor: Colors.redAccent));
      return;
    }
    ref.read(provedorCarregando.notifier).state = true;
    final t = AppLocalizations.of(context)!;

    try {
      if (widget.isInitialSetup) {
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
          await ref.read(provedorNotificadorAutenticacao.notifier).selecionarPapel(_papelSelecionado, tipoIdentificacao: _tipoIdentificacao ?? 'N/A');
        }
      } else {
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.t('cadastro_sucesso')), backgroundColor: Colors.green));
        if (!widget.isInitialSetup) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) ref.read(provedorCarregando.notifier).state = false;
    }
  }

  Future<void> _googleSignUp() async {
    ref.read(provedorCarregando.notifier).state = true;
    await ref.read(provedorNotificadorAutenticacao.notifier).loginComGoogle();
    if (mounted) ref.read(provedorCarregando.notifier).state = false;
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
                          label: t.t('cadastro_papel_label'),
                          value: _papelSelecionado,
                          items: ['aluno', 'professor', 'ca_projeto'],
                          displayItems: [t.t('papel_aluno'), t.t('papel_professor'), t.t('papel_ca')],
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

                        _buildStyledTextField(controller: _nomeController, label: t.t('cadastro_nome_label'), hint: 'John Doe', enabled: !estaCarregando, textColor: textColor, subTextColor: subTextColor, fillColor: fillColor),
                        const SizedBox(height: 20),

                        if (!widget.isInitialSetup) ...[
                          _buildStyledTextField(controller: _emailController, label: t.t('login_email'), hint: 'user@email.com', enabled: !estaCarregando, inputType: TextInputType.emailAddress, textColor: textColor, subTextColor: subTextColor, fillColor: fillColor),
                          const SizedBox(height: 20),
                          _buildStyledTextField(controller: _passwordController, label: t.t('login_senha'), hint: '••••••••', isObscure: true, enabled: !estaCarregando, validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null, textColor: textColor, subTextColor: subTextColor, fillColor: fillColor),
                          const SizedBox(height: 20),
                          _buildStyledTextField(controller: _confirmPasswordController, label: t.t('cadastro_confirmar_senha'), hint: '••••••••', isObscure: true, enabled: !estaCarregando, validator: (v) => (v != _passwordController.text) ? t.t('cadastro_erro_senha') : null, textColor: textColor, subTextColor: subTextColor, fillColor: fillColor),
                          const SizedBox(height: 20),
                        ],

                        if (_papelSelecionado == 'aluno') ...[
                          _buildStyledDropdown(
                            label: t.t('cadastro_curso'),
                            value: _cursoController.text.isEmpty ? null : _cursoController.text,
                            items: AppLocalizations.cursos,
                            onChanged: estaCarregando ? null : (v) { if (v != null) setState(() => _cursoController.text = v); },
                            textColor: textColor,
                            subTextColor: subTextColor,
                            fillColor: fillColor,
                            dropdownColor: dropdownColor,
                          ),
                          const SizedBox(height: 20),
                          _buildStyledTextField(controller: _raOuIdController, label: t.t('cadastro_ra_label'), hint: '123456', inputType: TextInputType.number, enabled: !estaCarregando, textColor: textColor, subTextColor: subTextColor, fillColor: fillColor),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: estaCarregando ? null : _selecionarDataNascimento,
                            child: AbsorbPointer(child: _buildStyledTextField(controller: _dataNascimentoController, label: t.t('cadastro_data_nasc_label'), hint: 'dd/mm/aaaa', suffixIcon: Icon(Icons.calendar_today, color: subTextColor, size: 18), textColor: textColor, subTextColor: subTextColor, fillColor: fillColor)),
                          ),
                        ] else ...[
                           _buildStyledDropdown(
                            label: t.t('cadastro_identificacao_prof'),
                            value: _tipoIdentificacao,
                            items: _opcoesIdentificacao,
                            onChanged: estaCarregando ? null : (v) => setState(() => _tipoIdentificacao = v),
                            textColor: textColor,
                            subTextColor: subTextColor,
                            fillColor: fillColor,
                            dropdownColor: dropdownColor,
                           ),
                           const SizedBox(height: 20),
                           _buildStyledTextField(controller: _raOuIdController, label: t.t('cadastro_num_prof'), hint: '123456', enabled: !estaCarregando, textColor: textColor, subTextColor: subTextColor, fillColor: fillColor),
                        ],

                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: estaCarregando ? null : _submit,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 5),
                            child: estaCarregando ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(widget.isInitialSetup ? t.t('aluno_perfil_salvar') : t.t('cadastro_botao'), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        
                        if (!widget.isInitialSetup) ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: estaCarregando ? null : _googleSignUp,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: subTextColor.withOpacity(0.5)), 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                                foregroundColor: textColor
                              ),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Image.asset('assets/images/google_logo.png', height: 24),
                                const SizedBox(width: 12),
                                Text('Sign up with Google', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
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

  Widget _buildStyledTextField({required TextEditingController controller, required String label, String hint = '', bool isObscure = false, bool enabled = true, TextInputType? inputType, Widget? suffixIcon, String? Function(String?)? validator, required Color textColor, required Color subTextColor, required Color fillColor}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller, obscureText: isObscure, keyboardType: inputType, enabled: enabled, style: TextStyle(color: textColor),
        validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
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

  Widget _buildStyledDropdown({required String label, required String? value, required List<String> items, List<String>? displayItems, required void Function(String?)? onChanged, required Color textColor, required Color subTextColor, required Color fillColor, required Color dropdownColor}) {
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
          errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
        ),
        validator: (v) => v == null ? 'Required' : null,
      ),
    ]);
  }
}
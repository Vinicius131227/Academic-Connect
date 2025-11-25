import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../models/aluno_info.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
// --- IMPORT ESSENCIAL ADICIONADO ABAIXO ---
import '../comum/overlay_carregamento.dart'; 

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
  // ignore: unused_field
  String? _universidadeSelecionada = 'UFSCar - Campus Sorocaba';

  // Cores do Design
  final Color bgDark = const Color(0xFF181818);
  final Color bgPurple = const Color(0xFF8C52FF);
  final Color textWhite = Colors.white;
  final Color textGrey = Colors.grey.shade500;
  
  // Identificações Prof/CA (Lista simples para o dropdown)
  final List<String> _opcoesIdentificacao = ['Matrícula', 'SIAPE', 'Outro'];
  String? _tipoIdentificacao;

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

  Future<void> _googleSignUp() async {
    ref.read(provedorCarregando.notifier).state = true;
    await ref.read(provedorNotificadorAutenticacao.notifier).loginComGoogle();
    if (mounted) ref.read(provedorCarregando.notifier).state = false;
  }

  void _selecionarDataNascimento() async {
    final theme = Theme.of(context);
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.primaryPurple,
              onPrimary: AppColors.textWhite,
              surface: AppColors.surface,
              onSurface: AppColors.textWhite,
            ),
            dialogBackgroundColor: AppColors.background,
          ),
          child: child!,
        );
      },
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Date of birth required'),
          backgroundColor: AppColors.error));
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
          await ref
              .read(provedorNotificadorAutenticacao.notifier)
              .salvarPerfilAluno(info);
          await ref
              .read(provedorNotificadorAutenticacao.notifier)
              .selecionarPapel('aluno');
        } else {
          await ref
              .read(provedorNotificadorAutenticacao.notifier)
              .selecionarPapel(_papelSelecionado,
                  tipoIdentificacao: _tipoIdentificacao ?? 'N/A', 
                  numIdentificacao: _raOuIdController.text.trim());
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
          await ref
              .read(provedorNotificadorAutenticacao.notifier)
              .signUpComIdentificacao(
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t.t('cadastro_sucesso')),
            backgroundColor: AppColors.success));
        if (!widget.isInitialSetup) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) ref.read(provedorCarregando.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final estaCarregando = ref.watch(provedorCarregando);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: bgDark,
      body: Row(
        children: [
          // --- METADE ESQUERDA (FORMULÁRIO) ---
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(t.t('cadastro_titulo'),
                            style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: textWhite)),
                        const SizedBox(height: 8),
                        Text(t.t('cadastro_subtitulo'),
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: textGrey)),
                        const SizedBox(height: 30),

                        _buildStyledDropdown(
                          label: t.t('cadastro_universidade'),
                          value: 'UFSCar - Campus Sorocaba',
                          items: const ['UFSCar - Campus Sorocaba'],
                          onChanged: null,
                        ),
                        const SizedBox(height: 20),

                        _buildStyledDropdown(
                          label: t.t('cadastro_papel_label'),
                          value: _papelSelecionado,
                          items: ['aluno', 'professor', 'ca_projeto'],
                          displayItems: [
                            t.t('papel_aluno'),
                            t.t('papel_professor'),
                            t.t('papel_ca')
                          ],
                          onChanged: estaCarregando
                              ? null
                              : (v) {
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
                        ),
                        const SizedBox(height: 20),

                        _buildStyledTextField(
                            controller: _nomeController,
                            label: t.t('cadastro_nome_label'),
                            hint: 'John Doe',
                            enabled: !estaCarregando),
                        const SizedBox(height: 20),

                        if (!widget.isInitialSetup) ...[
                          _buildStyledTextField(
                              controller: _emailController,
                              label: t.t('login_email'),
                              hint: 'user@email.com',
                              enabled: !estaCarregando,
                              inputType: TextInputType.emailAddress),
                          const SizedBox(height: 20),
                          _buildStyledTextField(
                              controller: _passwordController,
                              label: t.t('login_senha'),
                              hint: '••••••••',
                              isObscure: true,
                              enabled: !estaCarregando,
                              validator: (v) => (v == null || v.length < 6)
                                  ? 'Min 6 chars'
                                  : null),
                          const SizedBox(height: 20),
                          _buildStyledTextField(
                              controller: _confirmPasswordController,
                              label: t.t('cadastro_confirmar_senha'),
                              hint: '••••••••',
                              isObscure: true,
                              enabled: !estaCarregando,
                              validator: (v) => (v != _passwordController.text)
                                  ? t.t('cadastro_erro_senha')
                                  : null),
                          const SizedBox(height: 20),
                        ],

                        if (_papelSelecionado == 'aluno') ...[
                          _buildStyledDropdown(
                            label: t.t('cadastro_curso'),
                            value: _cursoController.text.isEmpty
                                ? null
                                : _cursoController.text,
                            items: AppLocalizations.cursos,
                            onChanged: estaCarregando
                                ? null
                                : (v) {
                                    if (v != null) {
                                      setState(() => _cursoController.text = v);
                                    }
                                  },
                          ),
                          const SizedBox(height: 20),
                          _buildStyledTextField(
                              controller: _raOuIdController,
                              label: t.t('cadastro_ra_label'),
                              hint: '123456',
                              inputType: TextInputType.number,
                              enabled: !estaCarregando),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap:
                                estaCarregando ? null : _selecionarDataNascimento,
                            child: AbsorbPointer(
                                child: _buildStyledTextField(
                                    controller: _dataNascimentoController,
                                    label: t.t('cadastro_data_nasc_label'),
                                    hint: 'dd/mm/aaaa',
                                    suffixIcon: const Icon(
                                        Icons.calendar_today,
                                        color: Colors.grey,
                                        size: 18))),
                          ),
                        ] else ...[
                           // PROFESSOR / CA
                           _buildStyledDropdown(
                            label: t.t('cadastro_identificacao_prof'),
                            value: _tipoIdentificacao,
                            items: _opcoesIdentificacao,
                            onChanged: estaCarregando ? null : (v) => setState(() => _tipoIdentificacao = v),
                           ),
                           const SizedBox(height: 20),
                           _buildStyledTextField(
                              controller: _raOuIdController,
                              label: t.t('cadastro_num_prof'),
                              hint: '123456',
                              enabled: !estaCarregando),
                        ],

                        const SizedBox(height: 40),

                        // Botão de Cadastro
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: estaCarregando ? null : _submit,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: bgPurple,
                                foregroundColor: textWhite,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 5),
                            child: estaCarregando
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text(
                                    widget.isInitialSetup
                                        ? t.t('aluno_perfil_salvar')
                                        : t.t('cadastro_botao'),
                                    style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Botão Google e Link para Login
                        if (!widget.isInitialSetup) ...[
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(
                                      color: textGrey.withOpacity(0.3))),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Text('Or',
                                      style: TextStyle(
                                          color: textGrey, fontSize: 12))),
                              Expanded(
                                  child: Divider(
                                      color: textGrey.withOpacity(0.3))),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: estaCarregando ? null : _googleSignUp,
                              style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: textGrey.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  foregroundColor: textWhite),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/google_logo.png',
                                      height: 24),
                                  const SizedBox(width: 12),
                                  Text('Sign up with Google',
                                      style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account? ",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 13)),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text('Sign in',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- METADE DIREITA (ARTE) ---
          if (isDesktop)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF8C52FF),
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF9D5CFF), Color(0xFF8C52FF)]),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Join the\nCommunity',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2)),
                      const SizedBox(height: 40),
                      ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxWidth: 400, maxHeight: 400),
                          // Placeholder para a imagem
                          child: const Icon(Icons.group_add_rounded,
                              size: 200, color: Colors.white24)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField(
      {required TextEditingController controller,
      required String label,
      String hint = '',
      bool isObscure = false,
      bool enabled = true,
      TextInputType? inputType,
      Widget? suffixIcon,
      String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          keyboardType: inputType,
          enabled: enabled,
          style: const TextStyle(color: Colors.white),
          validator:
              validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade700),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade800)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF8C52FF))),
            errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red)),
            focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2)),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Widget _buildStyledDropdown(
      {required String label,
      required String? value,
      required List<String> items,
      List<String>? displayItems,
      required void Function(String?)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: List.generate(items.length, (index) {
            return DropdownMenuItem(
                value: items[index],
                child: Text(displayItems != null ? displayItems[index] : items[index],
                    style: const TextStyle(color: Colors.white)));
          }),
          onChanged: onChanged,
          dropdownColor: const Color(0xFF2C2C2C),
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.grey.shade600,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.transparent,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade800)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF8C52FF))),
            errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red)),
          ),
          validator: (v) => v == null ? 'Required' : null,
        ),
      ],
    );
  }
}
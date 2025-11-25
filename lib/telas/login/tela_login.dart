// lib/telas/login/tela_login.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/provedor_autenticacao.dart';
import 'tela_esqueceu_senha.dart'; 
import '../../l10n/app_localizations.dart';
import 'tela_cadastro_usuario.dart';
import '../comum/overlay_carregamento.dart'; 
import '../../themes/app_theme.dart'; 

class TelaLogin extends ConsumerStatefulWidget {
  const TelaLogin({super.key});
  @override
  ConsumerState<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends ConsumerState<TelaLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  // ... (MANTENHA OS MÉTODOS DISPOSE, _login, _loginGoogle IGUAIS) ...
  // Vou pular para a parte do BUILD para economizar espaço, use a lógica da resposta anterior.
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
      if (_formKey.currentState!.validate()) {
        ref.read(provedorCarregando.notifier).state = true;
        await ref.read(provedorNotificadorAutenticacao.notifier).login(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
        if (mounted) ref.read(provedorCarregando.notifier).state = false;
      }
  }

  Future<void> _loginGoogle() async {
    ref.read(provedorCarregando.notifier).state = true;
    await ref.read(provedorNotificadorAutenticacao.notifier).loginComGoogle();
    if (mounted) ref.read(provedorCarregando.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final estaCarregando = ref.watch(provedorCarregando);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ... (LOGO AC MANTIDA) ...
                        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primaryPurple, AppColors.secondaryPurple]), borderRadius: BorderRadius.circular(24)), child: const Text('AC', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold))),
                        const SizedBox(height: 24),
                        
                        Text(t.t('login_titulo'), style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(t.t('login_subtitulo'), style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey)),
                        const SizedBox(height: 40),

                        // EMAIL
                        _buildTextField(
                          label: t.t('login_email'),
                          controller: _emailController,
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 20),
                        
                        // SENHA
                        _buildTextField(
                          label: t.t('login_senha'),
                          controller: _passwordController,
                          icon: Icons.lock_outline,
                          isObscure: _obscurePassword,
                          isPassword: true,
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaEsqueceuSenha())),
                            child: Text(t.t('login_esqueceu_senha'), style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // BOTÃO LOGIN
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: estaCarregando ? null : _login,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: Text(t.t('login_entrar'), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        // DIVISOR
                        Row(children: [const Expanded(child: Divider(color: Colors.white24)), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(t.t('login_ou_continue'), style: const TextStyle(color: Colors.white54, fontSize: 12))), const Expanded(child: Divider(color: Colors.white24))]),
                        const SizedBox(height: 24),
                        
                        // GOOGLE
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: estaCarregando ? null : _loginGoogle,
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), foregroundColor: Colors.white),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Image.asset('assets/google_logo.png', height: 24), const SizedBox(width: 12), Text('Google', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500))]),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // SIGN UP
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("${t.t('login_nao_tem_conta')} ", style: const TextStyle(color: AppColors.textGrey, fontSize: 13)), GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaCadastroUsuario())), child: Text(t.t('login_cadastre_se'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)))]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isDesktop) Expanded(flex: 5, child: Container(color: AppColors.primaryPurple)),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, IconData? icon, bool isObscure = false, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) : null,
            filled: true,
            fillColor: Colors.transparent,
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade800)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryPurple)),
          ),
        ),
      ],
    );
  }
}
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
        if (mounted) {
          ref.read(provedorCarregando.notifier).state = false;
        }
      }
  }

  Future<void> _loginGoogle() async {
    ref.read(provedorCarregando.notifier).state = true;
    await ref.read(provedorNotificadorAutenticacao.notifier).loginComGoogle();
    if (mounted) {
      ref.read(provedorCarregando.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final estaCarregando = ref.watch(provedorCarregando);
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 800;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // CORREÇÃO: Uso de Cores Não-Nulas (Garantia com '!' ou fallback)
    final textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final dividerColor = isDark ? Colors.white24 : Colors.black12;
    final Color inputBorderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    ref.listen(provedorNotificadorAutenticacao, (previous, next) {
      if (next.erro != null && previous?.erro != next.erro) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.erro!), backgroundColor: AppColors.error),
        );
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                        Container(
                          padding: const EdgeInsets.all(16), 
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryPurple, AppColors.secondaryPurple]
                            ), 
                            borderRadius: BorderRadius.circular(24)
                          ), 
                          child: const Text(
                            'AC', 
                            style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)
                          )
                        ),
                        const SizedBox(height: 24),
                        
                        Text(
                          t.t('login_titulo'), 
                          style: GoogleFonts.poppins(
                            fontSize: 32, 
                            fontWeight: FontWeight.bold, 
                            color: textColor
                          )
                        ),
                        Text(
                          t.t('login_subtitulo'), 
                          style: GoogleFonts.poppins(
                            fontSize: 14, 
                            color: subTextColor
                          )
                        ),
                        const SizedBox(height: 40),

                        _buildTextField(
                          label: t.t('login_email'),
                          hint: 'user@email.com',
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          borderColor: inputBorderColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 20),
                        
                        _buildTextField(
                          label: t.t('login_senha'),
                          hint: '••••••••',
                          controller: _passwordController,
                          icon: Icons.lock_outline,
                          isObscure: _obscurePassword,
                          isPassword: true,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          borderColor: inputBorderColor,
                          isDark: isDark,
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (_) => const TelaEsqueceuSenha())
                            ),
                            child: Text(
                              t.t('login_esqueceu_senha'), 
                              style: TextStyle(color: subTextColor, fontSize: 12)
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: estaCarregando ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple, 
                              foregroundColor: Colors.white, 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 5,
                            ),
                            child: estaCarregando 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  t.t('login_entrar'), 
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)
                                ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: Divider(color: dividerColor)), 
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10), 
                              child: Text(
                                t.t('login_ou_continue'), 
                                style: TextStyle(color: subTextColor, fontSize: 12)
                              )
                            ), 
                            Expanded(child: Divider(color: dividerColor))
                          ]
                        ),
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: estaCarregando ? null : _loginGoogle,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: dividerColor), 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                              foregroundColor: textColor
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center, 
                              children: [
                                Image.asset('assets/images/google_logo.png', height: 24), 
                                const SizedBox(width: 12), 
                                Text(
                                  'Google', 
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)
                                )
                              ]
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center, 
                          children: [
                            Text(
                              "${t.t('login_nao_tem_conta')} ", 
                              style: TextStyle(color: subTextColor, fontSize: 13)
                            ), 
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (_) => const TelaCadastroUsuario())
                              ), 
                              child: Text(
                                t.t('login_cadastre_se'), 
                                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)
                              )
                            )
                          ]
                        ),
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
                  color: AppColors.primaryPurple,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.secondaryPurple, AppColors.primaryPurple],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      t.t('login_bemvindo_arte'), 
                      textAlign: TextAlign.center, 
                      style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                    const SizedBox(height: 40),
                    const Icon(Icons.school_rounded, size: 200, color: Colors.white24),
                  ],
                ),
              )
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label, 
    String? hint, 
    required TextEditingController controller, 
    IconData? icon, 
    bool isObscure = false, 
    bool isPassword = false, 
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    required bool isDark
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: TextStyle(
            color: subTextColor, 
            fontSize: 12, 
            fontWeight: FontWeight.w500
          )
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hint, 
            hintStyle: TextStyle(color: subTextColor.withOpacity(0.3)), 
            prefixIcon: Icon(icon, color: subTextColor),
            suffixIcon: isPassword 
                ? IconButton(
                    icon: Icon(
                      isObscure ? Icons.visibility_off : Icons.visibility, 
                      color: subTextColor
                    ), 
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword)
                  ) 
                : null,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryPurple, width: 2),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.error),
            ),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
        ),
      ],
    );
  }
}
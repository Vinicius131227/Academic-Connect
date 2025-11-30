// lib/telas/login/tela_login.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Importações internas
import '../../providers/provedor_autenticacao.dart';
import 'tela_esqueceu_senha.dart'; 
import '../../l10n/app_localizations.dart'; // Traduções
import 'tela_cadastro_usuario.dart'; // Cadastro
import 'portao_autenticacao.dart'; // Redirecionamento (Home)
import '../comum/overlay_carregamento.dart'; // Loading
import '../../themes/app_theme.dart'; // Cores

/// Tela de Login principal.
/// Permite autenticação por e-mail e senha ou provedores sociais (Google).
class TelaLogin extends ConsumerStatefulWidget {
  const TelaLogin({super.key});
  
  @override
  ConsumerState<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends ConsumerState<TelaLogin> {
  // Controladores de texto para os campos
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Chave global para validação do formulário
  final _formKey = GlobalKey<FormState>();
  
  // Estado para ocultar/mostrar senha
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Limpeza de memória
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Lógica de Login por E-mail e Senha.
  Future<void> _login() async {
      // 1. Valida os campos
      if (_formKey.currentState!.validate()) {
        // 2. Ativa o loading global (Overlay)
        ref.read(provedorCarregando.notifier).state = true;
        
        try {
          // 3. Chama o provedor de autenticação
          // Se der sucesso, o estado muda e o listener no build redireciona.
          await ref.read(provedorNotificadorAutenticacao.notifier).login(
                _emailController.text.trim(),
                _passwordController.text.trim(),
              );
        } catch (e) {
           // Erros são capturados aqui, mas o feedback visual é feito pelo listener
        } finally {
           // 4. Desativa o loading (sempre)
           if (mounted) ref.read(provedorCarregando.notifier).state = false;
        }
      }
  }

  /// Lógica de Login com Google.
  Future<void> _loginGoogle() async {
    ref.read(provedorCarregando.notifier).state = true;
    try {
      await ref.read(provedorNotificadorAutenticacao.notifier).loginComGoogle();
    } finally {
      if (mounted) ref.read(provedorCarregando.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!; // Acesso às traduções
    final estaCarregando = ref.watch(provedorCarregando);
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 800; // Breakpoint para layout desktop

    // --- CORES DINÂMICAS (TEMA) ---
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final textColor = isDark ? Colors.white : Colors.black87;
    // Garante cor não nula para uso com transparência
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final dividerColor = isDark ? Colors.white24 : Colors.black12;
    final inputBorderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    // --- ESCUTA DE ESTADO (REDIRECIONAMENTO) ---
    ref.listen(provedorNotificadorAutenticacao, (previous, next) {
      // Se houver erro, mostra SnackBar
      if (next.erro != null && previous?.erro != next.erro) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.erro!), 
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      // Se autenticou com sucesso, navega para o Portão (Home)
      // pushAndRemoveUntil remove a tela de login da pilha (botão voltar fecha o app)
      if (next.status == StatusAutenticacao.autenticado) {
         Navigator.of(context).pushAndRemoveUntil(
           MaterialPageRoute(builder: (_) => const PortaoAutenticacao()),
           (route) => false, 
         );
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // --- LADO ESQUERDO: FORMULÁRIO ---
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
                        // Logo AC com Gradiente
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
                        
                        // Títulos
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

                        // Campo Email
                        _buildTextField(
                          label: t.t('login_email'),
                          hint: 'user@email.com',
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          borderColor: inputBorderColor,
                        ),
                        const SizedBox(height: 20),
                        
                        // Campo Senha
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
                        ),

                        // Esqueceu a senha
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

                        // Botão Login Principal
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
                        
                        // Divisor "Ou continue com"
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
                        
                        // Botão Google
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
                        
                        // Link para Cadastro
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
          
          // --- LADO DIREITO: ARTE (Apenas Desktop/Web Grande) ---
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
                    // Ícone Grande Ilustrativo
                    const Icon(Icons.school_rounded, size: 200, color: Colors.white24),
                  ],
                ),
              )
            ),
        ],
      ),
    );
  }

  /// Widget auxiliar para criar campos de texto estilizados.
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
            // Placeholder transparente para não parecer texto digitado
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
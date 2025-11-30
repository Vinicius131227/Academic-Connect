// lib/telas/login/tela_esqueceu_senha.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Importações locais
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';

/// Tela para recuperação de senha via e-mail.
/// 
/// Permite que o usuário insira seu e-mail e receba um link de redefinição
/// enviado pelo Firebase Authentication.
class TelaEsqueceuSenha extends ConsumerStatefulWidget {
  const TelaEsqueceuSenha({super.key});

  @override
  ConsumerState<TelaEsqueceuSenha> createState() => _TelaEsqueceuSenhaState();
}

class _TelaEsqueceuSenhaState extends ConsumerState<TelaEsqueceuSenha> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Controla o estado do botão de envio

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Função para enviar o link de redefinição de senha.
  Future<void> _enviarLink() async {
    // 1. Valida o campo de e-mail
    if (!_formKey.currentState!.validate()) return;
    
    // 2. Ativa o loading
    setState(() => _isLoading = true);
    
    try {
      // 3. Chama o Firebase Auth
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        // 4. Sucesso: Mostra mensagem e fecha a tela
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Link enviado para ${_emailController.text}'), 
            backgroundColor: Colors.green
          )
        );
        Navigator.of(context).pop(); 
      }
    } on FirebaseAuthException catch (e) {
      // 5. Erro específico do Firebase
      if (mounted) {
        String msg = 'Erro ao enviar.';
        if (e.code == 'user-not-found') msg = 'E-mail não cadastrado.';
        if (e.code == 'invalid-email') msg = 'E-mail inválido.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent)
        );
      }
    } catch (e) {
      // 6. Erro genérico
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro inesperado.'), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      // 7. Para o loading
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Definição de cores dinâmicas baseadas no tema
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    // Garante cor não nula para usar com transparência
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Fundo dinâmico (Branco/Preto)
      
      // AppBar transparente apenas para o botão de voltar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor), 
          onPressed: () => Navigator.pop(context)
        ),
      ),
      extendBodyBehindAppBar: true, // Conteúdo sobe atrás da AppBar
      
      body: Row(
        children: [
          // --- LADO ESQUERDO: FORMULÁRIO ---
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ícone de Cadeado
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withOpacity(0.1), 
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: const Icon(Icons.lock_reset, size: 40, color: AppColors.primaryPurple),
                        ),
                        const SizedBox(height: 24),
                        
                        // Títulos
                        Text(
                          t.t('esqueceu_titulo'), // "Esqueceu a Senha?"
                          style: GoogleFonts.poppins(
                            fontSize: 32, 
                            fontWeight: FontWeight.bold, 
                            color: textColor
                          )
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.t('esqueceu_subtitulo'), // "Digite seu e-mail..."
                          style: GoogleFonts.poppins(fontSize: 14, color: subTextColor)
                        ),
                        const SizedBox(height: 40),

                        // Campo de E-mail
                        TextFormField(
                          controller: _emailController,
                          style: TextStyle(color: textColor),
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: t.t('login_email'),
                            prefixIcon: Icon(Icons.email_outlined, color: subTextColor),
                            filled: true,
                            fillColor: Colors.transparent,
                            // Bordas adaptáveis
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: subTextColor.withOpacity(0.3))
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primaryPurple)
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty || !v.contains('@')) {
                              return 'E-mail inválido';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 32),

                        // Botão Enviar
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _enviarLink,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24, 
                                    height: 24, 
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  )
                                : Text(
                                    t.t('esqueceu_enviar'), 
                                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),

                        // Link para Voltar ao Login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${t.t('esqueceu_voltar_login')} ", 
                              style: TextStyle(color: subTextColor, fontSize: 13)
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                t.t('esqueceu_login_link'), 
                                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // --- LADO DIREITO: ARTE (Apenas Desktop) ---
          if (isDesktop) 
            Expanded(
              flex: 5, 
              child: Container(color: AppColors.primaryPurple)
            ),
        ],
      ),
    );
  }
}
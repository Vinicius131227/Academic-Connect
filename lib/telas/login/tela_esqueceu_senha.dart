// lib/telas/login/tela_esqueceu_senha.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Importações locais (Mantive suas importações originais)
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';

/// Tela para recuperação de senha via e-mail.
class TelaEsqueceuSenha extends ConsumerStatefulWidget {
  const TelaEsqueceuSenha({super.key});

  @override
  ConsumerState<TelaEsqueceuSenha> createState() => _TelaEsqueceuSenhaState();
}

class _TelaEsqueceuSenhaState extends ConsumerState<TelaEsqueceuSenha> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; 

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Função para enviar o link de redefinição de senha.
  Future<void> _enviarLink() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Link enviado para ${_emailController.text}'), 
            backgroundColor: Colors.green
          )
        );
        Navigator.of(context).pop(); 
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = 'Erro ao enviar.';
        if (e.code == 'user-not-found') msg = 'E-mail não cadastrado.';
        if (e.code == 'invalid-email') msg = 'E-mail inválido.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro inesperado.'), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor), 
          onPressed: () => Navigator.pop(context)
        ),
      ),
      extendBodyBehindAppBar: true,
      
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
                        // Ícone de Cadeado (Pequeno - Topo do form)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withOpacity(0.1), 
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: const Icon(Icons.lock_reset, size: 40, color: AppColors.primaryPurple),
                        ),
                        const SizedBox(height: 24),
                        
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
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryPurple,
                      // Cria um degradê sutil usando a cor primária
                      AppColors.primaryPurple.withOpacity(0.8),
                      // Você pode adicionar uma cor mais escura aqui se desejar mais contraste
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ícone Grande Decorativo
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 2)
                        ),
                        child: const Icon(
                          Icons.lock_person_outlined, // Ícone representando segurança/usuário
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Texto de Destaque
                      Text(
                        'Recuperação de Acesso',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Subtítulo explicativo
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: Text(
                          'Verifique sua caixa de entrada após o envio.\nSegurança e simplicidade para você retomar o controle.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
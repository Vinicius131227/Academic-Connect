// lib/telas/comum/tela_alterar_senha.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Alterar Senha',
  type: TelaAlterarSenha,
)
Widget buildTelaAlterarSenha(BuildContext context) {
  return const ProviderScope(child: TelaAlterarSenha());
}

/// Tela para redefinição de senha do usuário logado.
///
/// Exige:
/// 1. Senha Atual (para re-autenticação).
/// 2. Nova Senha.
/// 3. Confirmação da Nova Senha.
class TelaAlterarSenha extends ConsumerStatefulWidget {
  const TelaAlterarSenha({super.key});

  @override
  ConsumerState<TelaAlterarSenha> createState() => _TelaAlterarSenhaState();
}

class _TelaAlterarSenhaState extends ConsumerState<TelaAlterarSenha> {
  final _formKey = GlobalKey<FormState>();
  final _atualController = TextEditingController();
  final _novaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _atualController.dispose();
    _novaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  /// Lógica para atualizar a senha no Firebase.
  Future<void> _atualizarSenha() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    final t = AppLocalizations.of(context)!;

    if (user == null) return;

    try {
      // 1. Re-autenticar o usuário (Segurança exigida pelo Firebase)
      final cred = EmailAuthProvider.credential(
        email: user.email!, 
        password: _atualController.text
      );
      await user.reauthenticateWithCredential(cred);

      // 2. Atualizar para a nova senha
      await user.updatePassword(_novaController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('sucesso')), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String erro = t.t('erro_generico');
      if (e.code == 'wrong-password') erro = 'Senha atual incorreta.';
      if (e.code == 'weak-password') erro = 'A nova senha é muito fraca.';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erro), backgroundColor: Colors.red)
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
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.t('config_alterar_senha'), style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Ícone de cadeado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, size: 40, color: AppColors.primaryPurple),
              ),
              const SizedBox(height: 32),

              // Campos
              _buildPasswordField(
                controller: _atualController, 
                label: t.t('alterar_senha_atual'),
                theme: theme,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _novaController, 
                label: t.t('alterar_senha_nova'),
                theme: theme,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _confirmarController, 
                label: t.t('alterar_senha_confirmar'),
                theme: theme,
                validator: (val) {
                  if (val != _novaController.text) return t.t('cadastro_erro_senha');
                  return null;
                }
              ),
              const SizedBox(height: 40),

              // Botão Salvar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _atualizarSenha,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(t.t('salvar'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller, 
    required String label, 
    required ThemeData theme,
    String? Function(String?)? validator
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      obscureText: true,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        prefixIcon: const Icon(Icons.lock, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator ?? (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
    );
  }
}
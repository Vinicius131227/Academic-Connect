import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../l10n/app_localizations.dart'; 

/// Tela para o usuário (já logado) solicitar a redefinição de senha.
/// Esta tela envia um e-mail de redefinição para o usuário logado.
class TelaAlterarSenha extends ConsumerStatefulWidget {
  const TelaAlterarSenha({super.key});
  @override
  ConsumerState<TelaAlterarSenha> createState() => _TelaAlterarSenhaState();
}

class _TelaAlterarSenhaState extends ConsumerState<TelaAlterarSenha> {
  bool _isLoading = false;

  Future<void> _enviarLinkAlteracaoSenha() async {
    setState(() => _isLoading = true);

    // Pega o email do usuário logado através do provedor de autenticação
    final email = ref.read(provedorNotificadorAutenticacao).usuario?.email;

    if (email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Usuário não encontrado.'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Chama o Firebase para enviar o email de redefinição
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Link para alterar senha enviado para $email'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar link.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final emailUsuario = ref.watch(provedorNotificadorAutenticacao).usuario?.email ?? '...';

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('alterar_senha_titulo')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            // Aviso
            Card(
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.security, color: theme.colorScheme.onSecondaryContainer, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.t('alterar_senha_aviso_email'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Formulário
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t.t('login_email'), style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(emailUsuario, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    // Botões
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            child: Text(t.t('config_sair_dialog_cancelar')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: _isLoading
                              ? Container(width: 20, height: 20, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_outlined, size: 18),
                            label: Text(_isLoading ? 'Enviando...' : t.t('esqueceu_senha_enviar')),
                            onPressed: _isLoading ? null : _enviarLinkAlteracaoSenha,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
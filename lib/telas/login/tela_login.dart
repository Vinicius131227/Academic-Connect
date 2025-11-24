// lib/telas/login/tela_login.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provedor_autenticacao.dart';
import 'tela_esqueceu_senha.dart'; 
import '../../l10n/app_localizations.dart';
import 'tela_cadastro_usuario.dart';
import '../comum/cartao_vidro.dart'; 
import '../../themes/app_theme.dart';
import '../comum/overlay_carregamento.dart'; 

class TelaLogin extends ConsumerStatefulWidget {
  const TelaLogin({super.key});
  @override
  ConsumerState<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends ConsumerState<TelaLogin> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
    
    ref.listen(provedorNotificadorAutenticacao, (previous, next) {
      if (next.erro != null && previous?.erro != next.erro) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.erro!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
    
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    Widget cardConteudo = Padding(
      padding: const EdgeInsets.all(28.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text('AC', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
            const SizedBox(height: 24),
            Text(t.t('login_titulo'), textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(color: isDark ? AppColors.darkText : AppColors.lightText)),
            Text(t.t('login_subtitulo'), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: t.t('login_email'), prefixIcon: const Icon(Icons.email_outlined)),
              validator: (v) => (v == null || !v.contains('@')) ? 'Insira um e-mail válido' : null,
              enabled: !estaCarregando,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: t.t('login_senha'), prefixIcon: const Icon(Icons.lock_outline)),
              validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              enabled: !estaCarregando,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: estaCarregando ? null : () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaEsqueceuSenha()));
                },
                child: Text(t.t('login_esqueceu_senha')),
              ),
            ),
            const SizedBox(height: 12), 
            ElevatedButton.icon(
              icon: const Icon(Icons.login_outlined, size: 18),
              label: Text(t.t('login_entrar')),
              onPressed: estaCarregando ? null : _login,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(t.t('login_ou'))),
                  const Expanded(child: Divider()),
                ],
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.g_mobiledata, size: 24), // Simplificado para evitar erro de asset
              label: Text(t.t('login_google')),
              onPressed: estaCarregando ? null : _loginGoogle, 
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: estaCarregando ? null : () {
                // --- CORREÇÃO: Passando parâmetros para TelaCadastroUsuario ---
                // Como o usuário está clicando em "Cadastrar", passamos os valores atuais
                // dos controllers para já preencher a próxima tela.
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => TelaCadastroUsuario(
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim(),
                  ))
                );
                // --- FIM DA CORREÇÃO ---
              },
              child: Text(t.t('login_nao_tem_conta')),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
            ? [AppColors.darkSurface, AppColors.darkBg]
            : [AppColors.lightPrimary.withOpacity(0.3), AppColors.lightBg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: isDark 
                  ? CartaoVidro(child: cardConteudo)
                  : Card(elevation: 8, shadowColor: Colors.black.withOpacity(0.1), child: cardConteudo),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
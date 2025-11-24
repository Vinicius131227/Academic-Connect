import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../l10n/app_localizations.dart';
import '../aluno/tela_editar_perfil.dart'; 
import '../comum/cartao_vidro.dart';
import '../comum/animacao_fadein_lista.dart'; 
import '../../themes/app_theme.dart';

class TelaSelecaoPapel extends ConsumerWidget {
  const TelaSelecaoPapel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoAuth = ref.watch(provedorNotificadorAutenticacao);
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    void _selecionarPapel(String papel) {
      if (estadoAuth.carregando) return;

      final usuario = estadoAuth.usuario;
      
      // Se for aluno E os dados não estiverem completos (ex: login com Google),
      // força ele a ir para a tela de edição de perfil.
      if (papel == 'aluno' && (usuario?.alunoInfo?.ra.isEmpty ?? true)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            // Passa um parâmetro para a tela de edição saber que veio do cadastro
            builder: (context) => const TelaEditarPerfil(isFromSignUp: true), 
          ),
        );
        // Salva o papel, mas a tela de perfil vai forçar o preenchimento
        ref.read(provedorNotificadorAutenticacao.notifier).selecionarPapel(papel);
      } else {
        // Se for professor, CA, ou um aluno já com dados, apenas salva o papel
        ref.read(provedorNotificadorAutenticacao.notifier).selecionarPapel(papel);
      }
    }

    final widgets = [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0), 
        child: Column(
          children: [
            Text(
              t.t('papel_titulo'),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t.t('papel_subtitulo'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      
      // Card Aluno
      _buildCardPapel(
        context,
        titulo: t.t('papel_aluno'),
        descricao: t.t('papel_aluno_desc'),
        icone: Icons.school_outlined,
        onTap: () => _selecionarPapel('aluno'),
      ),
      
      // Card Professor
      _buildCardPapel(
        context,
        titulo: t.t('papel_professor'),
        descricao: t.t('papel_professor_desc'),
        icone: Icons.work_outline,
        onTap: () => _selecionarPapel('professor'),
      ),
      
      // Card C.A.
      _buildCardPapel(
        context,
        titulo: t.t('papel_ca'),
        descricao: t.t('papel_ca_desc'),
        icone: Icons.group_work_outlined,
        onTap: () => _selecionarPapel('ca_projeto'),
      ),
    ];

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
          child: FadeInListAnimation(
            children: widgets.map((w) => 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: isDark ? CartaoVidro(child: w) : Card(elevation: 4, shadowColor: Colors.black.withOpacity(0.1), child: w),
              )
            ).toList(),
          ),
        ),
      ),
    );
  }

  /// Widget auxiliar para os cards de papel
  Widget _buildCardPapel(
    BuildContext context, {
    required String titulo,
    required String descricao,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16), 
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icone, size: 32, color: isDark ? AppColors.darkAccent : theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: theme.textTheme.titleLarge?.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText
                  )),
                  Text(descricao, style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary
                  )),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: theme.textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}
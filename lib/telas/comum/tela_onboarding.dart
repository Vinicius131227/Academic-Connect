import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provedor_onboarding.dart';
import '../../themes/app_theme.dart';
import 'cartao_vidro.dart';
import 'package:dots_indicator/dots_indicator.dart'; // Pacote para os "pontinhos"

// --- Página 1 do Onboarding ---
class _SlideOnboarding extends StatelessWidget {
  final String titulo;
  final String descricao;
  final IconData icone;

  const _SlideOnboarding({
    required this.titulo,
    required this.descricao,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CartaoVidro(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Icon(
                icone, 
                size: 100, 
                color: isDark ? AppColors.darkAccent : AppColors.lightPrimary,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            titulo,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            descricao,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// --- Tela Principal do Onboarding ---
class TelaOnboarding extends ConsumerStatefulWidget {
  const TelaOnboarding({super.key});

  @override
  ConsumerState<TelaOnboarding> createState() => _TelaOnboardingState();
}

class _TelaOnboardingState extends ConsumerState<TelaOnboarding> {
  final PageController _controller = PageController();
  int _paginaAtual = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _paginaAtual = _controller.page?.round() ?? 0;
      });
    });
  }
  
  void _concluirOnboarding() {
    // Salva que o usuário já viu o onboarding
    ref.read(provedorOnboarding.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    
    final paginas = [
      _SlideOnboarding(
        titulo: "Bem-vindo ao Academic Connect",
        descricao: "Sua vida acadêmica, organizada em um só lugar.",
        icone: Icons.school,
      ),
      _SlideOnboarding(
        titulo: "Presença por NFC",
        descricao: "Use seu cartão de estudante para marcar presença de forma rápida e segura.",
        icone: Icons.nfc,
      ),
      _SlideOnboarding(
        titulo: "Tudo na Palma da Mão",
        descricao: "Acesse notas, frequência, e comunicados. Vamos começar!",
        icone: Icons.auto_awesome,
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
        child: Stack(
          children: [
            // Slides
            PageView(
              controller: _controller,
              children: paginas,
            ),
            
            // Botão "Pular"
            Positioned(
              top: 60,
              right: 20,
              child: TextButton(
                onPressed: _concluirOnboarding,
                child: const Text("Pular"),
              ),
            ),
            
            // Indicador de página e Botão "Próximo"
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DotsIndicator(
                    dotsCount: paginas.length,
                    position: _paginaAtual,
                    decorator: DotsDecorator(
                      color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
                      activeColor: isDark ? AppColors.darkAccent : AppColors.lightPrimary,
                      size: const Size.square(9.0),
                      activeSize: const Size(18.0, 9.0),
                      activeShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                    ),
                  ),
                  
                  ElevatedButton(
                    onPressed: () {
                      if (_paginaAtual == paginas.length - 1) {
                        _concluirOnboarding(); // Última página
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    child: Text(
                      _paginaAtual == paginas.length - 1 ? "Começar" : "Próximo"
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
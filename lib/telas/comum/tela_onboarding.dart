// lib/telas/comum/tela_onboarding.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/provedor_onboarding.dart';
import '../../themes/app_theme.dart';
import 'cartao_vidro.dart';

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
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone com efeito de vidro
          CartaoVidro(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Icon(
                icone, 
                size: 80, 
                color: AppColors.primaryPurple, 
              ),
            ),
          ),
          const SizedBox(height: 48),
          
          Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          Text(
            descricao,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

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
    ref.read(provedorOnboarding.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final paginas = [
      const _SlideOnboarding(
        titulo: "Bem-vindo ao Academic Connect",
        descricao: "Sua vida acadêmica simplificada. Notas, presença e materiais em um único lugar.",
        icone: Icons.school_rounded,
      ),
      const _SlideOnboarding(
        titulo: "Chamada Inteligente",
        descricao: "Esqueça o papel. Marque presença aproximando seu cartão ou celular (NFC).",
        icone: Icons.nfc_rounded,
      ),
      const _SlideOnboarding(
        titulo: "Comunidade Acadêmica",
        descricao: "Acesse dicas de veteranos, provas antigas e materiais exclusivos da sua disciplina.",
        icone: Icons.hub_rounded,
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2C2C2C), 
              AppColors.background,
            ], 
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            PageView(
              controller: _controller,
              children: paginas,
            ),
            
            // Botão Pular
            Positioned(
              top: 50,
              right: 20,
              child: TextButton(
                onPressed: _concluirOnboarding,
                child: Text(
                  "Pular", 
                  style: GoogleFonts.poppins(
                    color: Colors.white54, 
                    fontWeight: FontWeight.w600
                  ),
                ),
              ),
            ),
            
            // Controles Inferiores
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
                      color: Colors.white12,
                      activeColor: AppColors.primaryPurple,
                      size: const Size.square(9.0),
                      activeSize: const Size(24.0, 9.0),
                      activeShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                    ),
                  ),
                  
                  ElevatedButton(
                    onPressed: () {
                      if (_paginaAtual == paginas.length - 1) {
                        _concluirOnboarding();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _paginaAtual == paginas.length - 1 ? "Começar" : "Próximo",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
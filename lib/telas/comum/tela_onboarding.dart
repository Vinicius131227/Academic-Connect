import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // Necessário para o efeito de vidro

import '../../providers/provedor_onboarding.dart';
import '../../themes/app_theme.dart';
import '../login/portao_autenticacao.dart'; // Importante para o redirecionamento

// Widget interno para o efeito de vidro (Glassmorphism)
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05), // Transparência sutil
            borderRadius: BorderRadius.circular(30.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.1), 
              width: 1.5
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// Widget para cada Slide
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
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone dentro do cartão de vidro
          _GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(50.0),
              child: Icon(
                icone, 
                size: 80, 
                color: AppColors.primaryPurple, // Roxo vibrante
              ),
            ),
          ),
          const SizedBox(height: 60),
          
          // Título
          Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Descrição
          Text(
            descricao,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white60, // Cinza claro para leitura
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
      if (_controller.page != null) {
        setState(() {
          _paginaAtual = _controller.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _concluirOnboarding() async {
    // 1. Salva no disco que o usuário já viu o onboarding
    await ref.read(provedorOnboarding.notifier).completeOnboarding();
    
    if (mounted) {
      // 2. Navega para o Portão de Autenticação e remove o histórico
      // Isso impede que o botão "Voltar" traga o usuário para cá novamente
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PortaoAutenticacao()),
        (route) => false, 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dados dos Slides
    final paginas = [
      const _SlideOnboarding(
        titulo: "Bem-vindo ao\nAcademic Connect",
        descricao: "Sua vida acadêmica simplificada. Notas, presença e materiais em um único lugar.",
        icone: Icons.school_rounded,
      ),
      const _SlideOnboarding(
        titulo: "Chamada\nInteligente",
        descricao: "Esqueça o papel. Marque presença aproximando seu cartão ou celular via NFC.",
        icone: Icons.nfc_rounded,
      ),
      const _SlideOnboarding(
        titulo: "Comunidade\nAcadêmica",
        descricao: "Acesse dicas de veteranos, provas antigas e materiais exclusivos da sua disciplina.",
        icone: Icons.hub_rounded,
      ),
    ];

    return Scaffold(
      // Fundo escuro global
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Fundo com gradiente sutil
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2C2C2C), // Topo um pouco mais claro
                  AppColors.backgroundDark, // Fundo padrão
                ], 
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Conteúdo dos Slides
          PageView(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            children: paginas,
          ),
          
          // Botão Pular (Topo Direita)
          Positioned(
            top: 60,
            right: 24,
            child: TextButton(
              onPressed: _concluirOnboarding,
              child: Text(
                "Pular", 
                style: GoogleFonts.poppins(
                  color: Colors.white38, 
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          // Controles Inferiores (Dots e Botão Principal)
          Positioned(
            bottom: 48,
            left: 32,
            right: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicadores de Página (Bolinhas)
                DotsIndicator(
                  dotsCount: paginas.length,
                  position: _paginaAtual,
                  decorator: DotsDecorator(
                    color: Colors.white12, // Cor inativa
                    activeColor: AppColors.primaryPurple, // Cor ativa (Roxo)
                    size: const Size.square(8.0),
                    activeSize: const Size(24.0, 8.0),
                    activeShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                    spacing: const EdgeInsets.all(4.0),
                  ),
                ),
                
                // Botão Próximo / Começar
                ElevatedButton(
                  onPressed: () {
                    if (_paginaAtual == paginas.length - 1) {
                      _concluirOnboarding();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: AppColors.primaryPurple.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _paginaAtual == paginas.length - 1 ? "Começar" : "Próximo",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
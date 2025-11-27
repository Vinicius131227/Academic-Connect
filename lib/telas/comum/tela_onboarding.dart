// lib/telas/comum/tela_onboarding.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; 

import '../../providers/provedor_onboarding.dart';
import '../../themes/app_theme.dart';
import '../login/portao_autenticacao.dart';

// Widget interno (Glassmorphism)
class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final Color bgColor;

  const _GlassCard({required this.child, required this.borderColor, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor, 
            borderRadius: BorderRadius.circular(30.0),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SlideOnboarding extends StatelessWidget {
  final String titulo;
  final String descricao;
  final IconData icone;
  final Color textColor;
  final Color iconColor;
  final Color cardBg;
  final Color cardBorder;

  const _SlideOnboarding({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.textColor,
    required this.iconColor,
    required this.cardBg,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GlassCard(
            borderColor: cardBorder,
            bgColor: cardBg,
            child: Padding(
              padding: const EdgeInsets.all(50.0),
              child: Icon(icone, size: 80, color: iconColor),
            ),
          ),
          const SizedBox(height: 60),
          Text(titulo, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: textColor, height: 1.2), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(descricao, style: GoogleFonts.poppins(fontSize: 16, color: textColor.withOpacity(0.7), height: 1.5), textAlign: TextAlign.center),
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
      if (_controller.page != null) setState(() => _paginaAtual = _controller.page!.round());
    });
  }
  
  Future<void> _concluirOnboarding() async {
    await ref.read(provedorOnboarding.notifier).completeOnboarding();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const PortaoAutenticacao()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // CORES DINÂMICAS (Respeita o Claro/Escuro)
    final Color bgBottom = theme.scaffoldBackgroundColor;
    final Color bgTop = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100;
    final Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final Color primaryColor = AppColors.primaryPurple;
    
    // Cores do vidro
    final Color glassBg = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    final Color glassBorder = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);

    final paginas = [
      _SlideOnboarding(
        titulo: "Bem-vindo ao\nAcademic Connect",
        descricao: "Sua vida acadêmica simplificada. Notas, presença e materiais em um único lugar.",
        icone: Icons.school_rounded,
        textColor: textColor,
        iconColor: primaryColor,
        cardBg: glassBg,
        cardBorder: glassBorder,
      ),
      _SlideOnboarding(
        titulo: "Chamada\nInteligente",
        descricao: "Esqueça o papel. Marque presença aproximando seu cartão ou celular via NFC.",
        icone: Icons.nfc_rounded,
        textColor: textColor,
        iconColor: primaryColor,
        cardBg: glassBg,
        cardBorder: glassBorder,
      ),
      _SlideOnboarding(
        titulo: "Comunidade\nAcadêmica",
        descricao: "Acesse dicas de veteranos, provas antigas e materiais exclusivos da sua disciplina.",
        icone: Icons.hub_rounded,
        textColor: textColor,
        iconColor: primaryColor,
        cardBg: glassBg,
        cardBorder: glassBorder,
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [bgTop, bgBottom], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Stack(
          children: [
            PageView(controller: _controller, physics: const BouncingScrollPhysics(), children: paginas),
            Positioned(
              top: 60, right: 24,
              child: TextButton(
                onPressed: _concluirOnboarding,
                child: Text("Pular", style: GoogleFonts.poppins(color: textColor.withOpacity(0.5), fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
            Positioned(
              bottom: 48, left: 32, right: 32,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DotsIndicator(
                    dotsCount: paginas.length,
                    position: _paginaAtual,
                    decorator: DotsDecorator(
                      color: textColor.withOpacity(0.2),
                      activeColor: primaryColor,
                      size: const Size.square(8.0),
                      activeSize: const Size(24.0, 8.0),
                      activeShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_paginaAtual == paginas.length - 1) { _concluirOnboarding(); } else { _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut); }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, elevation: 8, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Row(children: [Text(_paginaAtual == paginas.length - 1 ? "Começar" : "Próximo", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)), const SizedBox(width: 8), const Icon(Icons.arrow_forward, size: 18)]),
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
// lib/telas/comum/tela_onboarding.dart

import 'dart:ui'; // Necessário para o efeito de desfoque (BackdropFilter)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dots_indicator/dots_indicator.dart'; // Indicador de páginas (bolinhas)
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart'; // Widgetbook

// Importações internas
import '../../providers/provedor_onboarding.dart';
import '../../themes/app_theme.dart';
import '../login/portao_autenticacao.dart';
import '../../l10n/app_localizations.dart'; // Traduções

/// Caso de uso para o Widgetbook.
/// Permite visualizar a tela de Onboarding isoladamente para testes de design.
@UseCase(
  name: 'Tela de Onboarding',
  type: TelaOnboarding,
)
Widget buildTelaOnboarding(BuildContext context) {
  return const ProviderScope(
    child: TelaOnboarding(),
  );
}

/// Widget auxiliar para criar o efeito de "Cartão de Vidro" (Glassmorphism).
/// Usado para destacar o ícone central em cada slide.
class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final Color bgColor;

  const _GlassCard({
    required this.child, 
    required this.borderColor, 
    required this.bgColor
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30.0), // Bordas arredondadas
      child: BackdropFilter(
        // Aplica o desfoque no fundo
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor, // Cor semitransparente
            borderRadius: BorderRadius.circular(30.0),
            border: Border.all(color: borderColor, width: 1.5), // Borda sutil
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Widget que representa um único slide do carrossel.
class _SlideOnboarding extends StatelessWidget {
  final String titulo;
  final String descricao;
  final IconData icone;
  
  // Cores passadas dinamicamente para suportar temas
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
          // Ícone destacado no cartão de vidro
          _GlassCard(
            borderColor: cardBorder,
            bgColor: cardBg,
            child: Padding(
              padding: const EdgeInsets.all(50.0),
              child: Icon(icone, size: 80, color: iconColor),
            ),
          ),
          const SizedBox(height: 60),
          
          // Título do slide
          Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Descrição do slide
          Text(
            descricao,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: textColor.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Tela principal de Onboarding com controle de estado (PageController).
class TelaOnboarding extends ConsumerStatefulWidget {
  const TelaOnboarding({super.key});

  @override
  ConsumerState<TelaOnboarding> createState() => _TelaOnboardingState();
}

class _TelaOnboardingState extends ConsumerState<TelaOnboarding> {
  final PageController _controller = PageController();
  int _paginaAtual = 0; // Índice da página atual para o indicador

  @override
  void initState() {
    super.initState();
    // Ouve a mudança de página para atualizar as bolinhas indicadoras
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
  
  /// Finaliza o onboarding e navega para a tela de autenticação.
  Future<void> _concluirOnboarding() async {
    // 1. Salva no dispositivo que o usuário já viu a introdução
    await ref.read(provedorOnboarding.notifier).completeOnboarding();
    
    if (mounted) {
      // 2. Navega para o Portão (que decidirá se mostra Login ou Home)
      // 'pushAndRemoveUntil' garante que o usuário não possa voltar para cá com o botão "Voltar"
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PortaoAutenticacao()),
        (route) => false, 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Acesso às traduções (embora o onboarding seja geralmente estático, é boa prática)
    // Nota: Como as frases do onboarding são muito específicas, muitas vezes são mantidas aqui,
    // mas se quiser traduzir, adicione chaves no app_localizations.dart.
    // Aqui usaremos textos fixos em português como solicitado, mas preparados para i18n.
    
    // --- TEMA DINÂMICO ---
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Definição de cores baseada no tema atual (Claro/Escuro)
    final Color bgBottom = theme.scaffoldBackgroundColor;
    final Color bgTop = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color primaryColor = AppColors.primaryPurple;
    
    // Cores específicas para o efeito de vidro
    final Color glassBg = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    final Color glassBorder = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);

    // Lista de Slides
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
      // Fundo com gradiente suave
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgTop, bgBottom], 
            begin: Alignment.topCenter, 
            end: Alignment.bottomCenter
          ),
        ),
        child: Stack(
          children: [
            // Carrossel de Páginas
            PageView(
              controller: _controller,
              physics: const BouncingScrollPhysics(), // Efeito elástico (iOS style)
              children: paginas,
            ),
            
            // Botão "Pular" no topo
            Positioned(
              top: 60,
              right: 24,
              child: TextButton(
                onPressed: _concluirOnboarding,
                child: Text(
                  "Pular", 
                  style: GoogleFonts.poppins(
                    color: textColor.withOpacity(0.5), 
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            
            // Controles Inferiores (Indicador + Botão Ação)
            Positioned(
              bottom: 48,
              left: 32,
              right: 32,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicador de bolinhas
                  DotsIndicator(
                    dotsCount: paginas.length,
                    position: _paginaAtual,
                    decorator: DotsDecorator(
                      color: textColor.withOpacity(0.2), // Cor inativa
                      activeColor: primaryColor,       // Cor ativa
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
                        // Se for o último, finaliza
                        _concluirOnboarding();
                      } else {
                        // Se não, vai para o próximo slide
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: primaryColor.withOpacity(0.4),
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
      ),
    );
  }
}
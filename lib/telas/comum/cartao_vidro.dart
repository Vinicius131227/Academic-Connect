import 'dart:ui'; // Necessário para o ImageFilter
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import '../../themes/app_theme.dart';

/// Caso de uso para o Widgetbook: Cartão de Vidro simples.
@UseCase(
  name: 'Cartão Vidro Padrão',
  type: CartaoVidro,
)
Widget buildCartaoVidro(BuildContext context) {
  return Container(
    color: Colors.purple, // Fundo colorido para destacar a transparência
    alignment: Alignment.center,
    child: const SizedBox(
      width: 200,
      height: 200,
      child: CartaoVidro(
        child: Center(child: Text("Efeito Vidro", style: TextStyle(color: Colors.white))),
      ),
    ),
  );
}

/// Widget que aplica o efeito de "Glassmorphism" (Vidro Fosco).
///
/// Utiliza [BackdropFilter] com blur e uma camada de cor semi-transparente.
/// Ideal para sobrepor fundos coloridos ou imagens.
class CartaoVidro extends StatelessWidget {
  /// O conteúdo que ficará dentro do cartão.
  final Widget child;
  
  /// Arredondamento das bordas (Padrão: 24.0).
  final double borderRadius;

  const CartaoVidro({
    super.key, 
    required this.child,
    this.borderRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    // Detecta o tema para ajustar a opacidade do vidro
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Cores ajustadas para garantir legibilidade em ambos os temas
    final colorOpacity = isDark ? 0.1 : 0.2;
    final borderOpacity = isDark ? 0.1 : 0.3;
    final baseColor = isDark ? Colors.white : Colors.grey.shade200;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        // Aplica o desfoque no que está atrás do widget
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            // Cor de fundo semi-transparente
            color: baseColor.withOpacity(colorOpacity),
            borderRadius: BorderRadius.circular(borderRadius),
            // Borda sutil para definir os limites do vidro
            border: Border.all(
              color: Colors.white.withOpacity(borderOpacity), 
              width: 1.5
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
// lib/telas/comum/cartao_vidro.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../themes/app_theme.dart'; // Importa nossas cores

// --- NOVO IMPORTE ---
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
// --- FIM NOVO IMPORTE ---

// --- ANOTAÇÃO @UseCase ---
// Isso diz ao Widgetbook para mostrar este widget
@UseCase(name: 'Default', type: CartaoVidro)
Widget buildCartaoVidro(BuildContext context) {
  // Nós apenas retornamos o widget que queremos testar
  return const Center(
    child: CartaoVidro(
      child: SizedBox(
        width: 250,
        height: 250,
        child: Center(
          child: Text("Conteúdo de Exemplo"),
        ),
      ),
    ),
  );
}
// --- FIM DA ANOTAÇÃO ---

class CartaoVidro extends StatelessWidget {
  final Widget child;
  const CartaoVidro({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Cores baseadas na sua paleta
    final surfaceColor = isDark 
      ? AppColors.darkSurface.withOpacity(0.6) // Roxo escuro
      : AppColors.lightAccent.withOpacity(0.4); // Lilás
      
    final borderColor = isDark
      ? AppColors.darkAccent.withOpacity(0.3) // Roxo claro
      : AppColors.lightSurface.withOpacity(0.5); // Branco

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0), // Mais arredondado
      child: BackdropFilter(
        // O "blur" (desfoque)
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            // Borda sutil para dar o efeito de "vidro"
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: child,
        ),
      ),
    );
  }
}

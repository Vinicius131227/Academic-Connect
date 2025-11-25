// lib/telas/comum/cartao_vidro.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'Padrão', type: CartaoVidro)
Widget buildCartaoVidro(BuildContext context) {
  return const Center(child: CartaoVidro(child: Text('Teste')));
}

class CartaoVidro extends StatelessWidget {
  final Widget child;
  const CartaoVidro({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // CORREÇÃO: Cores fixas do tema Dark/Roxo
    final surfaceColor = AppColors.surface.withOpacity(0.6); 
    final borderColor = Colors.white.withOpacity(0.1);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: child,
        ),
      ),
    );
  }
}
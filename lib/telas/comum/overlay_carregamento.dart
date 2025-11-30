// lib/telas/comum/overlay_carregamento.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import '../../themes/app_theme.dart';

/// Provedor de Estado Global para controlar o carregamento.
/// Se `true`, a tela de bloqueio (overlay) deve ser exibida.
final provedorCarregando = StateProvider<bool>((ref) => false);

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Overlay de Carregamento',
  type: WidgetCarregamento,
)
Widget buildWidgetCarregamento(BuildContext context) {
  return const Scaffold(
    body: Center(
      child: WidgetCarregamento(texto: "Processando dados..."),
    ),
  );
}

/// Widget visual de carregamento (Spinner).
///
/// Exibe um indicador circular roxo e um texto opcional.
/// Adapta a cor do texto para o tema Claro/Escuro.
class WidgetCarregamento extends StatelessWidget {
  final String? texto;

  const WidgetCarregamento({super.key, this.texto});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
            ),
            if (texto != null) ...[
              const SizedBox(height: 16),
              Text(
                texto!,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
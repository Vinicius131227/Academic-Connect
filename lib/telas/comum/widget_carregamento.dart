import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import '../../themes/app_theme.dart';

/// Caso de uso para o Widgetbook: Visualizar o Loading com texto padrão.
@UseCase(
  name: 'Loading Padrão',
  type: WidgetCarregamento,
)
Widget buildLoadingPadrao(BuildContext context) {
  return const Scaffold(
    body: Center(child: WidgetCarregamento()),
  );
}

/// Caso de uso para o Widgetbook: Visualizar o Loading com texto personalizado.
@UseCase(
  name: 'Loading com Mensagem',
  type: WidgetCarregamento,
)
Widget buildLoadingMensagem(BuildContext context) {
  return const Scaffold(
    body: Center(child: WidgetCarregamento(texto: "Processando dados...")),
  );
}

/// Widget de carregamento padronizado para todo o aplicativo.
///
/// Exibe um [CircularProgressIndicator] na cor primária e um texto opcional abaixo.
/// Adapta-se automaticamente ao tema claro/escuro.
class WidgetCarregamento extends StatelessWidget {
  /// Texto opcional para exibir abaixo do spinner (ex: "Aguarde...").
  final String? texto;
  
  const WidgetCarregamento({super.key, this.texto});

  @override
  Widget build(BuildContext context) {
    // Obtém o tema atual para definir cores de contraste
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black54;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador de progresso circular
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
          ),
          
          // Se houver texto, exibe com espaçamento
          if (texto != null && texto!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              texto!,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:ui'; // Para o BackdropFilter
import '../../l10n/app_localizations.dart'; // Importa i18n

class WidgetCarregamento extends StatelessWidget {
  final String texto;
  const WidgetCarregamento({super.key, this.texto = ''}); // Texto padrão vazio

  @override
  Widget build(BuildContext context) {
    // Se nenhum texto for passado, usa a tradução padrão
    final textoCarregando = texto.isEmpty ? (AppLocalizations.of(context)?.t('artigos_carregando') ?? 'Carregando...') : texto;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(textoCarregando, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// Widget de tela inteira (para usar no AuthGate)
class TelaCarregamento extends StatelessWidget {
  const TelaCarregamento({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundo levemente borrado para um loading mais "premium"
      body: Stack(
        children: [
          // Coloque um fundo se quiser (ex: imagem)
          // Container(decoration: BoxDecoration(image: ...)),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.1),
              ),
            ),
          ),
          const WidgetCarregamento(),
        ],
      ),
    );
  }
}
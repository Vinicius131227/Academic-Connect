import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cartao_vidro.dart';
import 'widget_carregamento.dart';

/// Provedor de estado global para controlar a visibilidade do overlay.
/// Para usar: `ref.read(provedorCarregando.notifier).state = true;`
final provedorCarregando = StateProvider<bool>((ref) => false);

/// Um widget que deve ser colocado no topo da árvore (ex: no `builder` do MaterialApp)
/// para mostrar um indicador de "loading" em tela cheia sobre todo o app.
class OverlayCarregamento extends ConsumerWidget {
  final Widget child;
  const OverlayCarregamento({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observa o provedor de carregamento
    final bool estaCarregando = ref.watch(provedorCarregando);

    return Stack(
      children: [
        // 1. O app principal
        child,

        // 2. O overlay de loading (só aparece se estaCarregando == true)
        if (estaCarregando)
          // Fundo escuro semitransparente
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const CartaoVidro( // Efeito de vidro fosco
              child: Padding(
                padding: EdgeInsets.all(24.0),
                // O widget de CircularProgressIndicator
                child: WidgetCarregamento(texto: 'Processando...'),
              ),
            ),
          ),
      ],
    );
  }
}
// lib/telas/comum/animacao_fadein_lista.dart

import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Lista FadeIn (Nativo)',
  type: FadeInListAnimation,
)
Widget buildFadeInList(BuildContext context) {
  return Scaffold(
    body: FadeInListAnimation(
      children: List.generate(5, (index) => Card(
        margin: const EdgeInsets.all(8),
        child: ListTile(
          leading: const Icon(Icons.star),
          title: Text("Item Animado ${index + 1}"),
        ),
      )),
    ),
  );
}

/// Widget utilitário que aplica animação de entrada (Fade + Slide)
/// para uma lista de widgets filhos.
///
/// Esta versão usa apenas AnimationController nativo do Flutter,
/// eliminando a necessidade de pacotes externos.
class FadeInListAnimation extends StatelessWidget {
  /// A lista de widgets que serão animados.
  final List<Widget> children;
  
  /// Duração da animação de cada item.
  final Duration duration;

  const FadeInListAnimation({
    super.key, 
    required this.children,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Configurações para permitir que esta lista funcione dentro de outros Scrolls (SingleChildScrollView)
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(), 
      
      itemCount: children.length,
      itemBuilder: (BuildContext context, int index) {
        return _AnimatedItem(
          index: index,
          duration: duration,
          child: children[index],
        );
      },
    );
  }
}

/// Widget interno que gerencia a animação de um único item.
/// Ele espera um pequeno atraso baseado no índice para criar o efeito "cascata".
class _AnimatedItem extends StatefulWidget {
  final int index;
  final Duration duration;
  final Widget child;

  const _AnimatedItem({
    required this.index,
    required this.duration,
    required this.child,
  });

  @override
  State<_AnimatedItem> createState() => _AnimatedItemState();
}

class _AnimatedItemState extends State<_AnimatedItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _translate;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this, 
      duration: widget.duration
    );
    
    // Animação de Opacidade (0.0 -> 1.0)
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    // Animação de Deslizamento (Vem de baixo para cima)
    _translate = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Inicia a animação com um atraso proporcional ao índice (efeito cascata)
    // Ex: Item 0 (0ms), Item 1 (100ms), Item 2 (200ms)...
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _translate,
        child: widget.child,
      ),
    );
  }
}
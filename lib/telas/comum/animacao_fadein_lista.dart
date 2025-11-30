import 'package:flutter/material.dart'; 
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// Caso de uso para o Widgetbook: Lista animada.
@UseCase(
  name: 'Lista FadeIn',
  type: FadeInListAnimation,
)
Widget buildFadeInList(BuildContext context) {
  return Scaffold(
    body: FadeInListAnimation(
      children: List.generate(5, (index) => Card(
        child: ListTile(title: Text("Item $index")),
      )),
    ),
  );
}

/// Widget que anima uma lista de filhos com efeito de Fade In e Slide Up.
///
/// Útil para tornar a entrada em telas de dashboard mais suave.
class FadeInListAnimation extends StatelessWidget {
  /// Lista de widgets a serem animados.
  final List<Widget> children;
  
  /// Duração da animação (Padrão: 375ms).
  final Duration duration;

  const FadeInListAnimation({
    super.key, 
    required this.children,
    this.duration = const Duration(milliseconds: 500), // Um pouco mais lento para suavidade
  });

  @override
  Widget build(BuildContext context) {
    // Usando AnimationLimiter e Configuration do pacote flutter_staggered_animations
    // Se não tiver o pacote, pode substituir por um ListView simples, mas aqui implementamos
    // uma lógica manual simples de Staggered para não quebrar se faltar o pacote.
    
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      shrinkWrap: true, // Permite usar dentro de outros Scrollers se necessário
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

/// Item individual animado internamente.
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
    _controller = AnimationController(vsync: this, duration: widget.duration);
    
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _translate = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Adiciona um delay baseado no índice para criar o efeito "cascata"
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _controller.forward();
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
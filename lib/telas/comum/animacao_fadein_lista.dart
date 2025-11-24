import 'package:flutter/material.dart';

/// Um widget que aplica um efeito de fade-in e slide-up escalonado
/// para cada item em uma lista de [children].
class FadeInListAnimation extends StatefulWidget {
  final List<Widget> children;
  const FadeInListAnimation({super.key, required this.children});

  @override
  State<FadeInListAnimation> createState() => _FadeInListAnimationState();
}

class _FadeInListAnimationState extends State<FadeInListAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // A duração total é baseada no número de itens
      duration: Duration(milliseconds: 300 + (widget.children.length * 80)),
    );

    // Cria uma animação para cada item
    _animations = widget.children.map((_) {
      final index = widget.children.indexOf(_);
      // Calcula o início e fim do delay para cada item
      final startTime = (index * 80) / _controller.duration!.inMilliseconds;
      final endTime = (startTime + (400 / _controller.duration!.inMilliseconds)).clamp(0.0, 1.0);

      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startTime, endTime, curve: Curves.easeOut),
        ),
      );
    }).toList();

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(widget.children.length, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _animations[index].value, // Aplica o fade
                child: Transform.translate(
                  offset: Offset(0, (1.0 - _animations[index].value) * 15), // Aplica o slide
                  child: child,
                ),
              );
            },
            child: widget.children[index],
          );
        }),
      ),
    );
  }
}
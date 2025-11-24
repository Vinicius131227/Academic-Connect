import 'package:flutter/material.dart';

/// Um widget simples que aplica um efeito de fade-in (aparecimento suave)
/// ao seu [child] após um [delay] especificado.
class FadeInCard extends StatefulWidget {
  final Widget child;
  final Duration delay;
  
  const FadeInCard({super.key, required this.child, required this.delay});

  @override
  State<FadeInCard> createState() => _FadeInCardState();
}

class _FadeInCardState extends State<FadeInCard> {
  bool _isVisible = false;
  
  @override
  void initState() {
    super.initState();
    // Aguarda o 'delay' e então torna o widget visível
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() => _isVisible = true);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: widget.child,
    );
  }
}
// lib/telas/aluno/tela_sugestoes.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/servico_firestore.dart';
import '../../providers/provedor_autenticacao.dart';

class TelaSugestoes extends ConsumerStatefulWidget {
  const TelaSugestoes({super.key});

  @override
  ConsumerState<TelaSugestoes> createState() => _TelaSugestoesState();
}

class _TelaSugestoesState extends ConsumerState<TelaSugestoes> {
  final _controller = TextEditingController();
  bool _enviando = false;

  Future<void> _enviar() async {
    if (_controller.text.isEmpty) return;
    setState(() => _enviando = true);
    
    final uid = ref.read(provedorNotificadorAutenticacao).usuario?.uid ?? 'anonimo';
    
    try {
      await ref.read(servicoFirestoreProvider).enviarSugestao(_controller.text, uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sugestão enviada! Obrigado.'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sugestões")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Encontrou um erro ou tem uma ideia? Conte para nós!", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Digite sua sugestão aqui...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _enviando ? null : _enviar,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              child: _enviando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Enviar Sugestão"),
            )
          ],
        ),
      ),
    );
  }
}
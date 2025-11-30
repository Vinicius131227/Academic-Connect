// lib/telas/aluno/tela_sugestoes.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart'; // Para o Widgetbook

// Importações internas
import '../../services/servico_firestore.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../l10n/app_localizations.dart'; // Traduções

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Tela de Sugestões',
  type: TelaSugestoes,
)
Widget buildTelaSugestoes(BuildContext context) {
  return const ProviderScope(
    child: TelaSugestoes(),
  );
}

/// Tela que permite ao usuário enviar sugestões, bugs ou feedbacks.
/// Os dados são salvos na coleção 'sugestoes' do Firestore.
class TelaSugestoes extends ConsumerStatefulWidget {
  const TelaSugestoes({super.key});

  @override
  ConsumerState<TelaSugestoes> createState() => _TelaSugestoesState();
}

class _TelaSugestoesState extends ConsumerState<TelaSugestoes> {
  final _controller = TextEditingController();
  bool _enviando = false; // Estado de carregamento do botão

  /// Envia a sugestão para o banco de dados.
  Future<void> _enviar() async {
    if (_controller.text.isEmpty) return;
    
    setState(() => _enviando = true);
    
    // Pega o ID do usuário logado ou marca como anônimo
    final uid = ref.read(provedorNotificadorAutenticacao).usuario?.uid ?? 'anonimo';
    
    try {
      await ref.read(servicoFirestoreProvider).enviarSugestao(_controller.text, uid);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sugestão enviada! Obrigado.'), backgroundColor: Colors.green)
        );
        Navigator.pop(context); // Fecha a tela após sucesso
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!; // Para traduções (se houver chaves)
    // Nota: Como o texto desta tela é muito específico e estático, 
    // muitas vezes mantemos hardcoded, mas para produção idealmente usaria t.t('chave').
    // Aqui mantemos os textos originais solicitados.

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sugestões"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Encontrou um erro ou tem uma ideia? Conte para nós!", 
              style: TextStyle(fontSize: 16)
            ),
            const SizedBox(height: 16),
            
            // Campo de Texto Multilinha
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Digite sua sugestão aqui...",
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            
            // Botão de Enviar
            ElevatedButton(
              onPressed: _enviando ? null : _enviar,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                // Cor do botão definida pelo tema global
              ),
              child: _enviando 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    ) 
                  : const Text("Enviar Sugestão"),
            )
          ],
        ),
      ),
    );
  }
}
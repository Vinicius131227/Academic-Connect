// lib/telas/aluno/tela_dicas_gerais.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/servico_firestore.dart';
import '../comum/widget_carregamento.dart';
import '../../themes/app_theme.dart';
import '../../models/dica_aluno.dart';
import 'package:intl/intl.dart';

final dicasGeraisProvider = StreamProvider<List<DicaAluno>>((ref) {
  return ref.watch(servicoFirestoreProvider).getTodasDicasGlobais();
});

class TelaDicasGerais extends ConsumerWidget {
  const TelaDicasGerais({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDicas = ref.watch(dicasGeraisProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Dicas da Comunidade")),
      body: asyncDicas.when(
        loading: () => const WidgetCarregamento(),
        error: (e, s) => Center(child: Text("Erro: $e")),
        data: (dicas) {
          if (dicas.isEmpty) return const Center(child: Text("Nenhuma dica encontrada.", style: TextStyle(color: Colors.white)));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dicas.length,
            itemBuilder: (context, index) {
              final dica = dicas[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.yellow, size: 20),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd/MM/yyyy').format(dica.dataPostagem), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(dica.texto, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
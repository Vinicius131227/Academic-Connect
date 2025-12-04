// lib/telas/aluno/tela_dicas_gerais.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // Importante

import '../../models/dica_aluno.dart';
import '../../services/servico_firestore.dart';
import '../../themes/app_theme.dart';
import '../comum/widget_carregamento.dart';

final dicasGeraisProvider = StreamProvider<List<DicaAluno>>((ref) {
  return ref.watch(servicoFirestoreProvider).getTodasDicasGlobais();
});

class TelaDicasGerais extends ConsumerWidget {
  const TelaDicasGerais({super.key});

  Future<void> _abrirLinkIndice(String erro) async {
    final regex = RegExp(r'(https://console\.firebase\.google\.com[^\s]+)');
    final match = regex.firstMatch(erro);
    if (match != null) {
      final url = Uri.parse(match.group(0)!);
      if (await canLaunchUrl(url)) await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDicas = ref.watch(dicasGeraisProvider);
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = AppColors.surfaceDark; // Simplificado

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Dicas da Comunidade", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: asyncDicas.when(
        loading: () => const WidgetCarregamento(texto: "Buscando dicas..."),
        error: (error, stack) {
          final erroString = error.toString();
          final ehErroIndice = erroString.contains("failed-precondition") || erroString.contains("index");

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.build_circle, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text("Configuração Pendente", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  if (ehErroIndice) ...[
                      const Text("O índice 'dicas' precisa ser criado no Firebase.", textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _abrirLinkIndice(erroString),
                        child: const Text("CRIAR ÍNDICE AGORA"),
                      ),
                  ] else 
                      Text(erroString),
                ],
              ),
            ),
          );
        },
        data: (dicas) {
          if (dicas.isEmpty) return const Center(child: Text("Nenhuma dica."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dicas.length,
            itemBuilder: (context, index) {
              final dica = dicas[index];
              return Card(
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                   leading: const Icon(Icons.lightbulb, color: Colors.amber),
                   title: Text(dica.texto, style: const TextStyle(color: Colors.white)),
                   subtitle: Text(DateFormat('dd/MM/yyyy').format(dica.dataPostagem), style: const TextStyle(color: Colors.grey)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
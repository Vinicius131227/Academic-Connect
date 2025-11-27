import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/dica_aluno.dart';
import '../../services/servico_firestore.dart';
import '../../themes/app_theme.dart';
import '../comum/widget_carregamento.dart';

final dicasGeraisProvider = StreamProvider<List<DicaAluno>>((ref) {
  return ref.watch(servicoFirestoreProvider).getTodasDicasGlobais();
});

class TelaDicasGerais extends ConsumerWidget {
  const TelaDicasGerais({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDicas = ref.watch(dicasGeraisProvider);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Dicas da Comunidade", 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: asyncDicas.when(
        loading: () => const WidgetCarregamento(texto: "Buscando dicas..."),
        error: (error, stack) {
          debugPrint("ERRO NO FIREBASE (DICAS): $error");
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.build_circle, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text("Configuração Necessária", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Verifique o terminal para o link de criação de índice.", textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
        data: (dicas) {
          if (dicas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb_outline, size: 80, color: subTextColor?.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text("Nenhuma dica encontrada.", style: GoogleFonts.poppins(fontSize: 16, color: subTextColor)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dicas.length,
            itemBuilder: (context, index) {
              final dica = dicas[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.cardYellow.withOpacity(0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.lightbulb, color: AppColors.cardYellow, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('dd MMM yyyy').format(dica.dataPostagem), style: GoogleFonts.poppins(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w500)),
                                const Icon(Icons.format_quote_rounded, size: 16, color: AppColors.primaryPurple),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(dica.texto, style: GoogleFonts.poppins(color: textColor, fontSize: 14, height: 1.5)),
                          ],
                        ),
                      ),
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
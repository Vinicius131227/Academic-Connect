// lib/telas/aluno/tela_dicas_gerais.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/dica_aluno.dart';
import '../../services/servico_firestore.dart';
import '../../themes/app_theme.dart';
import '../comum/widget_carregamento.dart';
import '../../l10n/app_localizations.dart'; // Traduções

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Dicas da Comunidade',
  type: TelaDicasGerais,
)
Widget buildTelaDicasGerais(BuildContext context) {
  return const ProviderScope(
    child: TelaDicasGerais(),
  );
}

/// Provedor que busca TODAS as dicas do banco (Collection Group Query).
/// Isso permite listar dicas de várias disciplinas em um só lugar.
final dicasGeraisProvider = StreamProvider<List<DicaAluno>>((ref) {
  return ref.watch(servicoFirestoreProvider).getTodasDicasGlobais();
});

/// Tela que exibe as dicas compartilhadas pela comunidade acadêmica.
///
/// Funcionalidades:
/// - Lista dicas de todas as disciplinas.
/// - Exibe erro amigável se o índice do Firebase não existir.
/// - Adapta-se ao tema Claro/Escuro.
class TelaDicasGerais extends ConsumerWidget {
  const TelaDicasGerais({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final asyncDicas = ref.watch(dicasGeraisProvider);
    
    // Configurações de Tema
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t.t('card_dicas'), // "Dicas Gerais" ou "Dicas da Comunidade"
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: asyncDicas.when(
        loading: () => const WidgetCarregamento(texto: "Buscando dicas..."),
        
        // Tratamento de Erros
        error: (error, stack) {
          debugPrint("ERRO NO FIREBASE (DICAS): $error");
          
          // Verifica se é erro de índice (comum em collectionGroup queries)
          if (error.toString().contains("failed-precondition")) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.build_circle_outlined, size: 64, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      "Configuração Pendente",
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "O índice do banco de dados está sendo criado. Verifique o console para o link.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: subTextColor),
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(child: Text("${t.t('erro_generico')}: $error"));
        },
        
        // Exibição dos Dados
        data: (dicas) {
          if (dicas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb_outline, size: 80, color: subTextColor?.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    t.t('dicas_vazio'), // "Nenhuma dica encontrada."
                    style: GoogleFonts.poppins(fontSize: 16, color: subTextColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Seja o primeiro a postar na sua disciplina!",
                    style: GoogleFonts.poppins(fontSize: 12, color: subTextColor?.withOpacity(0.7)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dicas.length,
            itemBuilder: (context, index) {
              final dica = dicas[index];
              return _CardDica(
                dica: dica,
                cardColor: cardColor,
                textColor: textColor!,
                subTextColor: subTextColor!,
              );
            },
          );
        },
      ),
    );
  }
}

/// Widget interno para renderizar o cartão de uma dica.
class _CardDica extends StatelessWidget {
  final DicaAluno dica;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;

  const _CardDica({
    required this.dica,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        // Sombra suave
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone de Lâmpada (Amarelo)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cardYellow.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lightbulb, color: AppColors.cardYellow, size: 24),
            ),
            const SizedBox(width: 16),
            
            // Conteúdo da Dica
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Data e Ícone de Citação
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(dica.dataPostagem),
                        style: GoogleFonts.poppins(
                          color: subTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(Icons.format_quote_rounded, size: 16, color: AppColors.primaryPurple),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Texto da Dica
                  Text(
                    dica.texto,
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Rodapé (Contador de Votos - Apenas visual neste MVP)
                  Row(
                    children: [
                      Icon(Icons.thumb_up_alt_outlined, size: 14, color: subTextColor),
                      const SizedBox(width: 4),
                      Text(
                        "${dica.upvotes}",
                        style: GoogleFonts.poppins(
                          color: subTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
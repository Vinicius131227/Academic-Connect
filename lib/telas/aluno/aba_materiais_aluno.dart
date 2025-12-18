// lib/telas/aluno/aba_materiais_aluno.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../../models/material_aula.dart';
import '../../l10n/app_localizations.dart';
import '../../services/servico_firestore.dart';
import '../comum/widget_carregamento.dart';
import '../comum/tela_webview.dart'; 
import '../../themes/app_theme.dart';

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Materiais da Disciplina',
  type: AbaMateriaisAluno,
)
Widget buildAbaMateriaisAluno(BuildContext context) {
  return const ProviderScope(
    child: Scaffold(
      body: AbaMateriaisAluno(
        turmaId: 'mock_id', 
        nomeDisciplina: 'Cálculo 1'
      ),
    ),
  );
}

/// Aba que lista os materiais de estudo para uma disciplina específica.
/// Exibe:
/// 1. Materiais postados pelo professor nesta turma.
/// 2. Banco de provas antigas (busca global por nome da disciplina).
class AbaMateriaisAluno extends ConsumerWidget {
  final String turmaId;
  final String nomeDisciplina;
  
  const AbaMateriaisAluno({
    super.key, 
    required this.turmaId, 
    required this.nomeDisciplina
  });

  /// Normaliza o nome da disciplina para buscar materiais antigos.
  /// Ex: "Cálculo 1 - Turma A" -> "Cálculo 1"
  String _getNomeBase(String nome) {
    final nomeBase = nome.replaceAll(RegExp(r'\s*\d+$'), '');
    return nomeBase.trim();
  }

  /// Retorna o ícone adequado para cada tipo de material.
  IconData _getIconForType(TipoMaterial tipo) {
    switch (tipo) {
      case TipoMaterial.link: return Icons.link;
      case TipoMaterial.video: return Icons.play_circle_fill;
      case TipoMaterial.prova: return Icons.assignment;
      case TipoMaterial.outro: return Icons.attach_file;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final nomeBase = _getNomeBase(nomeDisciplina);
    
    // Streams de dados
    final streamMateriais = ref.watch(streamMateriaisProvider(turmaId));
    final streamMateriaisAntigos = ref.watch(streamMateriaisAntigosProvider(nomeBase));

    // Configuração de Tema
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.black12;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // 1. TÍTULO MATERIAIS RECENTES
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                t.t('materiais_titulo'), // "Materiais Postados"
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)
              ),
            ),
          ),
          
          // 2. LISTA DE MATERIAIS DA TURMA
          streamMateriais.when(
            loading: () => const SliverToBoxAdapter(child: WidgetCarregamento()),
            error: (e, s) => SliverToBoxAdapter(child: Center(child: Text("${t.t('erro_generico')}", style: TextStyle(color: textColor)))),
            data: (materiais) {
              if (materiais.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor, 
                      borderRadius: BorderRadius.circular(12), 
                      border: Border.all(color: borderColor)
                    ),
                    child: Center(
                      child: Text(
                        t.t('materiais_vazio_aluno'), 
                        style: TextStyle(color: textColor.withOpacity(0.6))
                      )
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildMaterialCard(context, materiais[index], AppColors.cardBlue, cardColor, textColor, borderColor),
                  childCount: materiais.length,
                ),
              );
            },
          ),

          // 3. TÍTULO PROVAS ANTIGAS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
              child: Text(
                t.t('materiais_antigos'), // "Banco de Provas Antigas"
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)
              ),
            ),
          ),

          // 4. LISTA DE PROVAS ANTIGAS (Busca Global)
          streamMateriaisAntigos.when(
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()), // Ignora erro se índice não existir ainda
            data: (materiais) {
               final provas = materiais.where((m) => m.tipo == TipoMaterial.prova).toList();
               if (provas.isEmpty) {
                 return SliverToBoxAdapter(
                   child: Padding(
                     padding: const EdgeInsets.all(16), 
                     child: Text(t.t('materiais_vazio'), style: TextStyle(color: textColor.withOpacity(0.6)))
                   ),
                 );
               }
               return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildMaterialCard(context, provas[index], AppColors.cardOrange, cardColor, textColor, borderColor),
                    childCount: provas.length,
                  ),
               );
            },
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  /// Widget auxiliar para construir o cartão de material.
  Widget _buildMaterialCard(BuildContext context, MaterialAula material, Color iconColor, Color bgColor, Color textColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getIconForType(material.tipo), color: iconColor),
        ),
        title: Text(
          material.titulo, 
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
        ),
        subtitle: Text(
          DateFormat('dd/MM/yyyy').format(material.dataPostagem),
          style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: textColor.withOpacity(0.3), size: 16),
        onTap: () {
            // Abre o link/arquivo na WebView interna
            Navigator.push(context, MaterialPageRoute(builder: (_) => TelaWebView(url: material.url, titulo: material.titulo)));
        },
      ),
    );
  }
}
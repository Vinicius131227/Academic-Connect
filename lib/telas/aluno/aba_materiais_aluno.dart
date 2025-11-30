// lib/telas/aluno/aba_materiais_aluno.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/material_aula.dart';
import '../../models/video_recomendado.dart';
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

/// Provedor que busca vídeos no YouTube relacionados à matéria.
/// Usa a API pública "Invidious" para evitar necessidade de chave de API do Google.
final videosRecomendadosProvider = FutureProvider.family<List<VideoRecomendado>, String>((ref, nomeMateria) async {
  // Pega apenas a primeira palavra para busca (Ex: "Cálculo" de "Cálculo 1")
  final termoBusca = nomeMateria.split(' ')[0]; 
  try {
    final url = Uri.parse('https://inv.tux.pizza/api/v1/search?q=aula+$termoBusca&type=video&sort=relevance');
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // Retorna os top 5 vídeos
      return data.take(5).map((json) => VideoRecomendado.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    return []; // Retorna vazio em caso de erro de rede
  }
});

/// Aba que lista os materiais de estudo para uma disciplina específica.
class AbaMateriaisAluno extends ConsumerWidget {
  final String turmaId;
  final String nomeDisciplina;
  
  const AbaMateriaisAluno({
    super.key, 
    required this.turmaId, 
    required this.nomeDisciplina
  });

  /// Normaliza o nome da disciplina para buscar materiais antigos.
  /// Remove números de turma, etc.
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
    final asyncVideos = ref.watch(videosRecomendadosProvider(nomeBase));

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
          
          // 5. TÍTULO VÍDEOS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
              child: Row(children: [
                const Icon(Icons.play_circle_fill, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  t.t('materiais_videos'), // "Vídeo Aulas"
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)
                ),
              ]),
            ),
          ),
          
          // 6. LISTA DE VÍDEOS (Horizontal)
          asyncVideos.when(
            data: (videos) {
               if (videos.isEmpty) return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Text(t.t('materiais_vazio'), style: TextStyle(color: textColor.withOpacity(0.6)))));
               
               return SliverToBoxAdapter(
                 child: SizedBox(
                   height: 220,
                   child: ListView.builder(
                     scrollDirection: Axis.horizontal,
                     padding: const EdgeInsets.symmetric(horizontal: 16),
                     itemCount: videos.length,
                     itemBuilder: (context, index) {
                       final video = videos[index];
                       return Container(
                         width: 220,
                         margin: const EdgeInsets.only(right: 16),
                         child: Card(
                           clipBehavior: Clip.antiAlias,
                           color: cardColor,
                           elevation: 2,
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: borderColor)),
                           child: InkWell(
                             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaWebView(url: video.videoUrl, titulo: video.titulo))),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Expanded(
                                   child: Image.network(
                                     video.thumbnailUrl, 
                                     fit: BoxFit.cover, 
                                     width: double.infinity,
                                     errorBuilder: (c,e,s) => Container(color: Colors.black, child: const Center(child: Icon(Icons.play_arrow, color: Colors.white))),
                                   ),
                                 ),
                                 Padding(
                                   padding: const EdgeInsets.all(12),
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Text(video.titulo, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                       const SizedBox(height: 4),
                                       Text(video.canal, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 10)),
                                     ],
                                   ),
                                 )
                               ],
                             ),
                           ),
                         ),
                       );
                     },
                   ),
                 ),
               );
            },
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
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
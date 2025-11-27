import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/material_aula.dart';
import '../../models/video_recomendado.dart';
import '../../l10n/app_localizations.dart';
import '../../services/servico_firestore.dart';
import '../comum/widget_carregamento.dart';
import '../comum/tela_webview.dart'; 
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import '../../themes/app_theme.dart';

final videosRecomendadosProvider = FutureProvider.family<List<VideoRecomendado>, String>((ref, nomeMateria) async {
  final termoBusca = nomeMateria.split(' ')[0]; 
  try {
    final url = Uri.parse('https://inv.tux.pizza/api/v1/search?q=aula+$termoBusca&type=video&sort=relevance');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.take(5).map((json) => VideoRecomendado.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    return [];
  }
});

class AbaMateriaisAluno extends ConsumerWidget {
  final String turmaId;
  final String nomeDisciplina;
  const AbaMateriaisAluno({super.key, required this.turmaId, required this.nomeDisciplina});

  String _getNomeBase(String nome) {
    final nomeBase = nome.replaceAll(RegExp(r'\s*\d+$'), '');
    return nomeBase.trim();
  }

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
    
    final streamMateriais = ref.watch(streamMateriaisProvider(turmaId));
    final streamMateriaisAntigos = ref.watch(streamMateriaisAntigosProvider(nomeBase));
    final asyncVideos = ref.watch(videosRecomendadosProvider(nomeBase));

    // --- TEMA DINÂMICO ---
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.black12;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Materiais Postados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            ),
          ),
          
          streamMateriais.when(
            loading: () => const SliverToBoxAdapter(child: WidgetCarregamento()),
            error: (e, s) => SliverToBoxAdapter(child: Center(child: Text("Erro ao carregar", style: TextStyle(color: textColor)))),
            data: (materiais) {
              if (materiais.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                    child: Center(child: Text(t.t('materiais_vazio_aluno'), style: TextStyle(color: textColor.withOpacity(0.6)))),
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
              child: Text('Banco de Provas Antigas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            ),
          ),

          streamMateriaisAntigos.when(
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (materiais) {
               final provas = materiais.where((m) => m.tipo == TipoMaterial.prova).toList();
               if (provas.isEmpty) {
                 return SliverToBoxAdapter(
                   child: Padding(padding: const EdgeInsets.all(16), child: Text("Nenhuma prova antiga encontrada.", style: TextStyle(color: textColor.withOpacity(0.6)))),
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
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
              child: Row(children: [
                const Icon(Icons.play_circle_fill, color: Colors.red),
                const SizedBox(width: 8),
                Text('Vídeo Aulas (YouTube)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
              ]),
            ),
          ),
          
          asyncVideos.when(
            data: (videos) {
               if (videos.isEmpty) return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Text("Sem vídeos.", style: TextStyle(color: textColor.withOpacity(0.6)))));
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
        title: Text(material.titulo, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        subtitle: Text(
          DateFormat('dd/MM/yyyy').format(material.dataPostagem),
          style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: textColor.withOpacity(0.3), size: 16),
        onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => TelaWebView(url: material.url, titulo: material.titulo)));
        },
      ),
    );
  }
}
// lib/telas/aluno/aba_materiais_aluno.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/material_aula.dart';
import '../../models/video_recomendado.dart';
import '../../l10n/app_localizations.dart';
import '../../services/servico_firestore.dart';
import '../comum/widget_carregamento.dart';
import '../comum/tela_webview.dart'; 
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import '../../themes/app_theme.dart'; // CORES NOVAS

final videosRecomendadosProvider = FutureProvider.family<List<VideoRecomendado>, String>((ref, nomeMateria) async {
  final termoBusca = nomeMateria.split(' ')[0]; 
  try {
    // Usando Invidious para não precisar de API Key
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Título
          SliverToBoxAdapter(
             child: Padding(
               padding: const EdgeInsets.all(24.0),
               child: Text("Materiais da Aula", style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
             ),
          ),

          // Lista de Materiais (Stream)
          streamMateriais.when(
            loading: () => const SliverToBoxAdapter(child: WidgetCarregamento()),
            error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (materiais) {
              if (materiais.isEmpty) {
                 return SliverToBoxAdapter(
                   child: Container(
                     margin: const EdgeInsets.symmetric(horizontal: 24),
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                     child: const Center(child: Text("Professor ainda não postou materiais.", style: TextStyle(color: Colors.white54))),
                   ),
                 );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildMaterialCard(context, materiais[index], AppColors.cardBlue),
                    childCount: materiais.length,
                  ),
                ),
              );
            },
          ),

          // Seção Provas Antigas
          SliverToBoxAdapter(
             child: Padding(
               padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
               child: Text("Banco de Provas Antigas", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
             ),
          ),

          streamMateriaisAntigos.when(
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (materiais) {
               final provas = materiais.where((m) => m.tipo == TipoMaterial.prova).toList();
               if (provas.isEmpty) {
                 return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text("Nenhuma prova antiga encontrada.", style: TextStyle(color: Colors.white54))));
               }
               return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildMaterialCard(context, provas[index], AppColors.cardOrange),
                      childCount: provas.length,
                    ),
                  ),
               );
            },
          ),

          // Seção Vídeos (YouTube)
          SliverToBoxAdapter(
             child: Padding(
               padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
               child: Row(
                 children: [
                   const Icon(Icons.play_circle_fill, color: Colors.red),
                   const SizedBox(width: 8),
                   Text("Vídeo Aulas Recomendadas", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                 ],
               ),
             ),
          ),

          asyncVideos.when(
            data: (videos) {
               if (videos.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text("Sem vídeos no momento.", style: TextStyle(color: Colors.white54))));
               
               return SliverToBoxAdapter(
                 child: SizedBox(
                   height: 200,
                   child: ListView.builder(
                     scrollDirection: Axis.horizontal,
                     padding: const EdgeInsets.symmetric(horizontal: 24),
                     itemCount: videos.length,
                     itemBuilder: (context, index) {
                       final video = videos[index];
                       return Container(
                         width: 260,
                         margin: const EdgeInsets.only(right: 16),
                         child: Card(
                           clipBehavior: Clip.antiAlias,
                           color: AppColors.surface,
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
                                       Text(video.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                       Text(video.canal, style: const TextStyle(color: Colors.white54, fontSize: 12)),
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

  Widget _buildMaterialCard(BuildContext context, MaterialAula material, Color iconBgColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBgColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getIconForType(material.tipo), color: iconBgColor),
        ),
        title: Text(material.titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
          DateFormat('dd/MM/yyyy').format(material.dataPostagem),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
        onTap: () {
           Navigator.push(context, MaterialPageRoute(builder: (_) => TelaWebView(url: material.url, titulo: material.titulo)));
        },
      ),
    );
  }
}
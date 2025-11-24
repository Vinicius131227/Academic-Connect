// lib/telas/aluno/aba_materiais_aluno.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/material_aula.dart';
import '../../models/video_recomendado.dart'; // NOVO IMPORT
import '../../l10n/app_localizations.dart';
import '../../services/servico_firestore.dart';
import '../comum/widget_carregamento.dart';
import '../comum/tela_webview.dart'; 
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';

// --- PROVEDOR DA API DE VÍDEOS (INVIDIOUS) ---
final videosRecomendadosProvider = FutureProvider.family<List<VideoRecomendado>, String>((ref, nomeMateria) async {
  // Limpa o nome para busca (Ex: "Cálculo 1" -> "Calculo")
  final termoBusca = nomeMateria.split(' ')[0]; 
  
  try {
    // Usamos uma instância pública do Invidious (API do YouTube sem chave)
    // Se esta instância cair, pode-se trocar por outra (ex: inv.tux.pizza, yewtu.be)
    final url = Uri.parse('https://inv.tux.pizza/api/v1/search?q=aula+$termoBusca&type=video&sort=relevance');
    
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // Pega os 5 primeiros resultados
      return data.take(5).map((json) => VideoRecomendado.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    // Retorna lista vazia em caso de erro de conexão
    return [];
  }
});
// ------------------------------------

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
      case TipoMaterial.video: return Icons.videocam_outlined;
      case TipoMaterial.prova: return Icons.description_outlined;
      case TipoMaterial.outro: return Icons.attachment;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final nomeBase = _getNomeBase(nomeDisciplina);
    
    final streamMateriais = ref.watch(streamMateriaisProvider(turmaId));
    final streamMateriaisAntigos = ref.watch(streamMateriaisAntigosProvider(nomeBase));
    
    // Chama a API de Vídeos
    final asyncVideos = ref.watch(videosRecomendadosProvider(nomeBase));

    return CustomScrollView(
      slivers: [
        // --- SEÇÃO 1: MATERIAIS DA TURMA ---
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Materiais Postados', style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        
        streamMateriais.when(
          loading: () => const SliverToBoxAdapter(child: WidgetCarregamento()),
          error: (err, st) => SliverToBoxAdapter(child: Center(child: Text('Erro: $err'))),
          data: (materiais) {
            if (materiais.isEmpty) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(t.t('materiais_vazio_aluno'), textAlign: TextAlign.center),
                  ),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildMaterialCard(context, materiais[index], _getIconForType(materiais[index].tipo)),
                childCount: materiais.length,
              ),
            );
          },
        ),

        // --- SEÇÃO 2: PROVAS ANTERIORES ---
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
            child: Text('Banco de Provas Antigas', style: Theme.of(context).textTheme.titleLarge),
          ),
        ),

        streamMateriaisAntigos.when(
          loading: () => const SliverToBoxAdapter(child: WidgetCarregamento()),
          error: (err, st) => SliverToBoxAdapter(child: Center(child: Text('Erro: $err'))),
          data: (materiaisAntigos) {
            final materiaisFiltrados = materiaisAntigos.where((m) => m.tipo == TipoMaterial.prova).toList();

            if (materiaisFiltrados.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Nenhuma prova encontrada para "$nomeBase".', style: TextStyle(color: Colors.grey[600])),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildMaterialCard(context, materiaisFiltrados[index], Icons.history_edu, isAntigo: true),
                childCount: materiaisFiltrados.length,
              ),
            );
          },
        ),
        
        // --- SEÇÃO 3: VÍDEOS RECOMENDADOS (API) ---
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.play_circle_filled, color: Colors.red),
                const SizedBox(width: 8),
                Text('Vídeo Aulas Recomendadas (YouTube)', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ),
        
        asyncVideos.when(
          data: (videos) {
             if (videos.isEmpty) {
               return const SliverToBoxAdapter(
                 child: Padding(padding: EdgeInsets.all(16), child: Text("Sem recomendações de vídeo no momento.")),
               );
             }
             return SliverToBoxAdapter(
               child: SizedBox(
                 height: 240, // Altura do carrossel
                 child: ListView.builder(
                   scrollDirection: Axis.horizontal,
                   padding: const EdgeInsets.symmetric(horizontal: 12),
                   itemCount: videos.length,
                   itemBuilder: (context, index) {
                     final video = videos[index];
                     return Container(
                       width: 200, // Card mais largo para vídeo
                       margin: const EdgeInsets.symmetric(horizontal: 6),
                       child: Card(
                         clipBehavior: Clip.antiAlias,
                         elevation: 3,
                         child: InkWell(
                           onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (_) => TelaWebView(url: video.videoUrl, titulo: video.titulo)));
                           },
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               // Thumbnail
                               Expanded(
                                 flex: 3,
                                 child: Stack(
                                   fit: StackFit.expand,
                                   children: [
                                     video.thumbnailUrl.isNotEmpty
                                         ? Image.network(video.thumbnailUrl, fit: BoxFit.cover)
                                         : Container(color: Colors.black, child: const Icon(Icons.play_arrow, color: Colors.white)),
                                     
                                     if (video.duracao.isNotEmpty)
                                       Positioned(
                                         bottom: 8,
                                         right: 8,
                                         child: Container(
                                           padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                           color: Colors.black.withOpacity(0.8),
                                           child: Text(video.duracao, style: const TextStyle(color: Colors.white, fontSize: 10)),
                                         ),
                                       ),
                                   ],
                                 ),
                               ),
                               // Informações
                               Expanded(
                                 flex: 2,
                                 child: Padding(
                                   padding: const EdgeInsets.all(8.0),
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Text(video.titulo, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                       const Spacer(),
                                       Row(
                                         children: [
                                           const Icon(Icons.person, size: 12, color: Colors.grey),
                                           const SizedBox(width: 4),
                                           Expanded(child: Text(video.canal, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey))),
                                         ],
                                       )
                                     ],
                                   ),
                                 ),
                               ),
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
        
        // Espaço extra no final
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildMaterialCard(BuildContext context, MaterialAula material, IconData icon, {bool isAntigo = false}) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAntigo ? Colors.blueGrey.withOpacity(0.1) : theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(icon, color: isAntigo ? Colors.blueGrey : theme.colorScheme.primary),
        ),
        title: Text(material.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${isAntigo ? 'Arquivado em: ' : ''}${DateFormat('dd/MM/yy').format(material.dataPostagem)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => TelaWebView(url: material.url, titulo: material.titulo)));
        },
      ),
    );
  }
}
// lib/models/video_recomendado.dart

/// Modelo para dados vindos da API do Invidious (YouTube).
class VideoRecomendado {
  final String titulo;
  final String canal;
  final String thumbnailUrl;
  final String videoUrl;

  VideoRecomendado({
    required this.titulo,
    required this.canal,
    required this.thumbnailUrl,
    required this.videoUrl,
  });

  factory VideoRecomendado.fromJson(Map<String, dynamic> json) {
    String videoId = json['videoId'] ?? '';
    
    // Pega a thumbnail média se existir
    String thumb = '';
    if (json['videoThumbnails'] != null && (json['videoThumbnails'] as List).isNotEmpty) {
       var list = json['videoThumbnails'] as List;
       thumb = list.length > 1 ? list[1]['url'] : list[0]['url'];
    }

    return VideoRecomendado(
      titulo: json['title'] ?? 'Sem título',
      canal: json['author'] ?? 'Canal',
      thumbnailUrl: thumb,
      videoUrl: 'https://www.youtube.com/watch?v=$videoId',
    );
  }
}
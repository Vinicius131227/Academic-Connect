// lib/models/video_recomendado.dart
class VideoRecomendado {
  final String titulo;
  final String canal;
  final String thumbnailUrl;
  final String videoUrl;
  final String duracao;

  VideoRecomendado({
    required this.titulo,
    required this.canal,
    required this.thumbnailUrl,
    required this.videoUrl,
    this.duracao = '',
  });

  factory VideoRecomendado.fromJson(Map<String, dynamic> json) {
    // Pega o ID do vídeo
    final String videoId = json['videoId'] ?? '';
    
    // Tenta pegar a thumbnail de melhor qualidade
    String thumb = '';
    if (json['videoThumbnails'] != null && (json['videoThumbnails'] as List).isNotEmpty) {
      // Pega a segunda opção (geralmente medium quality) ou a primeira
      var list = json['videoThumbnails'] as List;
      var index = list.length > 1 ? 1 : 0;
      thumb = list[index]['url'];
    }

    // Formata a duração (vem em segundos do Invidious)
    String duracaoFormatada = '';
    if (json['lengthSeconds'] != null) {
      final int seconds = json['lengthSeconds'];
      final int min = seconds ~/ 60;
      final int sec = seconds % 60;
      duracaoFormatada = '$min:${sec.toString().padLeft(2, '0')}';
    }

    return VideoRecomendado(
      titulo: json['title'] ?? 'Vídeo sem título',
      canal: json['author'] ?? 'Canal desconhecido',
      thumbnailUrl: thumb,
      videoUrl: 'https://www.youtube.com/watch?v=$videoId',
      duracao: duracaoFormatada,
    );
  }
}
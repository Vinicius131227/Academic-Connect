import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa um evento criado pelo C.A.
/// Armazenado na coleção 'eventos'.
class EventoCA {
  final String id;
  final String nome;
  final DateTime data;
  final String local;
  final int totalParticipantes; // Estimativa
  final String organizadorId; // UID do usuário do C.A.
  final List<String> participantesInscritos; // Lista de UIDs de quem se inscreveu/participou

  EventoCA({
    required this.id,
    required this.nome,
    required this.data,
    required this.local,
    required this.totalParticipantes,
    required this.organizadorId,
    required this.participantesInscritos,
  });

  /// Construtor de fábrica para criar a partir de um [Map] (lido do Firestore)
  factory EventoCA.fromMap(Map<String, dynamic> data, String documentId) {
    return EventoCA(
      id: documentId,
      nome: data['nome'] ?? '',
      data: (data['data'] as Timestamp).toDate(),
      local: data['local'] ?? '',
      totalParticipantes: data['totalParticipantes'] ?? 0,
      organizadorId: data['organizadorId'] ?? '',
      participantesInscritos: List<String>.from(data['participantesInscritos'] ?? []),
    );
  }

  /// Converte este objeto para um [Map] (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'data': Timestamp.fromDate(data),
      'local': local,
      'totalParticipantes': totalParticipantes,
      'organizadorId': organizadorId,
      'participantesInscritos': participantesInscritos,
    };
  }
}
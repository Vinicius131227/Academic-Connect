import 'package:cloud_firestore/cloud_firestore.dart';

class EventoCA {
  final String id;
  final String nome;
  final DateTime data;
  final String local;
  final int totalParticipantes; // Estimativa ou capacidade
  final String organizadorId;
  final List<String> participantesInscritos; // LISTA REAL DE UIDs

  EventoCA({
    required this.id,
    required this.nome,
    required this.data,
    required this.local,
    required this.totalParticipantes,
    this.organizadorId = '',
    this.participantesInscritos = const [], // Padrão vazio
  });

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

  factory EventoCA.fromMap(Map<String, dynamic> map, String id) {
    return EventoCA(
      id: id,
      nome: map['nome'] ?? '',
      data: (map['data'] as Timestamp).toDate(),
      local: map['local'] ?? '',
      totalParticipantes: map['totalParticipantes'] ?? 0,
      organizadorId: map['organizadorId'] ?? '',
      participantesInscritos: List<String>.from(map['participantesInscritos'] ?? []),
    );
  }
}
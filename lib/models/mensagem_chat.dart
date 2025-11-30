// lib/models/mensagem_chat.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MensagemChat {
  final String id;
  final String texto;
  final String usuarioId;
  final String usuarioNome;
  final DateTime dataHora;

  MensagemChat({
    required this.id,
    required this.texto,
    required this.usuarioId,
    required this.usuarioNome,
    required this.dataHora,
  });

  Map<String, dynamic> toMap() {
    return {
      'texto': texto,
      'usuarioId': usuarioId,
      'usuarioNome': usuarioNome,
      'dataHora': Timestamp.fromDate(dataHora),
    };
  }

  factory MensagemChat.fromMap(Map<String, dynamic> map, String id) {
    return MensagemChat(
      id: id,
      texto: map['texto'] ?? '',
      usuarioId: map['usuarioId'] ?? '',
      usuarioNome: map['usuarioNome'] ?? 'Anônimo',
      dataHora: (map['dataHora'] as Timestamp).toDate(),
    );
  }
}
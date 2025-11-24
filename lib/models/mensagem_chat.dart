// lib/models/mensagem_chat.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MensagemChat {
  final String id;
  final String texto;
  final String usuarioId;
  final String usuarioNome; // Denormalizado para evitar buscas
  final DateTime dataHora;

  MensagemChat({
    required this.id,
    required this.texto,
    required this.usuarioId,
    required this.usuarioNome,
    required this.dataHora,
  });

  factory MensagemChat.fromMap(Map<String, dynamic> data, String documentId) {
    return MensagemChat(
      id: documentId,
      texto: data['texto'] ?? '',
      usuarioId: data['usuarioId'] ?? '',
      usuarioNome: data['usuarioNome'] ?? '',
      dataHora: (data['dataHora'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'texto': texto,
      'usuarioId': usuarioId,
      'usuarioNome': usuarioNome,
      'dataHora': Timestamp.fromDate(dataHora),
    };
  }
}
// lib/models/usuario.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'aluno_info.dart';

class UsuarioApp {
  final String uid;
  final String email;
  final String papel;
  final AlunoInfo? alunoInfo;
  final String? nfcCardId;
  final String? tipoIdentificacao;

  UsuarioApp({
    required this.uid,
    required this.email,
    required this.papel,
    this.alunoInfo,
    this.nfcCardId,
    this.tipoIdentificacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'papel': papel,
      'alunoInfo': alunoInfo?.toMap(),
      'nfcCardId': nfcCardId,
      'tipoIdentificacao': tipoIdentificacao,
    };
  }

  factory UsuarioApp.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UsuarioApp(
      uid: doc.id,
      email: data['email'] ?? '',
      papel: data['papel'] ?? '',
      alunoInfo: data['alunoInfo'] != null 
          ? AlunoInfo.fromMap(data['alunoInfo']) 
          : null,
      nfcCardId: data['nfcCardId'],
      tipoIdentificacao: data['tipoIdentificacao'],
    );
  }

  UsuarioApp copyWith({AlunoInfo? alunoInfo, String? nfcCardId}) {
    return UsuarioApp(
      uid: uid,
      email: email,
      papel: papel,
      alunoInfo: alunoInfo ?? this.alunoInfo,
      nfcCardId: nfcCardId ?? this.nfcCardId, // Usa o novo se passar, senão mantém
      tipoIdentificacao: tipoIdentificacao,
    );
  }
}
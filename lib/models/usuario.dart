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
  final Map<String, dynamic>? professorInfo;

  UsuarioApp({
    required this.uid,
    required this.email,
    required this.papel,
    this.alunoInfo,
    this.nfcCardId,
    this.tipoIdentificacao,
    this.professorInfo, // Adicionado ao construtor
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'papel': papel,
      'alunoInfo': alunoInfo?.toMap(),
      'nfcCardId': nfcCardId,
      'tipoIdentificacao': tipoIdentificacao,
      'professorInfo': professorInfo, // Salva no banco
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
      
      // Carrega o mapa do professor se existir
      professorInfo: data['professorInfo'] != null 
          ? Map<String, dynamic>.from(data['professorInfo']) 
          : null,
    );
  }

  UsuarioApp copyWith({
    AlunoInfo? alunoInfo, 
    String? nfcCardId,
    Map<String, dynamic>? professorInfo, // Adicionado ao copyWith
  }) {
    return UsuarioApp(
      uid: uid,
      email: email,
      papel: papel,
      alunoInfo: alunoInfo ?? this.alunoInfo,
      nfcCardId: nfcCardId ?? this.nfcCardId,
      tipoIdentificacao: tipoIdentificacao,
      professorInfo: professorInfo ?? this.professorInfo,
    );
  }
}
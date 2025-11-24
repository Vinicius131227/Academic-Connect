// lib/models/usuario.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'aluno_info.dart';

/// Representa um usuário no sistema, seja ele aluno, professor ou C.A.
class UsuarioApp {
  final String uid; 
  final String email;
  final String papel; 
  final AlunoInfo? alunoInfo;
  final String? nfcCardId;
  final String? tipoIdentificacao; // (NOVO) Ex: "Matrícula SIAPE"

  UsuarioApp({
    required this.uid,
    required this.email,
    required this.papel,
    this.alunoInfo,
    this.nfcCardId,
    this.tipoIdentificacao,
  });

  factory UsuarioApp.fromFirebaseUser(User user, String papel) {
    return UsuarioApp(
      uid: user.uid,
      email: user.email ?? 'email.desconhecido@erro.com',
      papel: papel,
      alunoInfo: null, 
      nfcCardId: null,
      tipoIdentificacao: null,
    );
  }

  factory UsuarioApp.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    return UsuarioApp(
      uid: doc.id,
      email: data['email'] ?? '',
      papel: data['papel'] ?? '',
      nfcCardId: data['nfcCardId'],
      tipoIdentificacao: data['tipoIdentificacao'],
      alunoInfo: data['alunoInfo'] != null
          ? AlunoInfo.fromMap(data['alunoInfo'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'papel': papel,
      'nfcCardId': nfcCardId,
      'alunoInfo': alunoInfo?.toMap(), 
      'tipoIdentificacao': tipoIdentificacao,
    };
  }

  UsuarioApp copyWith({
    String? uid,
    String? email,
    String? papel,
    AlunoInfo? alunoInfo,
    String? nfcCardId,
    String? tipoIdentificacao,
  }) {
    return UsuarioApp(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      papel: papel ?? this.papel,
      alunoInfo: alunoInfo ?? this.alunoInfo,
      nfcCardId: nfcCardId ?? this.nfcCardId,
      tipoIdentificacao: tipoIdentificacao ?? this.tipoIdentificacao,
    );
  }
}
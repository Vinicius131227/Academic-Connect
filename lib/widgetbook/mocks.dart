// lib/widgetbook/mocks.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';

// Importe seus modelos e providers reais
import '../models/usuario.dart';
import '../models/aluno_info.dart';
import '../models/turma_professor.dart';
import '../models/prova_agendada.dart';
import '../models/solicitacao_aluno.dart';
import '../models/aluno_chamada.dart'; // Importante para o mock de chamada
import '../services/servico_firestore.dart';
import '../providers/provedor_autenticacao.dart';

// =============================================================================
// 1. DADOS FALSOS (MOCKS) PARA TESTE
// =============================================================================

// Um usuário aluno falso logado
final mockUsuarioAluno = UsuarioApp(
  uid: 'uid_aluno_test',
  email: 'aluno@teste.com',
  papel: 'aluno',
  alunoInfo: AlunoInfo(
    nomeCompleto: 'João da Silva',
    ra: '123456',
    curso: 'Engenharia',
    cr: 8.5,
    status: 'Ativo', // <--- CORREÇÃO: Campo 'status' adicionado
  ),
);

// Uma turma falsa
final mockTurma = TurmaProfessor(
  id: 'turma_mock_1',
  nome: 'Cálculo Numérico',
  horario: 'Seg 08:00 - 10:00',
  local: 'Sala 305',
  professorId: 'prof_123',
  turmaCode: 'CALC24',
  creditos: 4,
  alunosInscritos: ['uid_aluno_test'],
);

// Uma prova falsa
final mockProva = ProvaAgendada(
  id: 'prova_1',
  turmaId: 'turma_mock_1',
  disciplina: 'Cálculo Numérico',
  titulo: 'P1',
  dataHora: DateTime.now().add(const Duration(days: 2)), 
  conteudo: 'Derivadas e Integrais',
  predio: 'Bloco C',
  sala: '305',
);

// =============================================================================
// 2. SERVIÇOS FALSOS (Para enganar o Riverpod)
// =============================================================================

/// Um Notificador de Autenticação que já começa com um usuário logado
class MockNotificadorAutenticacao extends NotificadorAutenticacao {
  
  // Hack para satisfazer o construtor pai
  MockNotificadorAutenticacao() : super(null as dynamic) {
    state = EstadoAutenticacao(
      status: StatusAutenticacao.autenticado,
      usuario: mockUsuarioAluno,
    );
  }

  @override Future<void> verificarUsuarioAtual() async {}
  @override Future<void> login(String e, String p) async {}
  
  @override Future<void> logout() async { 
    state = EstadoAutenticacao(status: StatusAutenticacao.desconhecido); 
  }
}

/// Um ServicoFirestore que retorna Streams com dados falsos instantaneamente
class MockServicoFirestore implements ServicoFirestore {
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  // --- Mocks para Aluno ---
  @override
  Stream<List<TurmaProfessor>> getTurmasAluno(String alunoUid) {
    return Stream.value([mockTurma]);
  }

  @override
  Stream<List<ProvaAgendada>> getCalendarioDeProvas() {
    return Stream.value([mockProva]);
  }
  
  @override
  Stream<List<ProvaAgendada>> getTodasProvas() {
    return Stream.value([mockProva]);
  }

  @override
  Stream<List<SolicitacaoAluno>> getSolicitacoesAluno(String alunoUid) {
    return Stream.value([]); 
  }

  @override
  Stream<List<SolicitacaoAluno>> getTodasSolicitacoesStream() {
    return Stream.value([]);
  }

  // --- Mocks para Professor ---
  @override
  Stream<List<TurmaProfessor>> getTurmasProfessor(String professorUid) {
     return Stream.value([mockTurma]);
  }
  
  @override
  Stream<List<SolicitacaoAluno>> getSolicitacoesProfessor(String professorUid) {
    return Stream.value([]);
  }

  // --- Mocks para Chamada e Presença ---
  @override
  Future<List<AlunoChamada>> getAlunosDaTurma(String turmaId) async {
    return [
      AlunoChamada(id: 'aluno1', nome: 'João Silva', ra: '12345'),
      AlunoChamada(id: 'aluno2', nome: 'Maria Souza', ra: '67890'),
    ];
  }

  @override
  Future<Map<String, dynamic>> getDadosChamada(String turmaId, String dataId) async {
    return {
      'presentes_inicio': ['aluno1'], 
      'presentes_fim': [],            
    };
  }
  
  @override
  Future<void> atualizarChamadaHistorico(
    String turmaId, 
    String dataId, 
    List<String> presentesInicio, 
    List<String> presentesFim
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
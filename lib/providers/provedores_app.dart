// lib/providers/provedores_app.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/servico_firestore.dart';
import 'provedor_autenticacao.dart';

// --- Importe seus Models ---
import '../models/turma_professor.dart';
import '../models/solicitacao_aluno.dart';
import '../models/disciplina_notas.dart';
import '../models/prova_agendada.dart';
import '../models/evento_ca.dart';

// -------------------------------------------------------------------
// 👨‍🏫 PROVEDORES DO PROFESSOR
// -------------------------------------------------------------------

/// Stream que escuta as turmas do professor logado.
final provedorStreamTurmasProfessor = StreamProvider<List<TurmaProfessor>>((ref) {
  final authState = ref.watch(provedorNotificadorAutenticacao);
  final servico = ref.watch(servicoFirestoreProvider);
  
  final uid = authState.usuario?.uid;
  if (uid == null) {
    return Stream.value([]);
  }
  return servico.getTurmasProfessor(uid);
});

/// Stream que escuta as solicitações do professor logado.
final provedorStreamSolicitacoesProfessor = StreamProvider<List<SolicitacaoAluno>>((ref) {
  final authState = ref.watch(provedorNotificadorAutenticacao);
  final servico = ref.watch(servicoFirestoreProvider);
  
  final uid = authState.usuario?.uid;
  if (uid == null) {
    return Stream.value([]);
  }
  return servico.getSolicitacoes(uid);
});

/// Filtra as solicitações para mostrar apenas as pendentes.
final provedorSolicitacoesPendentes = Provider<List<SolicitacaoAluno>>((ref) {
  final asyncSolicitacoes = ref.watch(provedorStreamSolicitacoesProfessor);
  return asyncSolicitacoes.valueOrNull
            ?.where((s) => s.status == StatusSolicitacao.pendente)
            .toList() ?? [];
});

// -------------------------------------------------------------------
// 🎓 PROVEDORES DO ALUNO (CORRIGIDOS)
// -------------------------------------------------------------------

/// Stream que escuta as turmas onde o aluno está inscrito.
final provedorStreamTurmasAluno = StreamProvider<List<TurmaProfessor>>((ref) {
  final authState = ref.watch(provedorNotificadorAutenticacao);
  final servico = ref.watch(servicoFirestoreProvider);
  
  final uid = authState.usuario?.uid;
  if (uid == null) {
    return Stream.value([]);
  }
  return servico.getTurmasAluno(uid); // CORRIGIDO
});

/// Stream que escuta as notas do aluno logado.
final provedorStreamNotasAluno = StreamProvider<List<DisciplinaNotas>>((ref) {
  final authState = ref.watch(provedorNotificadorAutenticacao);
  final servico = ref.watch(servicoFirestoreProvider);
  
  final uid = authState.usuario?.uid;
  if (uid == null) {
    return Stream.value([]);
  }
  return servico.getNotasAluno(uid); // CORRIGIDO
});

/// Stream que escuta as solicitações feitas pelo aluno logado.
final provedorStreamSolicitacoesAluno = StreamProvider<List<SolicitacaoAluno>>((ref) {
  final authState = ref.watch(provedorNotificadorAutenticacao);
  final servico = ref.watch(servicoFirestoreProvider);
  
  final uid = authState.usuario?.uid;
  if (uid == null) {
    return Stream.value([]);
  }
  return servico.getSolicitacoesAluno(uid); // CORRIGIDO
});

// -------------------------------------------------------------------
// 🗓️ PROVEDORES GERAIS (Calendário e Eventos) (CORRIGIDOS)
// -------------------------------------------------------------------

/// Stream que escuta todas as provas agendadas.
final provedorStreamCalendario = StreamProvider<List<ProvaAgendada>>((ref) {
  final servico = ref.watch(servicoFirestoreProvider);
  return servico.getCalendarioDeProvas(); // CORRIGIDO
});

/// Stream que escuta todos os eventos do C.A.
final provedorStreamEventosCA = StreamProvider<List<EventoCA>>((ref) {
  final servico = ref.watch(servicoFirestoreProvider);
  return servico.getEventos(); // CORRIGIDO
});
// lib/providers/provedores_app.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/servico_firestore.dart';
import 'provedor_autenticacao.dart';

// --- Importação dos Modelos de Dados ---
import '../models/turma_professor.dart';
import '../models/solicitacao_aluno.dart';
import '../models/disciplina_notas.dart';
import '../models/prova_agendada.dart';
import '../models/evento_ca.dart';

// ===========================================================================
// 👨‍🏫 SEÇÃO 1: PROVEDORES DO PROFESSOR
// ===========================================================================

/// Escuta em tempo real as **Turmas** criadas pelo professor logado.
///
/// Utiliza o UID do usuário autenticado para filtrar apenas as turmas que
/// pertencem a ele.
/// Retorna: `List<TurmaProfessor>`
final provedorStreamTurmasProfessor = StreamProvider<List<TurmaProfessor>>((ref) {
  // 1. Observa o estado da autenticação
  final authState = ref.watch(provedorNotificadorAutenticacao);
  final servico = ref.watch(servicoFirestoreProvider);
  
  final uid = authState.usuario?.uid;

  // 2. Segurança: Se não houver usuário logado, retorna lista vazia
  if (uid == null) {
    return Stream.value([]);
  }

  // 3. Busca os dados no Firestore
  return servico.getTurmasProfessor(uid);
});

/// Escuta em tempo real as **Solicitações** (ex: abono, adaptação) enviadas
/// pelos alunos para este professor.
///
/// Retorna: `List<SolicitacaoAluno>`
final provedorStreamSolicitacoesProfessor = StreamProvider<List<SolicitacaoAluno>>((ref) {
  final authState = ref.watch(provedorNotificadorAutenticacao);
  final servico = ref.watch(servicoFirestoreProvider);
  
  final uid = authState.usuario?.uid;

  if (uid == null) {
    return Stream.value([]);
  }

  return servico.getSolicitacoes(uid);
});

/// Provedor derivado que filtra a lista de solicitações acima,
/// retornando apenas aquelas que estão com status **"Pendente"**.
///
/// Útil para mostrar contadores de notificação ou badges.
final provedorSolicitacoesPendentes = Provider<List<SolicitacaoAluno>>((ref) {
  final asyncSolicitacoes = ref.watch(provedorStreamSolicitacoesProfessor);
  
  return asyncSolicitacoes.valueOrNull
          ?.where((s) => s.status == StatusSolicitacao.pendente)
          .toList() ?? [];
});


// ===========================================================================
// 🎓 SEÇÃO 2: PROVEDORES DO ALUNO
// ===========================================================================

/// Escuta em tempo real as **Turmas** nas quais o aluno está inscrito.
///
/// Diferente do professor (que vê as turmas que criou), aqui vemos
/// as turmas onde o ID do aluno está na lista de inscritos.
final provedorStreamTurmasAluno = StreamProvider<List<TurmaProfessor>>((ref) {
  final authState = ref.watch(provedorNotificadorAutenticacao);
  final servico = ref.watch(servicoFirestoreProvider);
  
  final uid = authState.usuario?.uid;

  if (uid == null) {
    return Stream.value([]);
  }

  return servico.getTurmasAluno(uid);
});

/// Escuta em tempo real as **Notas e Frequências** do aluno logado.
///
/// Retorna: `List<DisciplinaNotas>` contendo o desempenho em cada matéria.
final provedorStreamNotasAluno = StreamProvider<List<DisciplinaNotas>>((ref) {
  final authState = ref.watch(provedorNotificadorAutenticacao);
  final servico = ref.watch(servicoFirestoreProvider);
  
  final uid = authState.usuario?.uid;

  if (uid == null) {
    return Stream.value([]);
  }

  return servico.getNotasAluno(uid);
});

/// Escuta o histórico de **Solicitações** feitas pelo próprio aluno.
///
/// Permite que o aluno acompanhe se o pedido foi aprovado ou recusado.
final provedorStreamSolicitacoesAluno = StreamProvider<List<SolicitacaoAluno>>((ref) {
  final authState = ref.watch(provedorNotificadorAutenticacao);
  final servico = ref.watch(servicoFirestoreProvider);
  
  final uid = authState.usuario?.uid;

  if (uid == null) {
    return Stream.value([]);
  }

  return servico.getSolicitacoesAluno(uid);
});


// ===========================================================================
// 🗓️ SEÇÃO 3: PROVEDORES GERAIS (Compartilhados)
// ===========================================================================

/// Escuta o **Calendário Global** de provas e entregas.
///
/// Usado para popular a tela de Calendário e os widgets de "Próximas Avaliações".
final provedorStreamCalendario = StreamProvider<List<ProvaAgendada>>((ref) {
  final servico = ref.watch(servicoFirestoreProvider);
  return servico.getCalendarioDeProvas();
});

/// Escuta os **Eventos do C.A.** (Centro Acadêmico).
///
/// Usado para mostrar palestras, festas e avisos na timeline.
final provedorStreamEventosCA = StreamProvider<List<EventoCA>>((ref) {
  final servico = ref.watch(servicoFirestoreProvider);
  return servico.getEventos();
});
// lib/providers/provedores_app.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/servico_firestore.dart';
import 'provedor_autenticacao.dart';

// --- Importação dos Modelos de Dados ---
import '../models/turma_professor.dart';
import '../models/solicitacao_aluno.dart';
import '../models/disciplina_notas.dart';
import '../models/prova_agendada.dart';

// ===========================================================================
// 👨‍🏫 SEÇÃO 1: PROVEDORES DO PROFESSOR
// ===========================================================================

/// Escuta em tempo real as **Turmas** criadas pelo professor logado.
final provedorStreamTurmasProfessor = StreamProvider.autoDispose<List<TurmaProfessor>>((ref) {
  final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;
  if (usuario == null) return const Stream.empty();
  return ref.watch(servicoFirestoreProvider).getTurmasProfessor(usuario.uid);
});

/// Escuta em tempo real as **Solicitações** enviadas para este professor.
final provedorStreamSolicitacoesProfessor = StreamProvider.autoDispose<List<SolicitacaoAluno>>((ref) {
  final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;
  if (usuario == null) return const Stream.empty();
  // Atualizado para chamar o método específico do professor
  return ref.watch(servicoFirestoreProvider).getSolicitacoesProfessor(usuario.uid);
});

/// Filtra apenas solicitações **Pendentes** (Útil para badges de notificação).
final provedorSolicitacoesPendentes = Provider.autoDispose<List<SolicitacaoAluno>>((ref) {
  final asyncSolicitacoes = ref.watch(provedorStreamSolicitacoesProfessor);
  
  return asyncSolicitacoes.valueOrNull
          ?.where((s) => s.status == StatusSolicitacao.pendente)
          .toList() ?? [];
});

// ===========================================================================
// 🎓 SEÇÃO 2: PROVEDORES DO ALUNO
// ===========================================================================

/// Escuta em tempo real as **Turmas** nas quais o aluno está inscrito.
final provedorStreamTurmasAluno = StreamProvider.autoDispose<List<TurmaProfessor>>((ref) {
  final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;
  if (usuario == null) return const Stream.empty();
  return ref.watch(servicoFirestoreProvider).getTurmasAluno(usuario.uid);
});

/// Escuta em tempo real as **Notas e Frequências** do aluno logado.
final provedorStreamNotasAluno = StreamProvider.autoDispose<List<DisciplinaNotas>>((ref) {
  final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;
  if (usuario == null) return const Stream.empty();
  return ref.watch(servicoFirestoreProvider).getNotasAluno(usuario.uid);
});

/// Escuta o histórico de **Solicitações** feitas pelo próprio aluno (Específico).
final provedorStreamSolicitacoesAluno = StreamProvider.autoDispose<List<SolicitacaoAluno>>((ref) {
  final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;
  if (usuario == null) return const Stream.empty();
  return ref.watch(servicoFirestoreProvider).getSolicitacoesAluno(usuario.uid);
});

// ===========================================================================
// 🗓️ SEÇÃO 3: PROVEDORES GERAIS (Compartilhados)
// ===========================================================================

/// Escuta o **Calendário Global** de provas.
final provedorStreamCalendario = StreamProvider.autoDispose<List<ProvaAgendada>>((ref) {
  // Atualizado para o nome correto no serviço
  return ref.watch(servicoFirestoreProvider).getTodasProvas();
});

/// Escuta TODAS as solicitações (usado para filtros client-side se necessário).
/// Adicionado para corrigir o erro na tela "Minhas Solicitações".
final provedorStreamSolicitacoesGeral = StreamProvider.autoDispose<List<SolicitacaoAluno>>((ref) {
  return ref.watch(servicoFirestoreProvider).getTodasSolicitacoesStream();
});
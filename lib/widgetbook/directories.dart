// lib/widgetbook/directories.dart

import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Imports Reais ---
import '../providers/provedor_autenticacao.dart';
import '../services/servico_firestore.dart';

// --- Imports dos Mocks ---
import 'mocks.dart'; // <--- Importante!

// --- Imports das Telas ---
import '../telas/login/portao_autenticacao.dart';
import '../telas/login/tela_login.dart';
import '../telas/aluno/aba_inicio_aluno.dart';
import '../telas/aluno/aba_disciplinas_aluno.dart';
import '../telas/professor/aba_inicio_professor.dart';
import '../telas/professor/tela_detalhes_disciplina_prof.dart';

/// Esta função define quais provedores serão substituídos pelos falsos.
/// Usaremos ela em todas as telas que precisam de dados.
List<Override> get globalOverrides => [
  // Substitui o serviço real pelo mock que não usa Firebase
  servicoFirestoreProvider.overrideWith((ref) => MockServicoFirestore()),
  // Substitui o notificador de auth por um que já vem logado
  provedorNotificadorAutenticacao.overrideWith((ref) => MockNotificadorAutenticacao()),
];


List<WidgetbookNode> get directories => [
  
  WidgetbookCategory(
    name: 'Fluxos Principais',
    children: [
      WidgetbookUseCase(
        name: 'Portão (Auth Check)',
        // Se já estiver logado no mock, deve ir para Home
        builder: (context) => ProviderScope(
          overrides: globalOverrides,
          child: const PortaoAutenticacao()
        ),
      ),
      WidgetbookUseCase(
        name: 'Tela de Login',
        // Aqui não precisamos do usuário logado, então sem overrides de auth
        builder: (context) => const ProviderScope(child: TelaLogin()),
      ),
    ],
  ),

  WidgetbookCategory(
    name: 'Área do Aluno',
    children: [
      WidgetbookUseCase(
        name: 'Home Aluno',
        // Precisa dos overrides para carregar turmas e provas falsas
        builder: (context) => ProviderScope(
          overrides: globalOverrides,
          child: const AbaInicioAluno()
        ),
      ),
      WidgetbookUseCase(
        name: 'Minhas Disciplinas',
        builder: (context) => ProviderScope(
          overrides: globalOverrides,
          child: const AbaDisciplinasAluno()
        ),
      ),
    ],
  ),

  WidgetbookCategory(
    name: 'Área do Professor',
    children: [
      WidgetbookUseCase(
        name: 'Home Professor',
        builder: (context) => ProviderScope(
          overrides: globalOverrides,
          child: AbaInicioProfessor(onNavigateToTab: (_){})
        ),
      ),
      WidgetbookUseCase(
        name: 'Detalhes Disciplina (Mock)',
        // Passamos a turma mockada importada de mocks.dart
        builder: (context) => ProviderScope(
          overrides: globalOverrides,
          child: TelaDetalhesDisciplinaProf(turma: mockTurma)
        ),
      ),
    ],
  ),
];
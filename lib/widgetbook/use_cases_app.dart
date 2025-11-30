// lib/widgetbook/use_cases_app.dart

import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Telas Aluno ---
import '../telas/aluno/aba_inicio_aluno.dart';
import '../telas/aluno/aba_disciplinas_aluno.dart';
import '../telas/aluno/aba_perfil_aluno.dart';
import '../telas/aluno/tela_detalhes_disciplina_aluno.dart';
import '../telas/aluno/tela_notas_avaliacoes.dart';
import '../telas/aluno/tela_solicitar_adaptacao.dart';
import '../telas/aluno/tela_drive_provas.dart';
import '../telas/aluno/tela_dicas_gerais.dart';
import '../telas/aluno/tela_calendario.dart';
import '../telas/aluno/tela_cadastro_nfc.dart';

// --- Telas Professor ---
import '../telas/professor/aba_inicio_professor.dart';
import '../telas/professor/aba_turmas_professor.dart';
import '../telas/professor/aba_perfil_professor.dart';
import '../telas/professor/tela_detalhes_disciplina_prof.dart';
import '../telas/professor/tela_criar_turma.dart';
import '../telas/professor/tela_calendario_professor.dart';

// --- Telas C.A. ---
import '../telas/ca_projeto/aba_inicio_ca.dart';
import '../telas/ca_projeto/aba_eventos_ca.dart';
import '../telas/ca_projeto/aba_perfil_ca.dart';
import '../telas/ca_projeto/tela_criar_evento.dart';

// --- Comum ---
import '../telas/comum/tela_configuracoes.dart';
import '../models/turma_professor.dart';

/// Lista de componentes da Aplicação Principal para o Widgetbook.
List<WidgetbookComponent> get appUseCases => [
  
  // ===========================================================================
  // ALUNO
  // ===========================================================================
  WidgetbookComponent(
    name: 'Aluno - Principal',
    useCases: [
      WidgetbookUseCase(
        name: 'Dashboard (Home)',
        builder: (context) => const ProviderScope(child: AbaInicioAluno()),
      ),
      WidgetbookUseCase(
        name: 'Lista de Disciplinas',
        builder: (context) => const ProviderScope(child: AbaDisciplinasAluno()),
      ),
      WidgetbookUseCase(
        name: 'Perfil Completo',
        builder: (context) => const ProviderScope(child: AbaPerfilAluno()),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Aluno - Ferramentas',
    useCases: [
      WidgetbookUseCase(
        name: 'Hub da Disciplina (Mock)',
        builder: (context) => ProviderScope(
          child: TelaDetalhesDisciplinaAluno(
            turma: TurmaProfessor(
              id: 'mock', 
              nome: 'Cálculo 1', 
              horario: 'Seg 08:00', 
              local: 'Sala 10', 
              professorId: 'prof', 
              turmaCode: '123', 
              creditos: 4, 
              alunosInscritos: []
            )
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Drive de Provas',
        builder: (context) => const ProviderScope(child: TelaDriveProvas()),
      ),
      WidgetbookUseCase(
        name: 'Mural de Dicas',
        builder: (context) => const ProviderScope(child: TelaDicasGerais()),
      ),
      WidgetbookUseCase(
        name: 'Solicitar Adaptação',
        builder: (context) => const ProviderScope(child: TelaSolicitarAdaptacao()),
      ),
      WidgetbookUseCase(
        name: 'Calendário Acadêmico',
        builder: (context) => const ProviderScope(child: TelaCalendario()),
      ),
      WidgetbookUseCase(
        name: 'Cadastro NFC',
        builder: (context) => const ProviderScope(child: TelaCadastroNFC()),
      ),
    ],
  ),

  // ===========================================================================
  // PROFESSOR
  // ===========================================================================
  WidgetbookComponent(
    name: 'Professor - Principal',
    useCases: [
      WidgetbookUseCase(
        name: 'Dashboard (Home)',
        builder: (context) => ProviderScope(child: AbaInicioProfessor(onNavigateToTab: (i){})),
      ),
      WidgetbookUseCase(
        name: 'Minhas Turmas',
        builder: (context) => const ProviderScope(child: AbaTurmasProfessor()),
      ),
      WidgetbookUseCase(
        name: 'Perfil',
        builder: (context) => const ProviderScope(child: AbaPerfilProfessor()),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Professor - Gestão',
    useCases: [
      WidgetbookUseCase(
        name: 'Hub da Disciplina (Mock)',
        builder: (context) => ProviderScope(
          child: TelaDetalhesDisciplinaProf(
             turma: TurmaProfessor(
              id: 'mock', 
              nome: 'Física 1', 
              horario: 'Ter 10:00', 
              local: 'Lab 2', 
              professorId: 'prof', 
              turmaCode: 'ABC', 
              creditos: 4, 
              alunosInscritos: []
            )
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Criar Nova Turma',
        builder: (context) => const ProviderScope(child: TelaCriarTurma()),
      ),
      WidgetbookUseCase(
        name: 'Agenda do Professor',
        builder: (context) => const ProviderScope(child: TelaCalendarioProfessor()),
      ),
    ],
  ),

  // ===========================================================================
  // CENTRO ACADÊMICO
  // ===========================================================================
  WidgetbookComponent(
    name: 'C.A. - Principal',
    useCases: [
      WidgetbookUseCase(
        name: 'Dashboard (Home)',
        builder: (context) => const ProviderScope(child: AbaInicioCA()),
      ),
      WidgetbookUseCase(
        name: 'Lista de Eventos',
        builder: (context) => const ProviderScope(child: AbaEventosCA()),
      ),
      WidgetbookUseCase(
        name: 'Perfil Gestão',
        builder: (context) => const ProviderScope(child: AbaPerfilCA()),
      ),
      WidgetbookUseCase(
        name: 'Criar Evento',
        builder: (context) => const ProviderScope(child: TelaCriarEvento()),
      ),
    ],
  ),

  // ===========================================================================
  // COMUM
  // ===========================================================================
  WidgetbookComponent(
    name: 'Configurações',
    useCases: [
      WidgetbookUseCase(
        name: 'Tela de Ajustes',
        builder: (context) => const ProviderScope(child: TelaConfiguracoes()),
      ),
    ],
  ),
];
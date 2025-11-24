// lib/telas/aluno/tela_detalhes_disciplina_aluno.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/turma_professor.dart';
import '../../l10n/app_localizations.dart';
import '../comum/aba_chat_disciplina.dart';
import 'aba_materiais_aluno.dart';
import 'aba_dicas_aluno.dart';

class TelaDetalhesDisciplinaAluno extends ConsumerWidget {
  final TurmaProfessor turma;
  const TelaDetalhesDisciplinaAluno({super.key, required this.turma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(turma.nome, style: const TextStyle(fontSize: 18)),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: t.t('hub_chat')),
              Tab(text: t.t('hub_materiais')),
              Tab(text: t.t('hub_dicas')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Aba 1: Chat
            AbaChatDisciplina(turmaId: turma.id),
            // Aba 2: Materiais (Visão do Aluno)
            AbaMateriaisAluno(turmaId: turma.id, nomeDisciplina: turma.nome),
            // Aba 3: Dicas (MODIFICADO)
            AbaDicasAluno(turmaId: turma.id, nomeDisciplina: turma.nome),
          ],
        ),
      ),
    );
  }
}
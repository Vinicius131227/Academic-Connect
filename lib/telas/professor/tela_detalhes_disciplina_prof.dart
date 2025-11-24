// lib/telas/professor/tela_detalhes_disciplina_prof.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/turma_professor.dart';
import '../../l10n/app_localizations.dart';
import '../comum/aba_chat_disciplina.dart';
import 'aba_materiais_professor.dart';

class TelaDetalhesDisciplinaProf extends ConsumerWidget {
  final TurmaProfessor turma;
  const TelaDetalhesDisciplinaProf({super.key, required this.turma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(turma.nome, style: const TextStyle(fontSize: 18)),
          bottom: TabBar(
            tabs: [
              Tab(text: t.t('hub_chat')),
              Tab(text: t.t('hub_materiais')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Aba 1: Chat
            AbaChatDisciplina(turmaId: turma.id),
            // Aba 2: Materiais (Visão do Professor - pode adicionar)
            AbaMateriaisProfessor(turma: turma),
          ],
        ),
      ),
    );
  }
}
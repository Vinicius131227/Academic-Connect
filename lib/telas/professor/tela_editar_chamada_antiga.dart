// lib/telas/professor/tela_editar_chamada_antiga.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/turma_professor.dart';
import '../../services/servico_firestore.dart';
import '../../models/aluno_chamada.dart';
import '../../l10n/app_localizations.dart';

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Editar Chamada Antiga',
  type: TelaEditarChamadaAntiga,
)
Widget buildTelaEditarChamadaAntiga(BuildContext context) {
  return ProviderScope(
    child: TelaEditarChamadaAntiga(
      turma: TurmaProfessor(
        id: 'mock', nome: 'Turma Teste', horario: '', local: '', professorId: '', turmaCode: '', creditos: 4, alunosInscritos: []
      ),
      dataId: '2025-10-25'
    ),
  );
}

/// Tela que permite editar o registro de presença de uma data passada.
///
/// Útil para corrigir erros de chamada ou abonar faltas manualmente.
/// Exibe dois "chips" (botões de seleção) por aluno: Início e Fim.
class TelaEditarChamadaAntiga extends ConsumerStatefulWidget {
  final TurmaProfessor turma;
  final String dataId; // Formato yyyy-MM-dd
  
  const TelaEditarChamadaAntiga({
    super.key, 
    required this.turma, 
    required this.dataId
  });

  @override
  ConsumerState<TelaEditarChamadaAntiga> createState() => _TelaEditarChamadaAntigaState();
}

class _TelaEditarChamadaAntigaState extends ConsumerState<TelaEditarChamadaAntiga> {
  List<AlunoChamada> _alunos = [];
  bool _loading = true;
  
  // Listas temporárias para armazenar as alterações antes de salvar
  List<String> _presentesInicio = [];
  List<String> _presentesFim = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  /// Busca os alunos da turma e o registro de presença da data específica.
  Future<void> _carregarDados() async {
    final servico = ref.read(servicoFirestoreProvider);
    
    // 1. Busca todos os alunos inscritos na turma
    final alunosBase = await servico.getAlunosDaTurma(widget.turma.id);
    
    // 2. Busca o documento da aula naquela data
    final dadosChamada = await servico.getDadosChamada(widget.turma.id, widget.dataId);
    
    if (mounted) {
      setState(() {
        _presentesInicio = List<String>.from(dadosChamada['presentes_inicio'] ?? []);
        _presentesFim = List<String>.from(dadosChamada['presentes_fim'] ?? []);
        _alunos = alunosBase;
        _loading = false;
      });
    }
  }

  /// Salva as listas modificadas no Firestore.
  Future<void> _salvar() async {
    final t = AppLocalizations.of(context)!;
    
    await ref.read(servicoFirestoreProvider).atualizarChamadaHistorico(
      widget.turma.id, 
      widget.dataId, 
      _presentesInicio, 
      _presentesFim
    );
    
    if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('ca_presenca_salva_sucesso')), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text("${t.t('prof_editar_turma')}: ${widget.dataId}")), // "Editar: 2025-..."
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _alunos.length,
        itemBuilder: (ctx, i) {
          final aluno = _alunos[i];
          
          // Verifica se o aluno está nas listas carregadas
          final estaPresenteInicio = _presentesInicio.contains(aluno.id);
          final estaPresenteFim = _presentesFim.contains(aluno.id);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  ListTile(
                    title: Text(aluno.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("RA: ${aluno.ra}"),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Chip de Presença INICIAL
                      FilterChip(
                        label: Text(t.t('prof_chamada_tipo_inicio')), // "Início"
                        selected: estaPresenteInicio,
                        selectedColor: Colors.green.withOpacity(0.3),
                        onSelected: (val) {
                          setState(() {
                            val ? _presentesInicio.add(aluno.id) : _presentesInicio.remove(aluno.id);
                          });
                        },
                      ),
                      
                      // Chip de Presença FINAL
                      FilterChip(
                        label: Text(t.t('prof_chamada_tipo_fim')), // "Fim"
                        selected: estaPresenteFim,
                        selectedColor: Colors.green.withOpacity(0.3),
                        onSelected: (val) {
                          setState(() {
                            val ? _presentesFim.add(aluno.id) : _presentesFim.remove(aluno.id);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
      
      // Botão flutuante para salvar
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _salvar,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.save, color: Colors.white),
        label: Text(t.t('salvar'), style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
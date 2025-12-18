// lib/telas/professor/tela_chamada_manual.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/turma_professor.dart';
import '../../models/aluno_chamada.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../comum/widget_carregamento.dart';

// Provider para buscar alunos dessa turma
final provedorChamadaManual = FutureProvider.family<List<AlunoChamada>, String>((ref, turmaId) {
  return ref.watch(servicoFirestoreProvider).getAlunosDaTurma(turmaId);
});

class TelaChamadaManual extends ConsumerStatefulWidget {
  final TurmaProfessor turma;
  const TelaChamadaManual({super.key, required this.turma});

  @override
  ConsumerState<TelaChamadaManual> createState() => _TelaChamadaManualState();
}

class _TelaChamadaManualState extends ConsumerState<TelaChamadaManual> {
  final Set<String> _presentes = {};
  String _tipoChamada = 'inicio'; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // --- MODO TESTE: TRAVA DE HORÁRIO REMOVIDA ---
    // _verificarHorario(); 

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Carrega quem já marcou presença (via NFC ou manual anterior) no dia de HOJE
      _carregarPresencaExistente();
    });
  }

  // Sincroniza com o banco para ver o que o NFC salvou
  Future<void> _carregarPresencaExistente() async {
    setState(() => _isLoading = true);
    try {
      final servico = ref.read(servicoFirestoreProvider);
      
      // MODO TESTE: Busca sempre a data de HOJE, ignorando dia da semana da aula
      final dataId = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final dadosAula = await servico.getDadosChamada(widget.turma.id, dataId);
      
      if (dadosAula.isNotEmpty) {
        // Pega a lista de presença salva (padrão 'inicio')
        final listaSalva = List<String>.from(dadosAula['presentes_$_tipoChamada'] ?? []);
        
        setState(() {
          _presentes.clear(); // Limpa para garantir sync limpo
          _presentes.addAll(listaSalva);
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar presença: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _atualizarListaAoTrocarTipo(String novoTipo) {
    setState(() {
      _tipoChamada = novoTipo;
      _presentes.clear(); // Limpa visualmente antes de recarregar
    });
    _carregarPresencaExistente();
  }

  Future<void> _salvarChamada() async {
    setState(() => _isLoading = true);
    final t = AppLocalizations.of(context)!;

    try {
      // MODO TESTE: Salva com DateTime.now()
      // Isso garante que salve no mesmo documento que o NFC está usando
      await ref.read(servicoFirestoreProvider).salvarPresenca(
        widget.turma.id, 
        _tipoChamada, 
        _presentes.toList(), 
        DateTime.now()
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.t('prof_historico_sucesso')), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final asyncAlunos = ref.watch(provedorChamadaManual(widget.turma.id));
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.t('prof_chamada_manual_titulo')),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _tipoChamada == 'inicio' ? Colors.blue.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _tipoChamada == 'inicio' ? Colors.blue : Colors.orange)
              ),
              child: DropdownButton<String>(
                value: _tipoChamada,
                underline: const SizedBox(),
                isDense: true,
                items: [
                  DropdownMenuItem(value: 'inicio', child: Text(t.t('prof_chamada_tipo_inicio'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  DropdownMenuItem(value: 'fim', child: Text(t.t('prof_chamada_tipo_fim'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                ],
                onChanged: (v) {
                  if (v != null && v != _tipoChamada) {
                    _atualizarListaAoTrocarTipo(v);
                  }
                },
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // AVISO DE MODO LIVRE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.orange.withOpacity(0.2),
            child: const Text(
              "🛠 MODO TESTE: Chamada liberada fora do horário.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),

          // Contador
          Container(
            width: double.infinity,
            color: isDark ? Colors.black12 : Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${t.t('prof_presenca_presentes')}: ${_presentes.length}"),
                asyncAlunos.when(
                  data: (alunos) => TextButton(
                    onPressed: () {
                        setState(() {
                          if (_presentes.length == alunos.length) {
                            _presentes.clear();
                          } else {
                            _presentes.addAll(alunos.map((a) => a.id));
                          }
                        });
                    },
                    child: Text(_presentes.length == alunos.length ? "Limpar" : "Marcar Todos"),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_,__) => const SizedBox.shrink(),
                )
              ],
            ),
          ),

          Expanded(
            child: asyncAlunos.when(
              loading: () => const WidgetCarregamento(),
              error: (e, s) => Center(child: Text("Erro: $e")),
              data: (alunos) {
                if (alunos.isEmpty) return Center(child: Text(t.t('prof_presenca_vazio')));

                // Ordenação Alfabética
                alunos.sort((a, b) => a.nome.compareTo(b.nome));

                return ListView.builder(
                  itemCount: alunos.length,
                  itemBuilder: (context, index) {
                    final aluno = alunos[index];
                    final isSelected = _presentes.contains(aluno.id);

                    return Card(
                      color: isSelected 
                          ? AppColors.success.withOpacity(isDark ? 0.3 : 0.1) 
                          : cardColor,
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: CheckboxListTile(
                        value: isSelected,
                        activeColor: AppColors.success,
                        title: Text(aluno.nome, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        subtitle: Text(aluno.ra),
                        secondary: CircleAvatar(
                          backgroundColor: isSelected ? AppColors.success : Colors.grey,
                          child: Text(aluno.nome.isNotEmpty ? aluno.nome[0] : '?', style: const TextStyle(color: Colors.white)),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) _presentes.add(aluno.id);
                            else _presentes.remove(aluno.id);
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _salvarChamada,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(t.t('prof_chamada_manual_salvar'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
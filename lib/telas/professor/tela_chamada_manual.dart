// ARQUIVO: lib/telas/professor/tela_chamada_manual.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ATENÇÃO AOS CAMINHOS RELATIVOS (suba quantos níveis forem necessários):
import '../../models/turma_professor.dart';
import '../../models/aluno_chamada.dart';
import '../../providers/provedor_professor.dart'; // <--- Importante: deve apontar para o arquivo do Passo 1
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../comum/widget_carregamento.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Agora o método 'carregarAlunos' existirá porque corrigimos o provedor no Passo 1
      ref.read(provedorChamadaManual(widget.turma.id).notifier).carregarAlunos();
    });
  }

  Future<void> _salvarChamada() async {
    setState(() => _isLoading = true);
    final t = AppLocalizations.of(context)!;

    try {
      await ref.read(servicoFirestoreProvider).salvarPresenca(
        widget.turma.id, 
        _tipoChamada, 
        _presentes.toList(), 
        DateTime.now()
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.t('ca_presenca_salva_sucesso')), backgroundColor: Colors.green));
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
    final estado = ref.watch(provedorChamadaManual(widget.turma.id));
    
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
                onChanged: (v) => setState(() => _tipoChamada = v!),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: isDark ? Colors.black12 : Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${t.t('prof_presenca_presentes')}: ${_presentes.length}"),
                TextButton(
                  onPressed: () {
                     setState(() {
                       if (_presentes.length == estado.alunos.length) {
                         _presentes.clear();
                       } else {
                         _presentes.addAll(estado.alunos.map((a) => a.id));
                       }
                     });
                  },
                  child: Text(_presentes.length == estado.alunos.length ? t.t('prof_chamada_manual_limpar') : t.t('prof_chamada_manual_todos')),
                )
              ],
            ),
          ),

          Expanded(
            child: Builder(builder: (ctx) {
              if (estado.status == StatusChamadaManual.carregando) return const WidgetCarregamento();
              if (estado.alunos.isEmpty) return Center(child: Text(t.t('prof_presenca_vazio')));

              return ListView.builder(
                itemCount: estado.alunos.length,
                itemBuilder: (context, index) {
                  final aluno = estado.alunos[index];
                  final isSelected = _presentes.contains(aluno.id);
                  final isPendente = aluno.id.startsWith('pre_');

                  return Card(
                    color: isSelected 
                        ? AppColors.success.withOpacity(isDark ? 0.3 : 0.1) 
                        : cardColor,
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: CheckboxListTile(
                      value: isSelected,
                      activeColor: AppColors.success,
                      title: Text(
                        aluno.nome, 
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isPendente ? Colors.orange : null 
                        )
                      ),
                      subtitle: Text(isPendente ? t.t('prof_aluno_pendente') : aluno.ra),
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
            }),
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
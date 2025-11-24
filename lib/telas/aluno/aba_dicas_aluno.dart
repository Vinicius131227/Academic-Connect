// lib/telas/aluno/aba_dicas_aluno.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/dica_aluno.dart';
import '../../l10n/app_localizations.dart';
import '../../services/servico_firestore.dart';
import '../comum/widget_carregamento.dart';
import '../../providers/provedor_autenticacao.dart';
import 'package:intl/intl.dart';

class AbaDicasAluno extends ConsumerStatefulWidget {
  final String turmaId;
  final String nomeDisciplina; // NOVO: Precisamos do nome para gerar o base
  
  const AbaDicasAluno({
    super.key, 
    required this.turmaId,
    this.nomeDisciplina = '', // Opcional para compatibilidade, mas deve ser passado
  });

  @override
  ConsumerState<AbaDicasAluno> createState() => _AbaDicasAlunoState();
}

class _AbaDicasAlunoState extends ConsumerState<AbaDicasAluno> {
  final _dicaController = TextEditingController();
  bool _isLoading = false;

  // Helper para simplificar o nome (Ex: "Cálculo 1" -> "Cálculo")
  String _getNomeBase(String nome) {
    final nomeBase = nome.replaceAll(RegExp(r'\s*\d+$'), '');
    return nomeBase.trim();
  }

  Future<void> _postarDica() async {
    if (_dicaController.text.isEmpty) return;

    final alunoUid = ref.read(provedorNotificadorAutenticacao).usuario?.uid;
    if (alunoUid == null) return;

    setState(() => _isLoading = true);
    final t = AppLocalizations.of(context)!;
    
    // Calcula o nome base para salvar junto
    final nomeBase = _getNomeBase(widget.nomeDisciplina);

    final novaDica = DicaAluno(
      id: '',
      texto: _dicaController.text,
      alunoId: alunoUid,
      dataPostagem: DateTime.now(),
    );

    try {
      // MODIFICADO: Passa o nomeBaseDisciplina
      await ref.read(servicoFirestoreProvider).adicionarDica(widget.turmaId, novaDica, nomeBase);
      
      _dicaController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.t('dicas_postar_sucesso')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao postar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    // Calcula o nome base para buscar dicas de TODAS as turmas similares
    final nomeBase = _getNomeBase(widget.nomeDisciplina);
    
    // Usa o novo provedor por nome
    final streamDicas = ref.watch(streamDicasPorNomeProvider(nomeBase));
    
    final theme = Theme.of(context);

    return Column(
      children: [
        // Card para postar
        Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.t('dicas_titulo'),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  t.t('dicas_subtitulo'),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _dicaController,
                  decoration: InputDecoration(
                    hintText: t.t('dicas_placeholder'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: _isLoading
                      ? Container(width: 20, height: 20, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_outlined, size: 18),
                  label: Text(_isLoading ? 'Postando...' : t.t('dicas_postar_botao')),
                  onPressed: _isLoading ? null : _postarDica,
                ),
              ],
            ),
          ),
        ),
        // Lista de Dicas (GLOBAL DA DISCIPLINA)
        Expanded(
          child: streamDicas.when(
            loading: () => const WidgetCarregamento(),
            error: (err, st) => Center(child: Text('Erro: $err')),
            data: (dicas) {
              if (dicas.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      t.t('dicas_vazio'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: dicas.length,
                itemBuilder: (context, index) {
                  final dica = dicas[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ListTile(
                      leading: const Icon(Icons.lightbulb_outline, color: Colors.orange),
                      title: Text(dica.texto),
                      subtitle: Text(
                        'Postado em ${DateFormat('dd/MM/yyyy').format(dica.dataPostagem)}',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
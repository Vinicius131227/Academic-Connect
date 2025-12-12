// lib/telas/aluno/aba_dicas_aluno.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:intl/intl.dart';

// Importações de modelos e provedores
import '../../models/dica_aluno.dart';
import '../../l10n/app_localizations.dart';
import '../../services/servico_firestore.dart';
import '../comum/widget_carregamento.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../providers/provedores_app.dart';

@UseCase(
  name: 'Aba de Dicas (Aluno)',
  type: AbaDicasAluno,
)
Widget buildAbaDicasAluno(BuildContext context) {
  return const ProviderScope(
    child: Scaffold(
      body: AbaDicasAluno(
        turmaId: 'mock_id', 
        nomeDisciplina: 'Cálculo 1'
      ),
    ),
  );
}

class AbaDicasAluno extends ConsumerStatefulWidget {
  final String turmaId;
  final String nomeDisciplina;
  
  const AbaDicasAluno({
    super.key, 
    required this.turmaId,
    this.nomeDisciplina = '',
  });

  @override
  ConsumerState<AbaDicasAluno> createState() => _AbaDicasAlunoState();
}

class _AbaDicasAlunoState extends ConsumerState<AbaDicasAluno> {
  final _dicaController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _dicaController.dispose();
    super.dispose();
  }

  String _getNomeBase(String nome) {
    return nome.trim(); 
  }

  Future<void> _postarDica() async {
    if (_dicaController.text.isEmpty) return;

    final t = AppLocalizations.of(context)!;
    
    final usuario = ref.read(provedorNotificadorAutenticacao).usuario;
    final alunoUid = usuario?.uid;
    
    if (alunoUid == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(t.t('erro_generico')), backgroundColor: Colors.red)
       );
       return;
    }

    setState(() => _isLoading = true);
    
    final nomeBase = _getNomeBase(widget.nomeDisciplina);
    final nomeAutor = usuario?.alunoInfo?.nomeCompleto.split(' ').first ?? 'Anônimo';

    final novaDica = DicaAluno(
      id: '', 
      texto: _dicaController.text,
      alunoId: alunoUid,
      autorNome: nomeAutor,
      materia: nomeBase,
      dataPostagem: DateTime.now(),
      nomeBaseDisciplina: nomeBase, 
    );

    try {
      // CORRIGIDO: Passando apenas os 2 argumentos necessários (conforme atualizado no service)
      await ref.read(servicoFirestoreProvider).adicionarDica(widget.turmaId, novaDica);
      
      _dicaController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.t('dicas_postar_sucesso')), 
            backgroundColor: Colors.green,
          ),
        );
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.t('erro_generico')}: $e'), backgroundColor: Colors.red),
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
    final nomeBase = _getNomeBase(widget.nomeDisciplina);
    
    final streamDicas = ref.watch(streamDicasPorNomeProvider(nomeBase));
    final theme = Theme.of(context);

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16.0),
          elevation: 2,
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
                    filled: true,
                  ),
                  maxLines: 3,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_outlined, size: 18),
                  label: Text(_isLoading ? t.t('carregando') : t.t('dicas_postar_botao')), 
                  onPressed: _isLoading ? null : _postarDica,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: streamDicas.when(
            loading: () => const WidgetCarregamento(),
            error: (err, st) {
               if (err.toString().contains("failed-precondition")) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("Configuração pendente: Índice do Firebase necessário.", textAlign: TextAlign.center),
                  ));
               }
               return Center(child: Text('${t.t('erro_generico')}: $err'));
            },
            data: (dicas) {
              if (dicas.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      t.t('dicas_vazio'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: dicas.length,
                itemBuilder: (context, index) {
                  final dica = dicas[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ListTile(
                      leading: const Icon(Icons.lightbulb_outline, color: Colors.orange),
                      title: Text(dica.texto),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(dica.dataPostagem), 
                            style: const TextStyle(fontSize: 12)
                          ),
                          Text(
                            "por: ${dica.autorNome}",
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                          ),
                        ],
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
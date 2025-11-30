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

/// Caso de uso para o Widgetbook.
/// Simula a aba de dicas de uma disciplina genérica.
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

/// Tela que exibe e permite postar dicas sobre uma disciplina específica.
/// 
/// As dicas são compartilhadas globalmente com base no nome da disciplina.
/// Ex: Uma dica postada na turma de "Cálculo 1" de 2023 aparecerá para a turma de 2024.
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

  /// Normaliza o nome da disciplina para agrupar dicas.
  /// Ex: "Cálculo 1 - Turma A" -> "Cálculo 1"
  String _getNomeBase(String nome) {
    // Remove números e letras soltas do final se houver padrão de turma
    // Mas mantém números importantes como "Cálculo 1"
    // Aqui usamos uma lógica simples: usa o nome como está ou remove sufixos
    // Para este MVP, vamos assumir que o nome da disciplina já vem limpo ou usamos ele todo.
    return nome.trim(); 
  }

  /// Envia a dica para o Firestore.
  Future<void> _postarDica() async {
    if (_dicaController.text.isEmpty) return;

    final alunoUid = ref.read(provedorNotificadorAutenticacao).usuario?.uid;
    if (alunoUid == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Erro: Usuário não autenticado.'), backgroundColor: Colors.red)
       );
       return;
    }

    setState(() => _isLoading = true);
    final t = AppLocalizations.of(context)!;
    
    final nomeBase = _getNomeBase(widget.nomeDisciplina);

    final novaDica = DicaAluno(
      id: '', // Gerado pelo Firestore
      texto: _dicaController.text,
      alunoId: alunoUid,
      dataPostagem: DateTime.now(),
      nomeBaseDisciplina: nomeBase, // Importante para a busca global
    );

    try {
      await ref.read(servicoFirestoreProvider).adicionarDica(widget.turmaId, novaDica, nomeBase);
      
      _dicaController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.t('dicas_postar_sucesso')), // "Dica postada!"
            backgroundColor: Colors.green,
          ),
        );
        // Fecha o teclado
        FocusScope.of(context).unfocus();
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
    final nomeBase = _getNomeBase(widget.nomeDisciplina);
    
    // Busca dicas globais para esta disciplina
    final streamDicas = ref.watch(streamDicasPorNomeProvider(nomeBase));
    final theme = Theme.of(context);

    return Column(
      children: [
        // 1. Área de Postagem
        Card(
          margin: const EdgeInsets.all(16.0),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.t('dicas_titulo'), // "Dicas para Próximos Alunos"
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  t.t('dicas_subtitulo'), // "Deixe uma dica anônima..."
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _dicaController,
                  decoration: InputDecoration(
                    hintText: t.t('dicas_placeholder'), // "Escreva aqui..."
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

        // 2. Lista de Dicas
        Expanded(
          child: streamDicas.when(
            loading: () => const WidgetCarregamento(),
            error: (err, st) {
               // Tratamento para o erro de índice do Firebase
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
                      t.t('dicas_vazio'), // "Nenhuma dica encontrada."
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
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(dica.dataPostagem),
                        style: const TextStyle(fontSize: 12),
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
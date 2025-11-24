// lib/telas/comum/aba_chat_disciplina.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/mensagem_chat.dart';
import '../../services/servico_firestore.dart'; // O provedor streamMensagensProvider vem daqui
import '../../providers/provedor_autenticacao.dart';
import 'widget_carregamento.dart';
import 'package:intl/intl.dart';

class AbaChatDisciplina extends ConsumerStatefulWidget {
  final String turmaId;
  const AbaChatDisciplina({super.key, required this.turmaId});

  @override
  ConsumerState<AbaChatDisciplina> createState() => _AbaChatDisciplinaState();
}

class _AbaChatDisciplinaState extends ConsumerState<AbaChatDisciplina> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  Future<void> _enviarMensagem() async {
    if (_controller.text.trim().isEmpty) return;

    final usuario = ref.read(provedorNotificadorAutenticacao).usuario;
    if (usuario == null) return;

    String nomeUsuario = usuario.alunoInfo?.nomeCompleto ?? (usuario.email.split('@').first);
    if (nomeUsuario.isEmpty) nomeUsuario = usuario.email;

    setState(() => _isLoading = true);

    final novaMensagem = MensagemChat(
      id: '',
      texto: _controller.text.trim(),
      usuarioId: usuario.uid,
      usuarioNome: nomeUsuario,
      dataHora: DateTime.now(),
    );

    try {
      await ref.read(servicoFirestoreProvider).enviarMensagem(widget.turmaId, novaMensagem);
      _controller.clear();
      // Rola para o final da lista
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e'), backgroundColor: Colors.red),
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
    // Aqui ele usa o provedor definido no final do servico_firestore.dart
    final streamMensagens = ref.watch(streamMensagensProvider(widget.turmaId));
    final meuUid = ref.watch(provedorNotificadorAutenticacao).usuario?.uid;
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: streamMensagens.when(
            loading: () => const WidgetCarregamento(),
            error: (err, st) => Center(child: Text('Erro ao carregar chat: $err')),
            data: (mensagens) {
              if (mensagens.isEmpty) {
                return Center(
                  child: Text(
                    'Seja o primeiro a enviar uma mensagem!',
                    style: theme.textTheme.titleMedium,
                  ),
                );
              }
              return ListView.builder(
                controller: _scrollController,
                reverse: true, // Mostra as mais novas no topo (base da lista)
                padding: const EdgeInsets.all(16.0),
                itemCount: mensagens.length,
                itemBuilder: (context, index) {
                  final msg = mensagens[index];
                  final bool souEu = msg.usuarioId == meuUid;

                  return _buildBubble(context, msg, souEu);
                },
              );
            },
          ),
        ),
        // Input de texto
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Digite uma mensagem...',
                      border: InputBorder.none,
                      filled: false,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !_isLoading,
                    onSubmitted: (_) => _enviarMensagem(),
                  ),
                ),
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.send, color: theme.colorScheme.primary),
                  onPressed: _isLoading ? null : _enviarMensagem,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBubble(BuildContext context, MensagemChat msg, bool souEu) {
    final theme = Theme.of(context);
    final alignment = souEu ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = souEu ? theme.colorScheme.primary : theme.colorScheme.secondaryContainer;
    final textColor = souEu ? theme.colorScheme.onPrimary : theme.colorScheme.onSecondaryContainer;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          // Nome do remetente (se não for eu)
          if (!souEu)
            Padding(
              padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
              child: Text(
                msg.usuarioNome,
                style: theme.textTheme.bodySmall,
              ),
            ),
          // Balão da mensagem
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: souEu ? const Radius.circular(16) : const Radius.circular(4),
                bottomRight: souEu ? const Radius.circular(4) : const Radius.circular(16),
              ),
            ),
            child: Text(
              msg.texto,
              style: TextStyle(color: textColor),
            ),
          ),
          // Horário
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 12.0, right: 12.0),
            child: Text(
              DateFormat('HH:mm').format(msg.dataHora),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
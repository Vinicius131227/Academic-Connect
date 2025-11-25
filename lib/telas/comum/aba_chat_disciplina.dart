// lib/telas/comum/aba_chat_disciplina.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/mensagem_chat.dart';
import '../../services/servico_firestore.dart';
import '../../providers/provedor_autenticacao.dart';
import 'widget_carregamento.dart';
import 'package:intl/intl.dart';
import '../../themes/app_theme.dart';

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
    } catch (e) {
      // Erro silencioso ou snackbar
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streamMensagens = ref.watch(streamMensagensProvider(widget.turmaId));
    final meuUid = ref.watch(provedorNotificadorAutenticacao).usuario?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: streamMensagens.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => const Center(child: Text('Erro no chat', style: TextStyle(color: Colors.white))),
              data: (mensagens) {
                if (mensagens.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.white24),
                        SizedBox(height: 16),
                        Text('Nenhuma mensagem ainda.', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, 
                  padding: const EdgeInsets.all(16.0),
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final msg = mensagens[index];
                    final bool souEu = msg.usuarioId == meuUid;
                    return _buildBubble(msg, souEu);
                  },
                );
              },
            ),
          ),
          // Input Moderno
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Digite uma mensagem...',
                          hintStyle: TextStyle(color: Colors.white24),
                          border: InputBorder.none,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        enabled: !_isLoading,
                        onSubmitted: (_) => _enviarMensagem(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: AppColors.primaryPurple,
                    child: IconButton(
                      icon: _isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _isLoading ? null : _enviarMensagem,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(MensagemChat msg, bool souEu) {
    return Align(
      alignment: souEu ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: souEu ? AppColors.primaryPurple : const Color(0xFF383838),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: souEu ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: souEu ? const Radius.circular(4) : const Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!souEu)
              Text(msg.usuarioNome, style: const TextStyle(color: AppColors.cardBlue, fontSize: 12, fontWeight: FontWeight.bold)),
            if (!souEu) const SizedBox(height: 4),
            Text(msg.texto, style: const TextStyle(color: Colors.white, fontSize: 15)),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('HH:mm').format(msg.dataHora),
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// lib/telas/comum/aba_chat_disciplina.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/mensagem_chat.dart';
import '../../services/servico_firestore.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../themes/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Caso de uso para o Widgetbook.
/// Simula a tela de chat.
@UseCase(
  name: 'Chat da Disciplina',
  type: AbaChatDisciplina,
)
Widget buildChat(BuildContext context) {
  // Como depende de um ID real, aqui mostramos apenas a estrutura básica
  return const ProviderScope(
    child: Scaffold(body: AbaChatDisciplina(turmaId: 'demo_id')),
  );
}

/// Tela de Chat de uma turma específica.
/// Permite enviar e receber mensagens em tempo real.
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

  /// Envia a mensagem para o Firestore
  Future<void> _enviarMensagem() async {
    if (_controller.text.trim().isEmpty) return;
    
    final usuario = ref.read(provedorNotificadorAutenticacao).usuario;
    if (usuario == null) return;

    // Define o nome de exibição
    String nomeUsuario = usuario.alunoInfo?.nomeCompleto ?? (usuario.email.split('@').first);
    if (nomeUsuario.isEmpty) nomeUsuario = usuario.email;

    setState(() => _isLoading = true);
    
    final novaMensagem = MensagemChat(
      id: '', // Gerado pelo banco
      texto: _controller.text.trim(),
      usuarioId: usuario.uid,
      usuarioNome: nomeUsuario,
      dataHora: DateTime.now(),
    );

    try {
      await ref.read(servicoFirestoreProvider).enviarMensagem(widget.turmaId, novaMensagem);
      _controller.clear(); // Limpa o campo
    } catch (e) {
      // Tratamento silencioso de erro de envio (pode adicionar snackbar se quiser)
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    // Provedor de mensagens em tempo real (Stream)
    final streamMensagens = ref.watch(streamMensagensProvider(widget.turmaId));
    final meuUid = ref.watch(provedorNotificadorAutenticacao).usuario?.uid;
    
    // Tema
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final inputColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // LISTA DE MENSAGENS
          Expanded(
            child: streamMensagens.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Erro ao carregar chat', style: TextStyle(color: textColor))),
              data: (mensagens) {
                if (mensagens.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(t.t('chat_vazio'), style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Começa de baixo para cima
                  padding: const EdgeInsets.all(16.0),
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final msg = mensagens[index];
                    final bool souEu = msg.usuarioId == meuUid;
                    return _buildBubble(msg, souEu, textColor ?? Colors.black);
                  },
                );
              },
            ),
          ),
          
          // BARRA DE ENTRADA DE TEXTO
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: inputColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: t.t('chat_placeholder'), // "Digite uma mensagem..."
                          hintStyle: const TextStyle(color: Colors.grey),
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

  /// Constrói o balão de mensagem.
  Widget _buildBubble(MensagemChat msg, bool souEu, Color textColor) {
    return Align(
      alignment: souEu ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Cor diferente para minhas mensagens e dos outros
          color: souEu ? AppColors.primaryPurple : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF383838) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: souEu ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: souEu ? const Radius.circular(4) : const Radius.circular(20),
          ),
          // Sombra leve para mensagens brancas (tema claro)
          boxShadow: souEu ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!souEu)
              Text(
                msg.usuarioNome, 
                style: const TextStyle(color: AppColors.cardBlue, fontSize: 12, fontWeight: FontWeight.bold)
              ),
            if (!souEu) const SizedBox(height: 4),
            
            Text(
              msg.texto, 
              style: TextStyle(
                color: souEu ? Colors.white : textColor, 
                fontSize: 15
              )
            ),
            const SizedBox(height: 4),
            
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('HH:mm').format(msg.dataHora),
                style: TextStyle(
                  color: souEu ? Colors.white.withOpacity(0.7) : Colors.grey, 
                  fontSize: 10
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
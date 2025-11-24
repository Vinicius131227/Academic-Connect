import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/evento_ca.dart';
import '../../providers/provedor_ca.dart';
import '../../l10n/app_localizations.dart'; // Importa i18n

class TelaPresencaEvento extends ConsumerStatefulWidget {
  final EventoCA evento;
  const TelaPresencaEvento({super.key, required this.evento});

  @override
  ConsumerState<TelaPresencaEvento> createState() => _TelaPresencaEventoState();
}

class _TelaPresencaEventoState extends ConsumerState<TelaPresencaEvento> {
  // --- NOVO: Estado de carregamento para o botão Salvar ---
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Limpa qualquer estado de uma chamada anterior ao abrir a tela
    Future.microtask(() => ref.read(provedorPresencaEventoNFC.notifier).reset());
  }

  @override
  void dispose() {
    // Pausa a leitura ao sair da tela
    Future.microtask(() => ref.read(provedorPresencaEventoNFC.notifier).pausarLeitura());
    super.dispose();
  }

  // --- NOVO MÉTODO: Salvar Presença ---
  Future<void> _onSalvar(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final notifier = ref.read(provedorPresencaEventoNFC.notifier);

    setState(() => _isLoading = true);

    try {
      // Chama o notificador para salvar no Firebase
      await notifier.salvarChamadaEvento(widget.evento.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('ca_presenca_salva_sucesso') ?? 'Presença salva com sucesso!'), backgroundColor: Colors.green), // TODO: Adicionar tradução
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  // --- FIM NOVO MÉTODO ---

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!; // Pega o tradutor
    // USA O PROVEDOR DO C.A.
    final estadoNFC = ref.watch(provedorPresencaEventoNFC); 
    final notifierNFC = ref.read(provedorPresencaEventoNFC.notifier);
    final bool lendo = estadoNFC.status == StatusNFC.lendo;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('ca_presenca_titulo') ?? 'Registrar Presença'), // TODO: Adicionar tradução
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30.0),
          child: Container(
            padding: const EdgeInsets.only(bottom: 8.0),
            alignment: Alignment.center,
            child: Text(
              widget.evento.nome, // Mostra o nome do Evento
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildCardLeitura(context, t, lendo, estadoNFC.status, estadoNFC.erro, notifierNFC, widget.evento.id),
                const SizedBox(height: 16),
                _buildCardPresentes(context, t, estadoNFC),
                const SizedBox(height: 16),
                _buildCardRegistrados(context, t, estadoNFC),
              ],
            ),
          ),
          _buildFeedbackPopup(
            context,
            sucessoMsg: estadoNFC.ultimoAluno,
            erroMsg: estadoNFC.ultimoErroScan,
          ),
        ],
      ),
    );
  }

  // (Todos os widgets auxiliares abaixo são idênticos aos da tela do professor)
  Widget _buildCardLeitura(BuildContext context, AppLocalizations t, bool lendo, StatusNFC status, String? erro, NotificadorPresencaEventoNFC notifier, String eventoId) {
    IconData icone = Icons.nfc;
    Color corIcone = Colors.grey;
    String titulo = t.t('prof_presenca_nfc_pausada_titulo') ?? 'Leitura NFC Pausada'; 
    String subtitulo = t.t('prof_presenca_nfc_pausada_desc') ?? 'Clique em "Iniciar Leitura" para começar'; 
    
    if (lendo) {
      icone = Icons.nfc; corIcone = Colors.green;
      titulo = t.t('ca_presenca_nfc_lendo_titulo') ?? 'Aguardando cartão...'; // TODO: Adicionar tradução
      subtitulo = t.t('ca_presenca_nfc_lendo_desc') ?? 'Os participantes devem aproximar seus cartões'; // TODO: Adicionar tradução
    } else if (status == StatusNFC.indisponivel) {
      icone = Icons.nfc_outlined; corIcone = Colors.red;
      titulo = t.t('prof_presenca_nfc_indisponivel_titulo') ?? 'NFC Indisponível';
      subtitulo = erro ?? t.t('prof_presenca_nfc_indisponivel_desc') ?? 'Este dispositivo não suporta NFC.';
    } else if (status == StatusNFC.erro) {
      icone = Icons.error_outline; corIcone = Colors.red;
      titulo = t.t('prof_presenca_nfc_erro_titulo') ?? 'Erro na Leitura';
      subtitulo = erro ?? t.t('prof_presenca_nfc_erro_desc') ?? 'Ocorreu um erro. Tente novamente.';
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(icone, size: 80, color: corIcone),
            const SizedBox(height: 16),
            Text(titulo, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitulo, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: (status == StatusNFC.erro || status == StatusNFC.indisponivel) ? Colors.red : null), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(lendo ? Icons.pause : Icons.play_arrow),
              label: Text(lendo ? (t.t('prof_presenca_nfc_pausar') ?? 'Pausar Leitura') : (t.t('prof_presenca_nfc_iniciar') ?? 'Iniciar Leitura')),
              style: ElevatedButton.styleFrom(
                backgroundColor: lendo ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: (status == StatusNFC.indisponivel || _isLoading) ? null : () {
                lendo ? notifier.pausarLeitura() : notifier.iniciarLeitura(eventoId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPresentes(BuildContext context, AppLocalizations t, EstadoPresencaNFC estado) {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.group, color: Colors.green[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${t.t('prof_presenca_presentes') ?? 'Presentes'}: ${estado.presentes.length}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.green[800],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8), 
            if (estado.presentes.isNotEmpty)
              ElevatedButton(
                onPressed: _isLoading ? null : () => _onSalvar(context),
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(t.t('prof_presenca_nfc_finalizar') ?? 'Finalizar e Salvar'), // TODO: Adicionar tradução
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardRegistrados(BuildContext context, AppLocalizations t, EstadoPresencaNFC estado) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.t('ca_presenca_registrados') ?? 'Participantes Registrados', // TODO: Adicionar tradução
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 24),
            if (estado.presentes.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(t.t('ca_presenca_vazio') ?? 'Nenhum participante registrado ainda'), // TODO: Adicionar tradução
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: estado.presentes.length,
                itemBuilder: (context, index) {
                  final aluno = estado.presentes.reversed.toList()[index];
                  return ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(aluno.nome),
                    subtitle: Text(t.t('prof_presenca_nfc_presente') ?? 'Presente'),
                    trailing: Text(aluno.hora),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeedbackPopup(BuildContext context, {String? sucessoMsg, String? erroMsg}) {
    bool mostrarSucesso = sucessoMsg != null;
    bool mostrarErro = erroMsg != null;
    bool mostrar = mostrarSucesso || mostrarErro;
    
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: mostrar ? 0 : -100,
      left: 0,
      right: 0,
      child: Material(
        elevation: 4.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: mostrarSucesso ? Colors.green : Colors.red,
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(mostrarSucesso ? Icons.check_circle : Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sucessoMsg ?? erroMsg ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
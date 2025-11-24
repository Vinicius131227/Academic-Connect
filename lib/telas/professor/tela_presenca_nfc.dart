// lib/telas/professor/tela_presenca_nfc.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/turma_professor.dart';
import '../../providers/provedor_professor.dart';
import '../../l10n/app_localizations.dart';
import '../comum/widget_carregamento.dart';
import 'package:intl/intl.dart';

class TelaPresencaNFC extends ConsumerStatefulWidget {
  final TurmaProfessor turma;
  const TelaPresencaNFC({super.key, required this.turma});

  @override
  ConsumerState<TelaPresencaNFC> createState() => _TelaPresencaNFCState();
}

class _TelaPresencaNFCState extends ConsumerState<TelaPresencaNFC> {
  bool _isLoading = false;
  DateTime _dataSelecionada = DateTime.now();
  String? _tipoChamadaFinal; 

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(provedorPresencaNFC.notifier).reset());
  }

  @override
  void dispose() {
    Future.microtask(() => ref.read(provedorPresencaNFC.notifier).pausarLeitura());
    super.dispose();
  }
  
  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (data != null) {
      setState(() => _dataSelecionada = data);
    }
  }

  Future<void> _onSalvar(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final notifierNFC = ref.read(provedorPresencaNFC.notifier);

    // 1. Pergunta ao professor qual chamada ele está fazendo
    final String? tipoChamada = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.t('prof_chamada_tipo_titulo')),
        content: Text(t.t('prof_chamada_tipo_desc')),
        actions: [
          TextButton(
            child: Text(t.t('prof_chamada_tipo_inicio')),
            onPressed: () => Navigator.pop(ctx, 'inicio'),
          ),
          ElevatedButton(
            child: Text(t.t('prof_chamada_tipo_fim')),
            onPressed: () => Navigator.pop(ctx, 'fim'),
          ),
        ],
      ),
    );

    if (tipoChamada == null || !context.mounted) return;

    setState(() {
      _isLoading = true;
      _tipoChamadaFinal = tipoChamada;
    });

    try {
      // 2. Chama o notificador para salvar no Firebase, passando a data selecionada
      await notifierNFC.salvarChamadaNFC(widget.turma.id, tipoChamada, _dataSelecionada);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chamada ($tipoChamada) salva com sucesso!'), backgroundColor: Colors.green),
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final estadoNFC = ref.watch(provedorPresencaNFC); 
    final notifierNFC = ref.read(provedorPresencaNFC.notifier);
    final bool lendo = estadoNFC.status == StatusNFC.lendo;
    
    // Observa o provedor de pré-chamada para verificar bloqueios
    final asyncPreChamada = ref.watch(provedorPreChamada(widget.turma));
    final preChamada = asyncPreChamada.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('prof_presenca_nfc_titulo')),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30.0),
          child: Container(
            padding: const EdgeInsets.only(bottom: 8.0),
            alignment: Alignment.center,
            child: Text(
              widget.turma.nome,
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
                // --- Bloco de Status e Ações ---
                if (asyncPreChamada.isLoading)
                  const WidgetCarregamento(texto: 'Verificando horário...')
                else if (preChamada?.bloqueioMensagem != null && preChamada?.podeChamar == false)
                  Card(
                    color: Colors.red.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(preChamada!.bloqueioMensagem!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          
                          // Opção de Selecionar Data para Chamada Retroativa
                          if (preChamada.bloqueioMensagem == t.t('chamada_aviso_passado'))
                            OutlinedButton.icon(
                              icon: const Icon(Icons.date_range),
                              label: Text('Dia Selecionado: ${DateFormat('dd/MM/yyyy').format(_dataSelecionada)}'),
                              onPressed: () => _selecionarData(context),
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  _buildCardLeitura(context, t, lendo, estadoNFC.status, estadoNFC.erro, notifierNFC, widget.turma.id, preChamada!.podeChamar),
                // --- Fim Bloco de Status ---

                const SizedBox(height: 16),
                _buildCardPresentes(context, t, estadoNFC, preChamada?.podeChamar ?? false),
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

  Widget _buildCardLeitura(BuildContext context, AppLocalizations t, bool lendo, StatusNFC status, String? erro, NotificadorPresencaNFC notifier, String turmaId, bool podeChamar) {
    IconData icone = Icons.nfc;
    Color corIcone = Colors.grey;
    String titulo = t.t('prof_presenca_nfc_pausada_titulo'); 
    String subtitulo = t.t('prof_presenca_nfc_pausada_desc'); 
    
    if (lendo) {
      icone = Icons.nfc; corIcone = Colors.green;
      titulo = t.t('prof_presenca_nfc_lendo_titulo'); 
      subtitulo = t.t('prof_presenca_nfc_lendo_desc'); 
    } else if (status == StatusNFC.indisponivel) {
      icone = Icons.nfc_outlined; corIcone = Colors.red;
      titulo = t.t('prof_presenca_nfc_indisponivel_titulo'); 
      subtitulo = erro ?? t.t('prof_presenca_nfc_indisponivel_desc'); 
    } else if (status == StatusNFC.erro) {
      icone = Icons.error_outline; corIcone = Colors.red;
      titulo = t.t('prof_presenca_nfc_erro_titulo'); 
      subtitulo = erro ?? t.t('prof_presenca_nfc_erro_desc'); 
    }
    
    final bool isEnabled = podeChamar && (status != StatusNFC.indisponivel);
    
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
              label: Text(lendo ? t.t('prof_presenca_nfc_pausar') : t.t('prof_presenca_nfc_iniciar')),
              style: ElevatedButton.styleFrom(
                backgroundColor: lendo ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: isEnabled ? () {
                lendo ? notifier.pausarLeitura() : notifier.iniciarLeitura(turmaId);
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPresentes(BuildContext context, AppLocalizations t, EstadoPresencaNFC estado, bool podeChamar) {
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
                      '${t.t('prof_presenca_presentes')}: ${estado.presentes.length}',
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
                onPressed: podeChamar && !_isLoading ? () => _onSalvar(context) : null,
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(t.t('prof_presenca_nfc_finalizar')),
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
              t.t('prof_presenca_nfc_registrados'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 24),
            if (estado.presentes.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(t.t('prof_presenca_nfc_vazio')),
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
                    subtitle: Text(t.t('prof_presenca_nfc_presente')),
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
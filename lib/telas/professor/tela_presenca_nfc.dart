// lib/telas/professor/tela_presenca_nfc.dart

import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/turma_professor.dart';
import '../../models/aluno_chamada.dart'; 
import '../../providers/provedor_professor.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../comum/widget_carregamento.dart';
import '../../themes/app_theme.dart';

class TelaPresencaNFC extends ConsumerStatefulWidget {
  final TurmaProfessor turma;
  const TelaPresencaNFC({super.key, required this.turma});

  @override
  ConsumerState<TelaPresencaNFC> createState() => _TelaPresencaNFCState();
}

class _TelaPresencaNFCState extends ConsumerState<TelaPresencaNFC> with WidgetsBindingObserver {
  final Set<String> _idsPresentes = {};
  final List<AlunoChamada> _listaVisual = [];
  bool _isLoading = false;
  
  String? _ultimoSucesso;
  String? _ultimoErro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => ref.read(provedorCadastroNFC.notifier).reset());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarPresencaExistente();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Future.microtask(() => ref.read(provedorCadastroNFC.notifier).pausarLeitura());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ref.read(provedorCadastroNFC.notifier).pausarLeitura();
    }
  }

  Future<void> _carregarPresencaExistente() async {
    setState(() => _isLoading = true);
    try {
      final servico = ref.read(servicoFirestoreProvider);
      final dataId = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final dadosAula = await servico.getDadosChamada(widget.turma.id, dataId);
      
      if (dadosAula.isNotEmpty) {
        final listaIds = List<String>.from(dadosAula['presentes_inicio'] ?? []);
        if (listaIds.isNotEmpty) {
          final todosAlunos = await servico.getAlunosDaTurma(widget.turma.id);
          setState(() {
            _idsPresentes.clear();
            _listaVisual.clear();
            _idsPresentes.addAll(listaIds);
            for (var aluno in todosAlunos) {
              if (listaIds.contains(aluno.id)) {
                _listaVisual.add(aluno);
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Erro load: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processarTagLida(String nfcId) async {
    final servico = ref.read(servicoFirestoreProvider);
    final usuarioAluno = await servico.getAlunoPorNFC(nfcId);

    if (usuarioAluno == null) {
      _mostrarFeedback(erro: "Cartão não cadastrado.");
      return;
    }

    if (!widget.turma.alunosInscritos.contains(usuarioAluno.uid)) {
       _mostrarFeedback(erro: "Aluno não é desta turma.");
       return;
    }

    if (_idsPresentes.contains(usuarioAluno.uid)) {
       _mostrarFeedback(erro: "Já registrou presença hoje.");
       return;
    }

    final novoAluno = AlunoChamada(
      id: usuarioAluno.uid,
      nome: usuarioAluno.alunoInfo?.nomeCompleto ?? 'Aluno',
      ra: usuarioAluno.alunoInfo?.ra ?? '',
      hora: DateFormat('HH:mm').format(DateTime.now()),
    );

    setState(() {
      _idsPresentes.add(usuarioAluno.uid);
      _listaVisual.insert(0, novoAluno);
    });

    try {
      await servico.salvarPresenca(
        widget.turma.id, 
        'inicio', 
        _idsPresentes.toList(), 
        DateTime.now()
      );
      _mostrarFeedback(sucesso: "Presença: ${usuarioAluno.alunoInfo?.nomeCompleto}");
    } catch (e) {
      setState(() {
        _idsPresentes.remove(usuarioAluno.uid);
        _listaVisual.removeAt(0);
      });
      _mostrarFeedback(erro: "Erro ao salvar.");
    }
  }

  void _mostrarFeedback({String? sucesso, String? erro}) {
    setState(() {
      _ultimoSucesso = sucesso;
      _ultimoErro = erro;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() { _ultimoSucesso = null; _ultimoErro = null; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final estadoNFC = ref.watch(provedorCadastroNFC);
    final notifierNFC = ref.read(provedorCadastroNFC.notifier);
    final bool lendo = estadoNFC.status == StatusCadastroNFC.scanning;

    ref.listen(provedorCadastroNFC, (prev, next) {
      if (next.status == StatusCadastroNFC.success && next.uid != null) {
        _processarTagLida(next.uid!);
        notifierNFC.reset();
        Future.delayed(const Duration(seconds: 1), () {
           if (mounted && lendo) notifierNFC.iniciarLeitura();
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('prof_presenca_nfc_titulo')),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildCardLeitura(context, t, lendo, estadoNFC.status, estadoNFC.erro, notifierNFC),
                const SizedBox(height: 16),
                _buildCardPresentes(context, t),
                const SizedBox(height: 16),
                _buildCardRegistrados(context, t),
              ],
            ),
          ),
          _buildFeedbackPopup(context),
        ],
      ),
    );
  }

  Widget _buildCardLeitura(BuildContext context, AppLocalizations t, bool lendo, StatusCadastroNFC status, String? erro, NotificadorCadastroNFC notifier) {
    IconData icone = Icons.nfc;
    Color corIcone = Colors.grey;
    String titulo = t.t('prof_presenca_nfc_pausada_titulo'); 
    String subtitulo = t.t('prof_presenca_nfc_pausada_desc'); 
    
    if (lendo) {
      icone = Icons.nfc; corIcone = Colors.green;
      titulo = t.t('prof_presenca_nfc_lendo_titulo'); 
      subtitulo = t.t('prof_presenca_nfc_lendo_desc'); 
    } else if (status == StatusCadastroNFC.error) {
      icone = Icons.error_outline; corIcone = Colors.red;
      titulo = t.t('prof_presenca_nfc_erro_titulo'); 
      subtitulo = erro ?? t.t('prof_presenca_nfc_erro_desc'); 
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
            Text(subtitulo, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(lendo ? Icons.pause : Icons.play_arrow),
              label: Text(lendo ? t.t('prof_presenca_nfc_pausar') : t.t('prof_presenca_nfc_iniciar')),
              style: ElevatedButton.styleFrom(
                backgroundColor: lendo ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () {
                lendo ? notifier.pausarLeitura() : notifier.iniciarLeitura();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPresentes(BuildContext context, AppLocalizations t) {
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
                      '${t.t('prof_presenca_presentes')}: ${_listaVisual.length}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.green[800]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8), 
            ElevatedButton(
              onPressed: () {
                ref.read(provedorCadastroNFC.notifier).pausarLeitura();
                Navigator.pop(context);
              },
              child: Text(t.t('prof_presenca_nfc_finalizar')),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCardRegistrados(BuildContext context, AppLocalizations t) {
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
            if (_listaVisual.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_isLoading ? "Carregando..." : t.t('prof_presenca_nfc_vazio')),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _listaVisual.length,
                itemBuilder: (context, index) {
                  final aluno = _listaVisual[index];
                  return ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(aluno.nome),
                    subtitle: Text(aluno.ra),
                    trailing: Text(aluno.hora ?? "Presença"),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackPopup(BuildContext context) {
    bool mostrar = _ultimoSucesso != null || _ultimoErro != null;
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
          color: _ultimoErro != null ? Colors.red : Colors.green,
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_ultimoErro != null ? Icons.error : Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _ultimoSucesso ?? _ultimoErro ?? '',
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
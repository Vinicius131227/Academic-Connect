import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/evento_ca.dart';
import '../../models/participante_evento.dart';
import '../../models/atividade_evento.dart';
import '../../services/servico_firestore.dart';
import '../../themes/app_theme.dart';
import '../comum/widget_carregamento.dart';
import '../../l10n/app_localizations.dart';

// Provider temporário para gerenciar o estado local da tela (NFC e Lista)
// Em um app maior, isso ficaria em um arquivo separado.
final atividadeSelecionadaProvider = StateProvider.autoDispose<AtividadeEvento?>((ref) => null);

class TelaPresencaEvento extends ConsumerStatefulWidget {
  final EventoCA evento;
  const TelaPresencaEvento({super.key, required this.evento});

  @override
  ConsumerState<TelaPresencaEvento> createState() => _TelaPresencaEventoState();
}

class _TelaPresencaEventoState extends ConsumerState<TelaPresencaEvento> {
  List<AtividadeEvento> _atividades = [];
  List<ParticipanteEvento> _participantesVisuais = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // Carrega as atividades (palestras) do evento
  Future<void> _carregarDados() async {
    final servico = ref.read(servicoFirestoreProvider);
    
    // Stream de atividades
    final stream = servico.getAtividadesEvento(widget.evento.id);
    stream.listen((atividades) {
      if (mounted) {
        setState(() {
          _atividades = atividades;
          // Seleciona a primeira por padrão se nada estiver selecionado
          if (_atividades.isNotEmpty && ref.read(atividadeSelecionadaProvider) == null) {
            ref.read(atividadeSelecionadaProvider.notifier).state = _atividades.first;
            _carregarParticipantes(_atividades.first);
          } else if (_atividades.isEmpty) {
            _isLoading = false;
          }
        });
      }
    });
  }

  // Carrega a lista de alunos para mostrar na tela
  Future<void> _carregarParticipantes(AtividadeEvento atividade) async {
    setState(() => _isLoading = true);
    final servico = ref.read(servicoFirestoreProvider);
    
    List<ParticipanteEvento> listaVisual = [];

    // Se não tiver ninguém inscrito no evento pai, a lista é vazia
    if (widget.evento.participantesInscritos.isEmpty) {
       setState(() {
         _participantesVisuais = [];
         _isLoading = false;
       });
       return;
    }

    // Busca os dados de cada participante inscrito
    for (String uid in widget.evento.participantesInscritos) {
      final user = await servico.getUsuario(uid);
      if (user != null && user.alunoInfo != null) {
        listaVisual.add(ParticipanteEvento(
          id: uid,
          nome: user.alunoInfo!.nomeCompleto,
          ra: user.alunoInfo!.ra,
          // Marca como presente se o ID já estiver na lista da atividade
          isPresente: atividade.presentes.contains(uid),
        ));
      }
    }

    setState(() {
      _participantesVisuais = listaVisual;
      _isLoading = false;
    });
  }

  Future<void> _salvarPresenca() async {
    final atividade = ref.read(atividadeSelecionadaProvider);
    if (atividade == null) return;

    setState(() => _isSaving = true);
    
    // Filtra UIDs marcados
    final presentesUids = _participantesVisuais
        .where((p) => p.isPresente)
        .map((p) => p.id)
        .toList();

    try {
      await ref.read(servicoFirestoreProvider).registrarPresencaAtividade(
        widget.evento.id, 
        atividade.id, 
        presentesUids
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lista salva com sucesso!"), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final atividadeSelecionada = ref.watch(atividadeSelecionadaProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.evento.nome, 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)
        ),
        iconTheme: IconThemeData(color: textColor),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- SELETOR DE ATIVIDADE ---
          if (_atividades.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? Colors.black12 : Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Selecione a Atividade:", style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AtividadeEvento>(
                    value: atividadeSelecionada,
                    dropdownColor: cardColor,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: cardColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: _atividades.map((atv) => DropdownMenuItem(
                      value: atv,
                      child: Text(atv.nome, style: TextStyle(color: textColor)),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) {
                         ref.read(atividadeSelecionadaProvider.notifier).state = v;
                         _carregarParticipantes(v);
                      }
                    },
                  ),
                ],
              ),
            )
          else if (!_isLoading)
             Padding(
               padding: const EdgeInsets.all(32.0),
               child: Center(child: Text("Nenhuma atividade cadastrada neste evento.", style: TextStyle(color: textColor))),
             ),

          // --- LISTA DE ALUNOS ---
          Expanded(
            child: _isLoading 
              ? const WidgetCarregamento(texto: "Carregando lista...")
              : _participantesVisuais.isEmpty
                  ? Center(child: Text("Nenhum inscrito no evento.", style: TextStyle(color: textColor)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _participantesVisuais.length,
                      itemBuilder: (context, index) {
                        final p = _participantesVisuais[index];
                        return Card(
                          color: cardColor,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: CheckboxListTile(
                            activeColor: AppColors.primaryPurple,
                            title: Text(p.nome, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                            subtitle: Text("RA: ${p.ra}", style: TextStyle(color: textColor?.withOpacity(0.7))),
                            value: p.isPresente,
                            onChanged: (val) {
                              setState(() {
                                p.isPresente = val ?? false;
                              });
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      
      // Botão Flutuante Salvar
      floatingActionButton: _atividades.isNotEmpty ? FloatingActionButton.extended(
        onPressed: _isSaving ? null : _salvarPresenca,
        backgroundColor: AppColors.primaryPurple,
        icon: _isSaving 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : const Icon(Icons.save, color: Colors.white),
        label: Text(_isSaving ? "Salvando..." : "Salvar Presença", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }
}
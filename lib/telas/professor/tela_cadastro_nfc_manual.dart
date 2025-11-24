// lib/telas/professor/tela_cadastro_nfc_manual.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/turma_professor.dart';
import '../../models/aluno_chamada.dart';
import '../../providers/provedor_professor.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../comum/widget_carregamento.dart';

class TelaCadastroNfcManual extends ConsumerStatefulWidget {
  final TurmaProfessor turma;
  const TelaCadastroNfcManual({super.key, required this.turma});

  @override
  ConsumerState<TelaCadastroNfcManual> createState() =>
      _TelaCadastroNfcManualState();
}

class _TelaCadastroNfcManualState extends ConsumerState<TelaCadastroNfcManual> {
  final _formKey = GlobalKey<FormState>();
  final _nfcIdController = TextEditingController();
  AlunoChamada? _alunoSelecionado;
  bool _isLoading = false;

  @override
  void dispose() {
    _nfcIdController.dispose();
    super.dispose();
  }

  Future<void> _salvarCartao() async {
    if (!_formKey.currentState!.validate() || _alunoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um aluno e insira o ID.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final t = AppLocalizations.of(context)!;

    try {
      // Formata o ID para o padrão de armazenamento (Ex: 04:A1:B2:C3:D4:E5)
      final nfcIdFormatado = _nfcIdController.text.replaceAll(' ', ':').toUpperCase();
      
      // Chama o serviço para salvar o cartão no documento do aluno
      await ref.read(servicoFirestoreProvider).salvarCartaoNFC(
            _alunoSelecionado!.id, // UID do aluno
            nfcIdFormatado,        // ID do cartão
          );
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.t('nfc_manual_sucesso')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
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
    // Observa o provedor de alunos da turma
    final estadoAlunos = ref.watch(provedorChamadaManual(widget.turma.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('nfc_manual_titulo')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.turma.nome, style: Theme.of(context).textTheme.titleLarge),
                  const Divider(height: 24),
                  
                  // Bloco de Seleção de Aluno (Baseado no status de carregamento)
                  switch (estadoAlunos.status) {
                    StatusChamadaManual.ocioso || StatusChamadaManual.carregando =>
                      const WidgetCarregamento(texto: 'Carregando alunos...'),
                      
                    StatusChamadaManual.erro =>
                      const Center(child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Erro ao carregar lista de alunos.'),
                      )),
                      
                    StatusChamadaManual.pronto =>
                      DropdownButtonFormField<AlunoChamada>(
                        value: _alunoSelecionado,
                        hint: Text(t.t('nfc_manual_selecionar_aluno')),
                        decoration: InputDecoration(
                          labelText: t.t('nfc_manual_selecionar_aluno'),
                          border: const OutlineInputBorder(),
                        ),
                        items: estadoAlunos.alunos.map((aluno) {
                          return DropdownMenuItem<AlunoChamada>(
                            value: aluno,
                            child: Text('${aluno.nome} (${aluno.ra})'),
                          );
                        }).toList(),
                        onChanged: (aluno) {
                          setState(() => _alunoSelecionado = aluno);
                        },
                        validator: (v) => v == null ? 'Campo obrigatório' : null,
                      )
                  },

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nfcIdController,
                    decoration: InputDecoration(
                      labelText: t.t('nfc_manual_id_cartao'),
                      hintText: 'Ex: 04:A1:B2:C3:D4:E5',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: _isLoading
                        ? Container(width: 20, height: 20, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Salvando...' : t.t('nfc_manual_salvar')),
                    onPressed: _isLoading ? null : _salvarCartao,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
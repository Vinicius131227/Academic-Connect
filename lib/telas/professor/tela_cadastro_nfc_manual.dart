// lib/telas/professor/tela_cadastro_nfc_manual.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/turma_professor.dart';
import '../../models/aluno_chamada.dart'; 
import '../../providers/provedor_professor.dart';
import '../../providers/provedor_aluno.dart'; // Importante: Reutiliza a lógica de leitura de cartão
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart'; 
import '../comum/widget_carregamento.dart'; 
import '../../themes/app_theme.dart';

@UseCase(
  name: 'Cadastro NFC Manual (Prof)',
  type: TelaCadastroNfcManual,
)
Widget buildTelaCadastroNfcManual(BuildContext context) {
  return ProviderScope(
    child: TelaCadastroNfcManual(
      turma: TurmaProfessor(
        id: 'mock', nome: 'Cálculo 1', horario: '', local: '', professorId: '', turmaCode: '', creditos: 4, alunosInscritos: []
      ),
    ),
  );
}

class TelaCadastroNfcManual extends ConsumerStatefulWidget {
  final TurmaProfessor turma;
  const TelaCadastroNfcManual({super.key, required this.turma});

  @override
  ConsumerState<TelaCadastroNfcManual> createState() => _TelaCadastroNfcManualState();
}

class _TelaCadastroNfcManualState extends ConsumerState<TelaCadastroNfcManual> {
  final _formKey = GlobalKey<FormState>();
  final _nfcIdController = TextEditingController();
  
  AlunoChamada? _alunoSelecionado;
  bool _isLoading = false;

  @override
  void dispose() {
    _nfcIdController.dispose();
    // É boa prática parar a leitura se sair da tela
    // ref.read(provedorCadastroNFC.notifier).reset(); // Não podemos chamar ref aqui no dispose
    super.dispose();
  }

  Future<void> _salvarCartao() async {
    if (!_formKey.currentState!.validate() || _alunoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um aluno e insira o ID.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    final t = AppLocalizations.of(context)!;

    try {
      final nfcIdFormatado = _nfcIdController.text.replaceAll(' ', ':').toUpperCase();
      
      await ref.read(servicoFirestoreProvider).salvarCartaoNFC(
            _alunoSelecionado!.id, 
            nfcIdFormatado,        
          );
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('nfc_manual_sucesso')), backgroundColor: Colors.green),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final estadoAlunos = ref.watch(provedorChamadaManual(widget.turma.id));
    
    // Observa o estado do leitor NFC (reutilizando do aluno)
    final estadoNFC = ref.watch(provedorCadastroNFC);
    final notifierNFC = ref.read(provedorCadastroNFC.notifier);

    // Listener: Se ler um cartão com sucesso, preenche o campo
    ref.listen(provedorCadastroNFC, (previous, next) {
      if (next.status == StatusCadastroNFC.success && next.uid != null) {
         _nfcIdController.text = next.uid!;
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Cartão lido!"), backgroundColor: Colors.green)
         );
         // Para a leitura após sucesso para economizar bateria
         notifierNFC.reset();
      }
      if (next.status == StatusCadastroNFC.error && next.erro != null) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Erro na leitura: ${next.erro}"), backgroundColor: Colors.red)
         );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(t.t('nfc_manual_titulo'))),
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
                  
                  // 1. Seleção de Aluno
                  if (estadoAlunos.status == StatusChamadaManual.carregando)
                      const WidgetCarregamento(texto: 'Carregando alunos...')
                  else if (estadoAlunos.status == StatusChamadaManual.erro)
                      const Center(child: Text('Erro ao carregar lista.'))
                  else
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
                        onChanged: (aluno) => setState(() => _alunoSelecionado = aluno),
                        validator: (v) => v == null ? 'Campo obrigatório' : null,
                      ),

                  const SizedBox(height: 24),
                  
                  // 2. Campo de ID do Cartão + Botão de Leitura
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Alinha no topo se der erro de validação
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nfcIdController,
                          decoration: InputDecoration(
                            labelText: t.t('nfc_manual_id_cartao'),
                            hintText: '04:A1:B2...',
                            border: const OutlineInputBorder(),
                            // Adiciona ícone indicador se estiver lendo
                            suffixIcon: estadoNFC.status == StatusCadastroNFC.scanning 
                                ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)) 
                                : null
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                          enabled: !_isLoading,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Botão "Ler Cartão"
                      SizedBox(
                        height: 56, // Altura padrão do input para alinhar
                        child: ElevatedButton(
                          onPressed: (estadoNFC.status == StatusCadastroNFC.scanning) 
                              ? null // Desabilita se já estiver lendo
                              : () => notifierNFC.iniciarLeitura(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          child: const Icon(Icons.nfc),
                        ),
                      ),
                    ],
                  ),
                  
                  // Aviso se estiver lendo
                  if (estadoNFC.status == StatusCadastroNFC.scanning)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        t.t('nfc_cadastro_instrucao'), // "Aproxime o cartão"
                        style: const TextStyle(color: AppColors.primaryPurple, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 32),
                  
                  // 3. Botão Salvar
                  ElevatedButton.icon(
                    icon: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
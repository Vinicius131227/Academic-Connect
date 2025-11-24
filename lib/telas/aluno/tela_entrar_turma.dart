import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../comum/overlay_carregamento.dart';

class TelaEntrarTurma extends ConsumerStatefulWidget {
  const TelaEntrarTurma({super.key});

  @override
  ConsumerState<TelaEntrarTurma> createState() => _TelaEntrarTurmaState();
}

class _TelaEntrarTurmaState extends ConsumerState<TelaEntrarTurma> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  
  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _entrarNaTurma() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final alunoUid = ref.read(provedorNotificadorAutenticacao).usuario?.uid;
    if (alunoUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Aluno não autenticado.'), backgroundColor: Colors.red),
      );
      return;
    }

    ref.read(provedorCarregando.notifier).state = true;
    final t = AppLocalizations.of(context)!;
    
    try {
      final codigo = _codeController.text.trim().toUpperCase();
      // Chama o serviço do Firestore para tentar entrar na turma
      await ref.read(servicoFirestoreProvider).entrarNaTurma(codigo, alunoUid);

      if (mounted) {
        ref.read(provedorCarregando.notifier).state = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('entrar_turma_sucesso')), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Volta para a tela de disciplinas
      }
    } catch (e) {
      if (mounted) {
        ref.read(provedorCarregando.notifier).state = false;
        // Exibe o erro específico do Firebase (ex: "Código não encontrado")
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final estaCarregando = ref.watch(provedorCarregando);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('entrar_turma_titulo')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _codeController,
                autocorrect: false,
                // Força letras maiúsculas
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: t.t('entrar_turma_label'),
                  hintText: t.t('entrar_turma_hint'),
                  border: const OutlineInputBorder(),
                  counterText: "", // Esconde o contador de caracteres
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo obrigatório';
                  if (v.length != 6) return 'O código deve ter 6 caracteres';
                  return null;
                },
                maxLength: 6,
                enabled: !estaCarregando,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: estaCarregando 
                  ? Container(width: 20, height: 20, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.login),
                label: Text(estaCarregando ? 'Verificando...' : t.t('entrar_turma_botao')), 
                onPressed: estaCarregando ? null : _entrarNaTurma,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
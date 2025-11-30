// lib/telas/aluno/tela_entrar_turma.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../providers/provedor_autenticacao.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart'; // Traduções
import '../comum/overlay_carregamento.dart'; // Loading global

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Entrar na Turma',
  type: TelaEntrarTurma,
)
Widget buildTelaEntrarTurma(BuildContext context) {
  return const ProviderScope(
    child: TelaEntrarTurma(),
  );
}

/// Tela onde o aluno insere o código da disciplina para se matricular.
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

  /// Tenta realizar a matrícula do aluno na turma.
  Future<void> _entrarNaTurma() async {
    // 1. Validação local
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // 2. Obtém ID do aluno logado
    final alunoUid = ref.read(provedorNotificadorAutenticacao).usuario?.uid;
    if (alunoUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Aluno não autenticado.'), backgroundColor: Colors.red),
      );
      return;
    }

    // 3. Inicia carregamento
    ref.read(provedorCarregando.notifier).state = true;
    final t = AppLocalizations.of(context)!;
    
    try {
      final codigo = _codeController.text.trim().toUpperCase();
      
      // 4. Chama o serviço do Firestore
      await ref.read(servicoFirestoreProvider).entrarNaTurma(codigo, alunoUid);

      if (mounted) {
        ref.read(provedorCarregando.notifier).state = false;
        
        // 5. Sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('entrar_turma_sucesso')), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Volta para a lista de disciplinas
      }
    } catch (e) {
      if (mounted) {
        ref.read(provedorCarregando.notifier).state = false;
        
        // 6. Erro (Código inválido ou já inscrito)
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('entrar_turma_titulo')), // "Entrar na Turma"
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Texto de instrução
              Text(
                "Digite o código de 6 caracteres fornecido pelo professor.",
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 24),

              // Campo de Código
              TextFormField(
                controller: _codeController,
                autocorrect: false,
                // Força teclado em maiúsculas
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: t.t('entrar_turma_label'), // "Código da Turma"
                  hintText: t.t('entrar_turma_hint'),   // "Insira o código..."
                  border: const OutlineInputBorder(),
                  counterText: "", // Esconde contador "0/6"
                  prefixIcon: const Icon(Icons.vpn_key),
                ),
                // Filtra para aceitar apenas letras e números
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo obrigatório';
                  if (v.length != 6) return 'O código deve ter exatos 6 caracteres';
                  return null;
                },
                maxLength: 6,
                enabled: !estaCarregando,
              ),
              
              const SizedBox(height: 24),
              
              // Botão de Ação
              ElevatedButton.icon(
                icon: estaCarregando 
                  ? Container(width: 20, height: 20, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.login),
                label: Text(estaCarregando ? 'Verificando...' : t.t('entrar_turma_botao')), 
                onPressed: estaCarregando ? null : _entrarNaTurma,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  // Usa a cor primária do tema
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
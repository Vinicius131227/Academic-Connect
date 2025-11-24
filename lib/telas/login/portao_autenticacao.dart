// lib/telas/login/portao_autenticacao.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provedor_autenticacao.dart';
import 'tela_login.dart';
import '../aluno/tela_principal_aluno.dart';
import '../professor/tela_principal_professor.dart';
import '../ca_projeto/tela_principal_ca_projeto.dart';
import '../comum/widget_carregamento.dart';
// --- NOVO IMPORTE ---
import 'tela_cadastro_usuario.dart'; 
// --- FIM NOVO IMPORTE ---

/// O PortaoAutenticacao é o primeiro widget "inteligente" do app.
class PortaoAutenticacao extends ConsumerWidget {
  const PortaoAutenticacao({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoAuth = ref.watch(provedorNotificadorAutenticacao);

    switch (estadoAuth.status) {
      case StatusAutenticacao.desconhecido:
        return const TelaCarregamento();

      case StatusAutenticacao.naoAutenticado:
        return const TelaLogin();

      case StatusAutenticacao.autenticado:
        // Verifica se o usuário já definiu seu papel (aluno, professor, etc.)
        if (estadoAuth.usuario!.papel.isEmpty) {
          // Se o papel estiver vazio (primeiro login via Google),
          // força a ir para a tela de cadastro para escolher o papel e preencher dados.
          return const TelaCadastroUsuario(isInitialSetup: true);
        } else {
          // Se o papel já foi definido, direciona para o dashboard correto
          switch (estadoAuth.usuario!.papel) {
            case 'aluno':
              return const TelaPrincipalAluno();
            case 'professor':
              return const TelaPrincipalProfessor();
            case 'ca_projeto':
              return const TelaPrincipalCAProjeto();
            default:
              // Caso de segurança: se o papel for inválido, manda para o login
              return const TelaLogin();
          }
        }
    }
  }
}
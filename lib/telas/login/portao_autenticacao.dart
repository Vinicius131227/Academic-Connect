import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../providers/provedor_onboarding.dart';
import 'tela_login.dart';
import '../aluno/tela_principal_aluno.dart';
import '../professor/tela_principal_professor.dart';
import '../comum/widget_carregamento.dart';
import '../comum/tela_onboarding.dart';
import 'tela_cadastro_usuario.dart';

class PortaoAutenticacao extends ConsumerWidget {
  const PortaoAutenticacao({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Onboarding
    final onboardingVisto = ref.watch(provedorOnboarding);
    if (!onboardingVisto) {
      return const TelaOnboarding();
    }

    // 2. Autenticação
    final estadoAuth = ref.watch(provedorNotificadorAutenticacao);

    switch (estadoAuth.status) {
      case StatusAutenticacao.desconhecido:
        return const Scaffold(body: WidgetCarregamento());

      case StatusAutenticacao.naoAutenticado:
        return const TelaLogin();

      case StatusAutenticacao.autenticado:
        if (estadoAuth.usuario!.papel.isEmpty) {
          return const TelaCadastroUsuario(isInitialSetup: true);
        } else {
          switch (estadoAuth.usuario!.papel) {
            case 'aluno':
              return const TelaPrincipalAluno();
            case 'professor':
              return const TelaPrincipalProfessor();
            // CA REMOVIDO
            default:
              return const TelaLogin();
          }
        }
    }
  }
}
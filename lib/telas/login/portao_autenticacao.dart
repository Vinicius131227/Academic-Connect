// lib/telas/login/portao_autenticacao.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importação dos Provedores de Estado
import '../../providers/provedor_autenticacao.dart';
import '../../providers/provedor_onboarding.dart';

// Importação das Telas de Destino
import 'tela_login.dart';
import '../aluno/tela_principal_aluno.dart';
import '../professor/tela_principal_professor.dart';
import '../ca_projeto/tela_principal_ca_projeto.dart';
import '../comum/widget_carregamento.dart';
import '../comum/tela_onboarding.dart';
import 'tela_cadastro_usuario.dart';

/// Widget que gerencia o fluxo de navegação inicial do aplicativo.
///
/// Ele observa dois estados principais:
/// 1. [provedorOnboarding]: Se é a primeira vez que o usuário abre o app.
/// 2. [provedorNotificadorAutenticacao]: Se o usuário está logado e qual seu papel.
class PortaoAutenticacao extends ConsumerWidget {
  const PortaoAutenticacao({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Verifica se o usuário já viu o tutorial de boas-vindas (Onboarding)
    final onboardingVisto = ref.watch(provedorOnboarding);
    
    // Se ainda não viu, mostra o Onboarding primeiro.
    if (!onboardingVisto) {
      return const TelaOnboarding();
    }

    // 2. Verifica o estado da Autenticação (Firebase Auth + Firestore)
    final estadoAuth = ref.watch(provedorNotificadorAutenticacao);

    // Decide qual tela mostrar com base no status
    switch (estadoAuth.status) {
      
      // Ainda carregando ou verificando o token
      case StatusAutenticacao.desconhecido:
        return const Scaffold(
          body: WidgetCarregamento(texto: "Iniciando..."),
        );

      // Usuário não está logado
      case StatusAutenticacao.naoAutenticado:
        return const TelaLogin();

      // Usuário está logado
      case StatusAutenticacao.autenticado:
        // Verifica se o cadastro está completo (tem papel definido)
        // Isso acontece no primeiro login com Google, onde o papel ainda é vazio.
        if (estadoAuth.usuario!.papel.isEmpty) {
          return const TelaCadastroUsuario(isInitialSetup: true);
        } else {
          // Redireciona para a Home específica de cada perfil
          switch (estadoAuth.usuario!.papel) {
            case 'aluno':
              return const TelaPrincipalAluno();
            case 'professor':
              return const TelaPrincipalProfessor();
            case 'ca_projeto':
              return const TelaPrincipalCAProjeto();
            default:
              // Se o papel for desconhecido, manda para o Login por segurança
              return const TelaLogin();
          }
        }
    }
  }
}
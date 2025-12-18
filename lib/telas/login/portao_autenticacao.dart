// lib/telas/login/portao_autenticacao.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/provedor_autenticacao.dart';
import '../../providers/provedor_onboarding.dart';
import 'tela_login.dart';
import 'tela_cadastro_usuario.dart'; 
import '../aluno/tela_principal_aluno.dart';
import '../professor/tela_principal_professor.dart';
import '../comum/widget_carregamento.dart';
import '../comum/tela_onboarding.dart';

class PortaoAutenticacao extends ConsumerWidget {
  const PortaoAutenticacao({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Verifica se o Onboarding já foi visto
    final onboardingVisto = ref.watch(provedorOnboarding);
    if (!onboardingVisto) {
      return const TelaOnboarding();
    }

    // 2. Observa o estado da Autenticação
    final estadoAuth = ref.watch(provedorNotificadorAutenticacao);

    // 3. Gerencia o fluxo de telas
    switch (estadoAuth.status) {
      
      // CASO 1: Ainda não sabemos (Iniciando App)
      case StatusAutenticacao.desconhecido:
        return const Scaffold(
          body: WidgetCarregamento(texto: "Iniciando..."),
        );

      // CASO 2: Não logado
      case StatusAutenticacao.naoAutenticado:
        return const TelaLogin();

      // CASO 3: Usuário Logado
      case StatusAutenticacao.autenticado:
        final usuario = estadoAuth.usuario;

        // Proteção: Se o status é autenticado, mas o objeto usuário ainda não carregou
        // (Isso evita a tela preta ou erro de null check)
        if (usuario == null) {
          return const Scaffold(
            body: WidgetCarregamento(texto: "Validando sessão..."),
          );
        }

        // Se o usuário não tem 'papel' (Aluno ou Professor) definido no banco
        // Isso acontece no primeiro login com Google
        if (usuario.papel.isEmpty) {
          return const TelaCadastroUsuario(isInitialSetup: true);
        } 
        
        // Se já tem papel definido, direciona para a área correta
        else {
          switch (usuario.papel) {
            case 'aluno':
            //Chama a TELA PRINCIPAL (com abas), não a ABA isolada.
              return const TelaPrincipalAluno(); 
            
            case 'professor':
              return const TelaPrincipalProfessor();
            
            default:
              // Se o papel for inválido, volta pro login por segurança
              return const TelaLogin();
          }
        }
    }
  }
}
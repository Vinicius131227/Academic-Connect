// lib/widgetbook/use_cases.dart
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Imports das telas
import '../telas/login/tela_login.dart';
import '../telas/login/tela_cadastro_usuario.dart';
import '../telas/comum/tela_onboarding.dart';
import '../telas/comum/tela_configuracoes.dart';
import '../telas/aluno/tela_principal_aluno.dart';
import '../telas/professor/tela_principal_professor.dart';
import '../telas/comum/widget_carregamento.dart';

// --- COMPONENTES PEQUENOS ---

@UseCase(name: 'Loading Padrão', type: WidgetCarregamento)
Widget buildLoading(BuildContext context) {
  return const Center(child: WidgetCarregamento(texto: 'Carregando dados...'));
}

// --- TELAS DE AUTENTICAÇÃO ---

@UseCase(name: 'Tela de Login', type: TelaLogin)
Widget buildTelaLogin(BuildContext context) {
  // Envolvemos em ProviderScope para o Riverpod funcionar
  return const ProviderScope(
    child: TelaLogin(),
  );
}

@UseCase(name: 'Tela de Cadastro', type: TelaCadastroUsuario)
Widget buildTelaCadastro(BuildContext context) {
  return const ProviderScope(
    child: TelaCadastroUsuario(isInitialSetup: false),
  );
}

@UseCase(name: 'Onboarding', type: TelaOnboarding)
Widget buildOnboarding(BuildContext context) {
  return const ProviderScope(
    child: TelaOnboarding(),
  );
}

// --- TELAS PRINCIPAIS (O "Todo" do Aplicativo) ---

@UseCase(name: 'Home do Aluno', type: TelaPrincipalAluno)
Widget buildHomeAluno(BuildContext context) {
  return const ProviderScope(
    child: TelaPrincipalAluno(),
  );
}

@UseCase(name: 'Home do Professor', type: TelaPrincipalProfessor)
Widget buildHomeProfessor(BuildContext context) {
  return const ProviderScope(
    child: TelaPrincipalProfessor(),
  );
}

@UseCase(name: 'Configurações', type: TelaConfiguracoes)
Widget buildConfiguracoes(BuildContext context) {
  return const ProviderScope(
    child: TelaConfiguracoes(),
  );
}
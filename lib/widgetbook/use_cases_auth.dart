// lib/widgetbook/use_cases_auth.dart

import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importações das Telas
import '../telas/login/tela_login.dart';
import '../telas/login/tela_cadastro_usuario.dart';
import '../telas/login/tela_esqueceu_senha.dart';
import '../telas/login/portao_autenticacao.dart';
import '../telas/comum/tela_onboarding.dart';

/// Lista de componentes de Autenticação para o Widgetbook.
List<WidgetbookComponent> get authUseCases => [
  
  // 1. Portão de Autenticação (Gatekeeper)
  WidgetbookComponent(
    name: 'Portão (Gatekeeper)',
    useCases: [
      WidgetbookUseCase(
        name: 'Fluxo Inicial',
        builder: (context) => const ProviderScope(child: PortaoAutenticacao()),
      ),
    ],
  ),

  // 2. Tela de Login
  WidgetbookComponent(
    name: 'Login',
    useCases: [
      WidgetbookUseCase(
        name: 'Padrão',
        builder: (context) => const ProviderScope(child: TelaLogin()),
      ),
    ],
  ),

  // 3. Tela de Cadastro
  WidgetbookComponent(
    name: 'Cadastro',
    useCases: [
      WidgetbookUseCase(
        name: 'Novo Usuário',
        builder: (context) => const ProviderScope(child: TelaCadastroUsuario()),
      ),
      WidgetbookUseCase(
        name: 'Completar Cadastro (Google)',
        builder: (context) => const ProviderScope(
          child: TelaCadastroUsuario(isInitialSetup: true)
        ),
      ),
    ],
  ),

  // 4. Recuperação de Senha
  WidgetbookComponent(
    name: 'Recuperação de Senha',
    useCases: [
      WidgetbookUseCase(
        name: 'Esqueceu Senha',
        builder: (context) => const ProviderScope(child: TelaEsqueceuSenha()),
      ),
    ],
  ),

  // 5. Onboarding (Boas-vindas)
  WidgetbookComponent(
    name: 'Onboarding',
    useCases: [
      WidgetbookUseCase(
        name: 'Slides de Introdução',
        builder: (context) => const ProviderScope(child: TelaOnboarding()),
      ),
    ],
  ),
];
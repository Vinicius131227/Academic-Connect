// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:ddm_projeto_final/telas/comum/cartao_vidro.dart'
    as _ddm_projeto_final_telas_comum_cartao_vidro;
import 'package:ddm_projeto_final/widgetbook/use_cases.dart'
    as _ddm_projeto_final_widgetbook_use_cases;
import 'package:widgetbook/widgetbook.dart' as _widgetbook;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookFolder(
    name: 'telas',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'aluno',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'TelaPrincipalAluno',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Home do Aluno',
                builder: _ddm_projeto_final_widgetbook_use_cases.buildHomeAluno,
              )
            ],
          )
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'comum',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CartaoVidro',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Padrão',
                builder: _ddm_projeto_final_telas_comum_cartao_vidro
                    .buildCartaoVidro,
              )
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'TelaConfiguracoes',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Configurações',
                builder:
                    _ddm_projeto_final_widgetbook_use_cases.buildConfiguracoes,
              )
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'TelaOnboarding',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Onboarding',
                builder:
                    _ddm_projeto_final_widgetbook_use_cases.buildOnboarding,
              )
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'WidgetCarregamento',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Loading Padrão',
                builder: _ddm_projeto_final_widgetbook_use_cases.buildLoading,
              )
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'login',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'TelaCadastroUsuario',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Tela de Cadastro',
                builder:
                    _ddm_projeto_final_widgetbook_use_cases.buildTelaCadastro,
              )
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'TelaLogin',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Tela de Login',
                builder: _ddm_projeto_final_widgetbook_use_cases.buildTelaLogin,
              )
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'professor',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'TelaPrincipalProfessor',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Home do Professor',
                builder:
                    _ddm_projeto_final_widgetbook_use_cases.buildHomeProfessor,
              )
            ],
          )
        ],
      ),
    ],
  )
];

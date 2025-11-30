import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações das telas internas (Abas)
import 'aba_inicio_ca.dart';
import 'aba_perfil_ca.dart';

// Importações de configuração e tema
import '../comum/tela_configuracoes.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';

/// Caso de uso para o Widgetbook.
/// Permite visualizar a estrutura principal da navegação do C.A.
@UseCase(
  name: 'Principal CA (Navegação)',
  type: TelaPrincipalCAProjeto,
)
Widget buildTelaPrincipalCA(BuildContext context) {
  return const ProviderScope(
    child: TelaPrincipalCAProjeto(),
  );
}

/// Tela Principal para usuários do tipo "Centro Acadêmico" ou "Projeto".
///
/// Responsável por:
/// 1. Gerenciar a navegação inferior ([BottomNavigationBar]).
/// 2. Alternar entre o Dashboard de Eventos e o Perfil.
/// 3. Fornecer acesso às configurações globais via AppBar.
class TelaPrincipalCAProjeto extends ConsumerStatefulWidget {
  const TelaPrincipalCAProjeto({super.key});

  @override
  ConsumerState<TelaPrincipalCAProjeto> createState() => _TelaPrincipalCAProjetoState();
}

class _TelaPrincipalCAProjetoState extends ConsumerState<TelaPrincipalCAProjeto> {
  /// Índice da aba atualmente selecionada (0 = Início, 1 = Perfil).
  int _indiceAtual = 0;

  /// Lista de widgets que representam as páginas.
  /// Usamos 'const' para evitar reconstruções desnecessárias.
  final List<Widget> _telas = [
    const AbaInicioCA(), // Dashboard com métricas e ações
    const AbaPerfilCA(), // Perfil e ajustes
  ];

  /// Função chamada ao tocar em um item da barra de navegação.
  void _onTabTapped(int index) {
    setState(() {
      _indiceAtual = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Acesso às traduções
    final t = AppLocalizations.of(context)!;
    
    // Acesso ao tema atual para garantir consistência visual (Claro/Escuro)
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final isDark = theme.brightness == Brightness.dark;

    // Títulos dinâmicos para a AppBar dependendo da aba selecionada
    final List<String> _titulos = [
      t.t('ca_titulo'),    // "Portal C.A."
      t.t('perfil_titulo'), // "Perfil"
    ];

    return Scaffold(
      // Garante que o fundo siga a cor definida no AppTheme (Branco ou Preto)
      backgroundColor: theme.scaffoldBackgroundColor,
      
      // --- APP BAR SUPERIOR ---
      appBar: AppBar(
        // Título muda conforme a aba
        title: Text(
          _titulos[_indiceAtual],
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.transparent, // Fundo transparente moderno
        elevation: 0, // Sem sombra
        actions: [
          // Botão de Configurações (Engrenagem)
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: textColor?.withOpacity(0.05), // Fundo sutil no botão
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.settings_outlined, color: textColor),
              tooltip: t.t('config_titulo'),
              onPressed: () {
                // Navega para a tela de configurações gerais
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const TelaConfiguracoes()),
                );
              },
            ),
          ),
        ],
      ),
      
      // --- CORPO DA TELA ---
      // IndexedStack preserva o estado das abas (não recarrega ao trocar)
      body: IndexedStack(
        index: _indiceAtual,
        children: _telas,
      ),
      
      // --- BARRA DE NAVEGAÇÃO INFERIOR ---
      bottomNavigationBar: Container(
        // Adiciona uma borda sutil no topo para separar do conteúdo (especialmente no modo claro)
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white10 : Colors.black12, 
              width: 1
            )
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _indiceAtual,
          onTap: _onTabTapped,
          backgroundColor: theme.scaffoldBackgroundColor,
          
          // Cores dos ícones
          selectedItemColor: AppColors.primaryPurple, // Roxo quando ativo
          unselectedItemColor: Colors.grey, // Cinza quando inativo
          
          // Estilo minimalista: sem labels (texto) embaixo dos ícones
          showSelectedLabels: false, 
          showUnselectedLabels: false,
          iconSize: 28,
          type: BottomNavigationBarType.fixed,
          
          items: [
            // Aba 0: Início (Dashboard)
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard),
              label: t.t('nav_inicio'),
            ),
            // Aba 1: Perfil
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: t.t('perfil_titulo'),
            ),
          ],
        ),
      ),
    );
  }
}
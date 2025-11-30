// lib/telas/comum/tela_configuracoes.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../providers/provedor_autenticacao.dart';
import '../../themes/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/provedor_tema.dart';
import '../../providers/provedor_localizacao.dart';

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Tela de Configurações',
  type: TelaConfiguracoes,
)
Widget buildTelaConfiguracoes(BuildContext context) {
  return const ProviderScope(
    child: TelaConfiguracoes(),
  );
}

/// Tela de Configurações Gerais do Aplicativo.
/// Permite:
/// - Trocar Tema (Claro/Escuro/Sistema).
/// - Trocar Idioma (PT/EN/ES).
/// - Fazer Logout.
class TelaConfiguracoes extends ConsumerWidget {
  const TelaConfiguracoes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    // Dados do usuário para o cabeçalho
    final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;
    final nome = usuario?.alunoInfo?.nomeCompleto ?? 'Usuário';
    
    // Estados atuais de Tema e Idioma
    final temaAtual = ref.watch(provedorNotificadorTema);
    final localeAtual = ref.watch(provedorLocalizacao);

    // Configuração visual baseada no tema atual
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    
    // Cores dos containers internos
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? Colors.transparent : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Botão de fechar (X)
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor), 
          onPressed: () => Navigator.pop(context)
        ),
        title: Text(
          t.t('config_titulo'), // "Configurações"
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // 1. Cabeçalho do Usuário (Mini Perfil)
            Row(
              children: [
                CircleAvatar(
                  radius: 30, 
                  backgroundColor: AppColors.primaryPurple, 
                  child: Text(
                    nome.isNotEmpty ? nome[0].toUpperCase() : 'U', 
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)
                  )
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    nome, 
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor), 
                    overflow: TextOverflow.ellipsis
                  )
                ),
              ],
            ),
            const SizedBox(height: 40),
            
            // 2. SEÇÃO DE TEMA
            _buildSectionTitle(t.t('config_secao_aparencia'), isDark),
            Container(
              decoration: BoxDecoration(
                color: cardColor, 
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(color: borderColor)
              ),
              child: Column(
                children: [
                  _buildRadioItem(
                    t.t('config_tema_claro'), 
                    temaAtual == ModoSistemaTema.claro, 
                    textColor, 
                    () => ref.read(provedorNotificadorTema.notifier).mudarTema(ModoSistemaTema.claro)
                  ),
                  Divider(height: 1, color: textColor?.withOpacity(0.1)),
                  _buildRadioItem(
                    t.t('config_tema_escuro'), 
                    temaAtual == ModoSistemaTema.escuro, 
                    textColor, 
                    () => ref.read(provedorNotificadorTema.notifier).mudarTema(ModoSistemaTema.escuro)
                  ),
                  Divider(height: 1, color: textColor?.withOpacity(0.1)),
                  _buildRadioItem(
                    t.t('config_tema_sistema'), // "Sistema"
                    temaAtual == ModoSistemaTema.sistema, 
                    textColor, 
                    () => ref.read(provedorNotificadorTema.notifier).mudarTema(ModoSistemaTema.sistema)
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // 3. SEÇÃO DE IDIOMA
            _buildSectionTitle(t.t('config_secao_idioma'), isDark),
            Container(
              decoration: BoxDecoration(
                color: cardColor, 
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(color: borderColor)
              ),
              child: Column(
                children: [
                  _buildRadioItem(
                    "Português", 
                    localeAtual.languageCode == 'pt', 
                    textColor, 
                    () => ref.read(provedorLocalizacao.notifier).mudarLingua('pt')
                  ),
                  Divider(height: 1, color: textColor?.withOpacity(0.1)),
                  _buildRadioItem(
                    "English", 
                    localeAtual.languageCode == 'en', 
                    textColor, 
                    () => ref.read(provedorLocalizacao.notifier).mudarLingua('en')
                  ),
                  Divider(height: 1, color: textColor?.withOpacity(0.1)),
                  _buildRadioItem(
                    "Español", 
                    localeAtual.languageCode == 'es', 
                    textColor, 
                    () => ref.read(provedorLocalizacao.notifier).mudarLingua('es')
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 4. BOTÃO DE LOGOUT
            TextButton.icon(
              onPressed: () {
                // Realiza o logout e limpa o histórico de navegação
                ref.read(provedorNotificadorAutenticacao.notifier).logout();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.power_settings_new, color: AppColors.error),
              label: Text(
                t.t('config_sair'), 
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.error)
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16), 
                alignment: Alignment.centerLeft
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper para títulos de seção
  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0), 
      child: Text(
        title, 
        style: GoogleFonts.poppins(
          color: isDark ? Colors.grey : Colors.grey[700], 
          fontWeight: FontWeight.bold, 
          fontSize: 12, 
          letterSpacing: 1.2
        )
      )
    );
  }

  // Helper para itens de seleção (Radio)
  Widget _buildRadioItem(String title, bool selected, Color? color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap, 
      title: Text(
        title, 
        style: GoogleFonts.poppins(color: color)
      ), 
      trailing: selected 
          ? const Icon(Icons.check_circle, color: AppColors.primaryPurple) 
          : const Icon(Icons.circle_outlined, color: Colors.grey)
    );
  }
}
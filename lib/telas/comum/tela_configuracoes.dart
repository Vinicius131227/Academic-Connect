// lib/telas/comum/tela_configuracoes.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../themes/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/provedor_tema.dart';
import '../../providers/provedor_localizacao.dart';
import 'tela_onboarding.dart';

class TelaConfiguracoes extends ConsumerWidget {
  const TelaConfiguracoes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;
    final nome = usuario?.alunoInfo?.nomeCompleto ?? 'Usuário';
    
    final temaAtual = ref.watch(provedorNotificadorTema);
    final localeAtual = ref.watch(provedorLocalizacao);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: AppColors.textWhite), onPressed: () => Navigator.pop(context)),
        title: Text(t.t('config_titulo'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (Cabeçalho do Perfil igual) ...
             const SizedBox(height: 40),
            
            // --- TEMA (Agora com opção Sistema) ---
            _buildSectionTitle(t.t('config_secao_aparencia')),
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildRadioItem(t.t('config_tema_claro'), temaAtual == ModoSistemaTema.claro, () => ref.read(provedorNotificadorTema.notifier).mudarTema(ModoSistemaTema.claro)),
                  const Divider(height: 1, color: Colors.white10),
                  _buildRadioItem(t.t('config_tema_escuro'), temaAtual == ModoSistemaTema.escuro, () => ref.read(provedorNotificadorTema.notifier).mudarTema(ModoSistemaTema.escuro)),
                  const Divider(height: 1, color: Colors.white10),
                  _buildRadioItem("Sistema", temaAtual == ModoSistemaTema.sistema, () => ref.read(provedorNotificadorTema.notifier).mudarTema(ModoSistemaTema.sistema)),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // --- IDIOMA ---
            _buildSectionTitle(t.t('config_secao_idioma')),
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildRadioItem("Português", localeAtual.languageCode == 'pt', () => ref.read(provedorLocalizacao.notifier).mudarLingua('pt')),
                  const Divider(height: 1, color: Colors.white10),
                  _buildRadioItem("English", localeAtual.languageCode == 'en', () => ref.read(provedorLocalizacao.notifier).mudarLingua('en')),
                  const Divider(height: 1, color: Colors.white10),
                  _buildRadioItem("Español", localeAtual.languageCode == 'es', () => ref.read(provedorLocalizacao.notifier).mudarLingua('es')),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Geral
            _buildSectionTitle(t.t('config_secao_geral')),
            _buildSettingItem(Icons.help_outline, t.t('config_ajuda'), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaOnboarding()))),
            
            const SizedBox(height: 40),
            
            // Logout
            TextButton.icon(
              onPressed: () {
                ref.read(provedorNotificadorAutenticacao.notifier).logout();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.power_settings_new, color: AppColors.error),
              label: Text(t.t('config_sair'), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.error)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), alignment: Alignment.centerLeft),
            ),
          ],
        ),
      ),
    );
  }
  
  // ... (Widgets auxiliares _buildSectionTitle, _buildRadioItem, _buildSettingItem mantidos iguais) ...
  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Text(title, style: GoogleFonts.poppins(color: AppColors.textGrey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)));
  }
  Widget _buildRadioItem(String title, bool selected, VoidCallback onTap) {
    return ListTile(onTap: onTap, title: Text(title, style: GoogleFonts.poppins(color: Colors.white)), trailing: selected ? const Icon(Icons.check_circle, color: AppColors.primaryPurple) : const Icon(Icons.circle_outlined, color: Colors.grey));
  }
  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(onTap: onTap, contentPadding: EdgeInsets.zero, leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppColors.textGrey)), title: Text(title, style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.w500)), trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14));
  }
}
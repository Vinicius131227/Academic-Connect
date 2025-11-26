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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.close, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text(t.t('config_titulo'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(radius: 30, backgroundColor: AppColors.primaryPurple, child: Text(nome.isNotEmpty ? nome[0].toUpperCase() : 'U', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))),
                const SizedBox(width: 16),
                Expanded(child: Text(nome, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 40),
            
            _buildSectionTitle(t.t('config_secao_aparencia')),
            Container(
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildRadioItem(t.t('config_tema_claro'), temaAtual == ModoSistemaTema.claro, textColor, () => ref.read(provedorNotificadorTema.notifier).mudarTema(ModoSistemaTema.claro)),
                  Divider(height: 1, color: textColor?.withOpacity(0.1)),
                  _buildRadioItem(t.t('config_tema_escuro'), temaAtual == ModoSistemaTema.escuro, textColor, () => ref.read(provedorNotificadorTema.notifier).mudarTema(ModoSistemaTema.escuro)),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            _buildSectionTitle(t.t('config_secao_idioma')),
            Container(
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildRadioItem("Português", localeAtual.languageCode == 'pt', textColor, () => ref.read(provedorLocalizacao.notifier).mudarLingua('pt')),
                  Divider(height: 1, color: textColor?.withOpacity(0.1)),
                  _buildRadioItem("English", localeAtual.languageCode == 'en', textColor, () => ref.read(provedorLocalizacao.notifier).mudarLingua('en')),
                  Divider(height: 1, color: textColor?.withOpacity(0.1)),
                  _buildRadioItem("Español", localeAtual.languageCode == 'es', textColor, () => ref.read(provedorLocalizacao.notifier).mudarLingua('es')),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionTitle(t.t('config_secao_geral')),
            _buildSettingItem(Icons.help_outline, t.t('config_ajuda'), textColor, cardColor, () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaOnboarding()));
            }),
            
            const SizedBox(height: 40),
            
            TextButton.icon(
              onPressed: () {
                ref.read(provedorNotificadorAutenticacao.notifier).logout();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.power_settings_new, color: AppColors.error),
              label: Text(t.t('config_sair'), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.error)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), alignment: Alignment.centerLeft),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Text(title, style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)));
  }
  Widget _buildRadioItem(String title, bool selected, Color? color, VoidCallback onTap) {
    return ListTile(onTap: onTap, title: Text(title, style: GoogleFonts.poppins(color: color)), trailing: selected ? const Icon(Icons.check_circle, color: AppColors.primaryPurple) : const Icon(Icons.circle_outlined, color: Colors.grey));
  }
  Widget _buildSettingItem(IconData icon, String title, Color? color, Color? bgColor, VoidCallback onTap) {
    return ListTile(onTap: onTap, contentPadding: EdgeInsets.zero, leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.grey)), title: Text(title, style: GoogleFonts.poppins(fontSize: 16, color: color, fontWeight: FontWeight.w500)), trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14));
  }
}
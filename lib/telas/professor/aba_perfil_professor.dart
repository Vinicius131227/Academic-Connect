import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../themes/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../aluno/tela_editar_perfil.dart'; 
import '../comum/tela_configuracoes.dart'; 

class AbaPerfilProfessor extends ConsumerWidget {
  const AbaPerfilProfessor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;
    final nome = usuario?.alunoInfo?.nomeCompleto ?? 'Professor';
    final email = usuario?.email ?? '';
    final identificacao = usuario?.alunoInfo?.ra ?? ''; 
    final tipoId = usuario?.tipoIdentificacao ?? 'ID';

    // Tema Dinâmico
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             Center(
               child: Column(
                 children: [
                   CircleAvatar(
                     radius: 60,
                     backgroundColor: AppColors.primaryPurple,
                     child: Text(
                       nome.isNotEmpty ? nome[0].toUpperCase() : 'P',
                       style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                     ),
                   ),
                   const SizedBox(height: 20),
                   Text(nome, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor), textAlign: TextAlign.center),
                   const SizedBox(height: 4),
                   Text(email, style: GoogleFonts.poppins(fontSize: 14, color: isDark ? AppColors.textGrey : Colors.grey)),
                 ],
               ),
             ),

             const SizedBox(height: 40),

             SizedBox(
               width: 200,
               child: ElevatedButton(
                 onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaEditarPerfil()));
                 },
                 style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                 child: Text(t.t('perfil_editar_btn'), style: const TextStyle(color: Colors.white)),
               ),
             ),

             const SizedBox(height: 40),
             
             Align(
               alignment: Alignment.centerLeft,
               child: Text(t.t('perfil_info_profissional'), style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
             ),
             const SizedBox(height: 10),

             _buildInfoItem(tipoId, identificacao, textColor!),
             _buildInfoItem("Departamento", "Ciências Exatas", textColor),
             
             const SizedBox(height: 30),
             
             ListTile(
               contentPadding: EdgeInsets.zero,
               leading: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: AppColors.primaryPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                 child: const Icon(Icons.settings, color: AppColors.primaryPurple),
               ),
               title: Text(t.t('config_titulo'), style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.w500)),
               trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
               onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaConfiguracoes()));
               },
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }
}
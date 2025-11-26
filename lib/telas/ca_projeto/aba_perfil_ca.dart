// lib/telas/ca_projeto/aba_perfil_ca.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../themes/app_theme.dart';
import '../comum/tela_configuracoes.dart';

class AbaPerfilCA extends ConsumerWidget {
  const AbaPerfilCA({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;
    final email = usuario?.email ?? '';
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

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
                     backgroundColor: AppColors.cardOrange, // Laranja para diferenciar CA
                     child: Text("CA", style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                   ),
                   const SizedBox(height: 20),
                   Text("Centro Acadêmico", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor), textAlign: TextAlign.center),
                   const SizedBox(height: 4),
                   Text(email, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                 ],
               ),
             ),

             const SizedBox(height: 40),
             
             ListTile(
               contentPadding: EdgeInsets.zero,
               leading: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                 child: Icon(Icons.settings, color: textColor),
               ),
               title: Text("Configurações", style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.w500)),
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
}
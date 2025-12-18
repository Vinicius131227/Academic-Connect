// lib/telas/aluno/aba_perfil_aluno.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../../providers/provedor_autenticacao.dart';
import '../../themes/app_theme.dart';
import 'tela_editar_perfil.dart';
import '../comum/tela_configuracoes.dart'; 
import '../../l10n/app_localizations.dart';

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Perfil Aluno',
  type: AbaPerfilAluno,
)
Widget buildAbaPerfilAluno(BuildContext context) {
  return const ProviderScope(
    child: AbaPerfilAluno(),
  );
}

/// Tela de Perfil do Aluno.
class AbaPerfilAluno extends ConsumerWidget {
  const AbaPerfilAluno({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Instancia o sistema de tradução
    final t = AppLocalizations.of(context)!;
    
    final authState = ref.watch(provedorNotificadorAutenticacao);
    final usuario = authState.usuario;
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;

    if (authState.carregando) return const Center(child: CircularProgressIndicator());
    
    if (usuario == null || usuario.alunoInfo == null) {
       return Center(
         child: ElevatedButton(
           child: const Text("Completar Cadastro"),
           onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaEditarPerfil(isFromSignUp: true))),
         )
       );
    }

    final info = usuario.alunoInfo!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             // 1. Cabeçalho (Avatar + Nome)
             Center(
               child: Column(
                 children: [
                   CircleAvatar(
                     radius: 60,
                     backgroundColor: AppColors.primaryPurple,
                     child: Text(
                       info.nomeCompleto.isNotEmpty ? info.nomeCompleto[0].toUpperCase() : 'A',
                       style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                     ),
                   ),
                   const SizedBox(height: 20),
                   Text(
                     info.nomeCompleto,
                     style: GoogleFonts.poppins(
                       fontSize: 24, fontWeight: FontWeight.bold, color: textColor
                     ),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 4),
                   Text(
                     usuario.email,
                     style: GoogleFonts.poppins(
                       fontSize: 14, color: isDark ? AppColors.textGrey : Colors.grey
                     ),
                   ),
                 ],
               ),
             ),

             const SizedBox(height: 40),

             // 2. Botão Editar
             SizedBox(
               width: 200,
               child: ElevatedButton(
                 onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaEditarPerfil()));
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.primaryPurple,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                 ),
                 child: Text(t.t('perfil_editar_btn'), style: const TextStyle(color: Colors.white)),
               ),
             ),

             const SizedBox(height: 40),
             
             // 3. Informações Acadêmicas
             Align(
               alignment: Alignment.centerLeft,
               child: Text(
                 t.t('perfil_info_academica'), 
                 style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)
               ),
             ),
             const SizedBox(height: 10),

             _buildInfoItem(t.t('cadastro_ra_label'), info.ra, textColor!), 
             _buildInfoItem(t.t('cadastro_curso'), info.curso, textColor),  
             _buildInfoItem(
               t.t('cadastro_data_nasc_label'), 
               info.dataNascimento != null ? DateFormat('dd/MM/yyyy').format(info.dataNascimento!) : "N/A", 
               textColor
             ),
             _buildInfoItem(t.t('aluno_perfil_status'), info.status, textColor),

             const SizedBox(height: 30),
             
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
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
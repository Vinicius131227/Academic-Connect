// lib/telas/aluno/aba_perfil_aluno.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../themes/app_theme.dart';
import 'tela_editar_perfil.dart';
import 'tela_sugestoes.dart';
import '../../l10n/app_localizations.dart';

class AbaPerfilAluno extends ConsumerWidget {
  const AbaPerfilAluno({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(provedorNotificadorAutenticacao);
    final usuario = authState.usuario;
    
    if (authState.carregando) return const Center(child: CircularProgressIndicator());
    if (usuario == null || usuario.alunoInfo == null) {
       // Fallback se não tiver dados
       return Center(
         child: ElevatedButton(
           child: const Text("Completar Cadastro"),
           onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaEditarPerfil(isFromSignUp: true))),
         )
       );
    }

    final info = usuario.alunoInfo!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             // Foto e Nome
             Center(
               child: Column(
                 children: [
                   CircleAvatar(
                     radius: 60,
                     backgroundColor: AppColors.primaryPurple,
                     // Imagem placeholder
                     backgroundImage: const NetworkImage('https://i.pravatar.cc/300'),
                   ),
                   const SizedBox(height: 20),
                   Text(
                     info.nomeCompleto,
                     style: GoogleFonts.poppins(
                       fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white
                     ),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 4),
                   Text(
                     usuario.email,
                     style: GoogleFonts.poppins(
                       fontSize: 14, color: AppColors.textGrey
                     ),
                   ),
                 ],
               ),
             ),

             const SizedBox(height: 40),

             // Botão de Editar (Visual igual ao "Go PRO" ou destaque)
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
                 child: const Text("Edit Profile"),
               ),
             ),

             const SizedBox(height: 40),
             
             // LISTA DE DADOS (Academic Info)
             Align(
               alignment: Alignment.centerLeft,
               child: Text("ACADEMIC INFO", style: GoogleFonts.poppins(color: AppColors.textGrey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
             ),
             const SizedBox(height: 10),

             _buildInfoItem("RA (ID)", info.ra),
             _buildInfoItem("Course", info.curso),
             _buildInfoItem("Birth Date", info.dataNascimento != null ? DateFormat('dd/MM/yyyy').format(info.dataNascimento!) : "N/A"),
             _buildInfoItem("Status", info.status),
             _buildInfoItem("CR (GPA)", info.cr.toStringAsFixed(2)),

             const SizedBox(height: 30),
             
             // Botão de Sugestão
             ListTile(
               contentPadding: EdgeInsets.zero,
               leading: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                 child: const Icon(Icons.feedback, color: AppColors.primaryPurple),
               ),
               title: Text("Send Feedback", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
               trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
               onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaSugestoes())),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.poppins(color: Colors.white70)),
        ],
      ),
    );
  }
}
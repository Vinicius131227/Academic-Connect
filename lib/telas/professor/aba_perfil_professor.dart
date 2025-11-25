// lib/telas/professor/aba_perfil_professor.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../themes/app_theme.dart';
import '../aluno/tela_editar_perfil.dart';
import '../comum/tela_configuracoes.dart'; // Import para configurações

class AbaPerfilProfessor extends ConsumerWidget {
  const AbaPerfilProfessor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;
    final nome = usuario?.alunoInfo?.nomeCompleto ?? 'Professor';
    final email = usuario?.email ?? '';
    final identificacao = usuario?.alunoInfo?.ra ?? ''; // Usando campo RA para ID
    final tipoId = usuario?.tipoIdentificacao ?? 'ID';

    return Scaffold(
      backgroundColor: AppColors.background,
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
                   Text(nome, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                   const SizedBox(height: 4),
                   Text("Professor | $email", style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey)),
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
                 child: const Text("Editar Perfil"),
               ),
             ),

             const SizedBox(height: 40),
             
             Align(
               alignment: Alignment.centerLeft,
               child: Text("INFORMAÇÕES", style: GoogleFonts.poppins(color: AppColors.textGrey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
             ),
             const SizedBox(height: 10),

             _buildInfoItem(tipoId, identificacao),
             _buildInfoItem("Departamento", "Ciências Exatas"),
             
             const SizedBox(height: 30),
             
             ListTile(
               contentPadding: EdgeInsets.zero,
               leading: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                 child: const Icon(Icons.settings, color: Colors.white),
               ),
               title: Text("Configurações", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
               trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
               onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaConfiguracoes()));
               },
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
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
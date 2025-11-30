// lib/telas/professor/aba_perfil_professor.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../providers/provedor_autenticacao.dart';
import '../../themes/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../aluno/tela_editar_perfil.dart'; // Reutiliza a tela de edição (que se adapta)
import '../comum/tela_configuracoes.dart'; 

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Perfil Professor',
  type: AbaPerfilProfessor,
)
Widget buildAbaPerfilProfessor(BuildContext context) {
  return const ProviderScope(
    child: AbaPerfilProfessor(),
  );
}

/// Aba de Perfil do Professor.
/// 
/// Exibe:
/// - Avatar e Nome.
/// - Botão de Edição.
/// - Dados Profissionais (SIAPE, Departamento).
/// - Acesso às Configurações.
class AbaPerfilProfessor extends ConsumerWidget {
  const AbaPerfilProfessor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    // Obtém usuário logado
    final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;
    
    // Fallbacks seguros para dados
    final nome = usuario?.alunoInfo?.nomeCompleto ?? 'Professor';
    final email = usuario?.email ?? '';
    final identificacao = usuario?.alunoInfo?.ra ?? ''; // RA é usado para guardar SIAPE
    final tipoId = usuario?.tipoIdentificacao ?? 'ID';

    // Tema Dinâmico
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      
      // AppBar (Transparente, apenas para espaçamento/ícones se precisar)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             // 1. Cabeçalho (Foto e Nome)
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
                   Text(
                     nome, 
                     style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor), 
                     textAlign: TextAlign.center
                   ),
                   const SizedBox(height: 4),
                   Text(
                     email, 
                     style: GoogleFonts.poppins(fontSize: 14, color: isDark ? AppColors.textGrey : Colors.grey)
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
                    // Navega para tela de edição (que se adapta para professor)
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaEditarPerfil()));
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.primaryPurple, 
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                 ),
                 child: Text(t.t('perfil_editar_btn'), style: const TextStyle(color: Colors.white)),
               ),
             ),

             const SizedBox(height: 40),
             
             // 3. Seção de Informações Profissionais
             Align(
               alignment: Alignment.centerLeft,
               child: Text(
                 t.t('perfil_info_profissional'), // "INFORMAÇÕES PROFISSIONAIS"
                 style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)
               ),
             ),
             const SizedBox(height: 10),

             // Itens de Informação
             _buildInfoItem(tipoId, identificacao, textColor!),
             _buildInfoItem("Departamento", "Ciências Exatas", textColor), // Fixo para MVP ou buscar do banco
             
             const SizedBox(height: 30),
             
             // 4. Botão Configurações
             ListTile(
               contentPadding: EdgeInsets.zero,
               leading: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: AppColors.primaryPurple.withOpacity(0.1), 
                   borderRadius: BorderRadius.circular(8)
                 ),
                 child: const Icon(Icons.settings, color: AppColors.primaryPurple),
               ),
               title: Text(
                 t.t('config_titulo'), 
                 style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.w500)
               ),
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

  /// Widget auxiliar para linhas de informação (Label + Valor).
  Widget _buildInfoItem(String label, String value, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12))
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
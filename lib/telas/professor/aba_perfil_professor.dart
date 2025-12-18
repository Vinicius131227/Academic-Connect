// lib/telas/professor/aba_perfil_professor.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../providers/provedor_autenticacao.dart';
import '../../themes/app_theme.dart';
import '../comum/tela_configuracoes.dart'; 
import '../../l10n/app_localizations.dart';
import '../aluno/tela_editar_perfil.dart';

/// Caso de uso para o Widgetbook.
/// Permite visualizar a tela de perfil do professor isoladamente.
@UseCase(
  name: 'Perfil Professor',
  type: AbaPerfilProfessor,
)
Widget buildAbaPerfilProfessor(BuildContext context) {
  return const ProviderScope(
    child: AbaPerfilProfessor(),
  );
}

/// Tela que exibe o perfil do Professor.
/// 
/// Funcionalidades:
/// - Avatar e Nome.
/// - Botão para Editar Perfil.
/// - Lista de Informações Profissionais (ID/SIAPE, Email).
/// - Acesso às Configurações (via AppBar).
/// - Envio de Sugestões.
class AbaPerfilProfessor extends ConsumerWidget {
  const AbaPerfilProfessor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Instancia o tradutor
    final t = AppLocalizations.of(context)!;
    
    // Obtém dados do usuário
    final authState = ref.watch(provedorNotificadorAutenticacao);
    final usuario = authState.usuario;
    
    // Configuração de Tema
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;

    // Se estiver carregando ou sem usuário, mostra spinner ou erro
    if (authState.carregando) return const Center(child: CircularProgressIndicator());
    if (usuario == null) return const Center(child: Text("Erro: Usuário não encontrado"));

    // Pega o nome do objeto alunoInfo (usado genericamente para todos os usuários)
    final nomeExibicao = usuario.alunoInfo?.nomeCompleto ?? "Professor";
    
    // Para professor, o RA armazena o número de identificação (SIAPE/Registro)
    final identificacao = usuario.alunoInfo?.ra ?? "N/A";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, 
      
      // Corpo Rolável
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             // 1. Cabeçalho (Avatar + Nome + Email)
             Center(
               child: Column(
                 children: [
                   CircleAvatar(
                     radius: 60,
                     backgroundColor: AppColors.primaryPurple,
                     child: Text(
                       nomeExibicao.isNotEmpty ? nomeExibicao[0].toUpperCase() : 'P',
                       style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                     ),
                   ),
                   const SizedBox(height: 20),
                   Text(
                     nomeExibicao,
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

             // 2. Botão Editar (Roxo, Arredondado)
             SizedBox(
               width: 200,
               child: ElevatedButton(
                 onPressed: () {
                   // Reusa a tela de edição de perfil (ela se adapta se não for aluno)
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
             _buildInfoItem(t.t('cadastro_num_prof'), identificacao, textColor!), 
             _buildInfoItem(t.t('login_email'), usuario.email, textColor),  
             
             const SizedBox(height: 30),
             
          ],
        ),
      ),
    );
  }

  /// Widget auxiliar para criar as linhas de informação (Label + Valor).
  Widget _buildInfoItem(String label, String value, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)), // Linha divisória sutil
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
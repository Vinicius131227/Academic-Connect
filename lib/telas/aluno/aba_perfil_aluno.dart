// lib/telas/aluno/aba_perfil_aluno.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../providers/provedor_autenticacao.dart';
import '../../themes/app_theme.dart';
import 'tela_editar_perfil.dart'; // Edição de dados
import 'tela_sugestoes.dart';     // Envio de feedback
import '../comum/tela_configuracoes.dart'; // Configurações globais
import '../../l10n/app_localizations.dart'; // Traduções

/// Caso de uso para o Widgetbook.
/// Permite visualizar a tela de perfil do aluno isoladamente.
@UseCase(
  name: 'Perfil Aluno',
  type: AbaPerfilAluno,
)
Widget buildAbaPerfilAluno(BuildContext context) {
  // Envolvemos em ProviderScope para simular o ambiente do Riverpod
  return const ProviderScope(
    child: AbaPerfilAluno(),
  );
}

/// Tela que exibe o perfil completo do Aluno.
///
/// Funcionalidades:
/// - Visualizar Nome, Email e Foto (Avatar).
/// - Botão para Editar Perfil.
/// - Lista de Informações Acadêmicas (RA, Curso, Data Nasc, Status, CR).
/// - Acesso às Configurações (via AppBar).
/// - Envio de Sugestões.
class AbaPerfilAluno extends ConsumerWidget {
  const AbaPerfilAluno({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    // Obtém o estado da autenticação (usuário logado)
    final authState = ref.watch(provedorNotificadorAutenticacao);
    final usuario = authState.usuario;
    
    // Configurações de tema
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;

    // Se estiver carregando os dados, mostra spinner
    if (authState.carregando) return const Center(child: CircularProgressIndicator());
    
    // Se não houver usuário ou dados de aluno, mostra botão de fallback
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
      backgroundColor: theme.scaffoldBackgroundColor, // Respeita o tema claro/escuro
      
      // AppBar Transparente com Ícone de Configurações
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textColor),
            tooltip: t.t('config_titulo'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaConfiguracoes())),
          ),
        ],
      ),
      
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
                       // Mostra a inicial do nome se não tiver foto
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

             // 2. Botão de Editar
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
             
             // 3. Seção de Informações Acadêmicas
             Align(
               alignment: Alignment.centerLeft,
               child: Text(
                 t.t('perfil_info_academica'), // "INFORMAÇÕES ACADÊMICAS"
                 style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)
               ),
             ),
             const SizedBox(height: 10),

             // Lista de detalhes
             _buildInfoItem("RA (ID)", info.ra, textColor!),
             _buildInfoItem(t.t('cadastro_curso'), info.curso, textColor), // Usando chave correta 'cadastro_curso'
             _buildInfoItem(
               t.t('cadastro_data_nasc_label'), 
               info.dataNascimento != null ? DateFormat('dd/MM/yyyy').format(info.dataNascimento!) : "N/A", 
               textColor
             ),
             _buildInfoItem(t.t('aluno_perfil_status'), info.status, textColor),
             _buildInfoItem(t.t('aluno_perfil_cr'), info.cr.toStringAsFixed(2), textColor),

             const SizedBox(height: 30),
             
             // 4. Botão de Sugestão/Feedback
             ListTile(
               contentPadding: EdgeInsets.zero,
               leading: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: AppColors.primaryPurple.withOpacity(0.1), 
                   borderRadius: BorderRadius.circular(8)
                 ),
                 child: const Icon(Icons.feedback, color: AppColors.primaryPurple),
               ),
               title: Text(
                 t.t('perfil_sugestao_btn'), 
                 style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.w500)
               ),
               trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
               onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaSugestoes())),
             ),
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
        border: Border(bottom: BorderSide(color: Colors.black12)), // Separador sutil
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
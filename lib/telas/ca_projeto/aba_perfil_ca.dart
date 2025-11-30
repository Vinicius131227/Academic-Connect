// lib/telas/ca_projeto/aba_perfil_ca.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../providers/provedor_autenticacao.dart';
import '../../themes/app_theme.dart'; // Cores e Estilos
import '../comum/tela_configuracoes.dart'; // Navegação
import '../../l10n/app_localizations.dart'; // Traduções

/// Caso de uso para o Widgetbook.
/// Permite testar o visual da tela de Perfil do CA isoladamente.
@UseCase(
  name: 'Perfil CA',
  type: AbaPerfilCA,
)
Widget buildAbaPerfilCA(BuildContext context) {
  return const ProviderScope(
    child: AbaPerfilCA(),
  );
}

/// Aba de Perfil para o usuário do tipo "Centro Acadêmico" (C.A.) ou Projeto.
///
/// Exibe:
/// - Avatar e Nome (Gestão).
/// - E-mail de contato.
/// - Botão para acessar as Configurações Gerais (Tema, Idioma, Sair).
class AbaPerfilCA extends ConsumerWidget {
  const AbaPerfilCA({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    // Obtém os dados do usuário logado via Riverpod
    final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;
    final email = usuario?.email ?? '';
    
    // Configurações de Tema
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Respeita Claro/Escuro
      
      // Conteúdo Rolável
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             // 1. Cabeçalho do Perfil (Avatar + Texto)
             Center(
               child: Column(
                 children: [
                   CircleAvatar(
                     radius: 60,
                     backgroundColor: AppColors.cardOrange, // Laranja para identidade visual do CA
                     child: Text(
                       "CA", 
                       style: GoogleFonts.poppins(
                         fontSize: 40, 
                         fontWeight: FontWeight.bold, 
                         color: Colors.white
                       )
                     ),
                   ),
                   const SizedBox(height: 20),
                   
                   Text(
                     "Centro Acadêmico", 
                     style: GoogleFonts.poppins(
                       fontSize: 24, 
                       fontWeight: FontWeight.bold, 
                       color: textColor
                     ), 
                     textAlign: TextAlign.center
                   ),
                   
                   const SizedBox(height: 4),
                   
                   Text(
                     email, 
                     style: GoogleFonts.poppins(
                       fontSize: 14, 
                       color: Colors.grey
                     )
                   ),
                 ],
               ),
             ),

             const SizedBox(height: 40),
             
             // 2. Lista de Opções
             // (Atualmente apenas Configurações, mas pode expandir para "Editar Perfil", etc.)
             ListTile(
               contentPadding: EdgeInsets.zero,
               leading: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: Colors.grey.withOpacity(0.1), 
                   borderRadius: BorderRadius.circular(8)
                 ),
                 child: Icon(Icons.settings, color: textColor),
               ),
               title: Text(
                 t.t('config_titulo'), // "Configurações"
                 style: GoogleFonts.poppins(
                   color: textColor, 
                   fontWeight: FontWeight.w500
                 )
               ),
               trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
               onTap: () {
                 // Navega para a tela de configurações gerais
                 Navigator.push(
                   context, 
                   MaterialPageRoute(builder: (_) => const TelaConfiguracoes())
                 );
               },
             ),
          ],
        ),
      ),
    );
  }
}
// lib/telas/aluno/aba_inicio_aluno.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../../providers/provedor_autenticacao.dart';
import '../../providers/provedores_app.dart'; 
import '../../providers/provedor_mapas.dart'; 
import '../../models/prova_agendada.dart'; 
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../comum/animacao_fadein_lista.dart'; 
import '../comum/widget_carregamento.dart';
import 'tela_solicitar_adaptacao.dart'; 
import 'tela_drive_provas.dart'; 
import 'tela_dicas_gerais.dart'; 
import 'tela_calendario.dart';
import 'tela_cadastro_nfc.dart'; 
import 'tela_minhas_solicitacoes.dart';

@UseCase(
  name: 'Home Aluno',
  type: AbaInicioAluno,
)
Widget buildAbaInicioAluno(BuildContext context) {
  return const ProviderScope(
    child: AbaInicioAluno(),
  );
}

class AbaInicioAluno extends ConsumerWidget {
  const AbaInicioAluno({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    // Providers de dados
    final asyncTurmas = ref.watch(provedorStreamTurmasAluno);
    final asyncProvas = ref.watch(provedorStreamCalendario); 
    final servicoMapas = ref.read(provedorMapas); 
    
    final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;

    // Pega o primeiro nome para a saudação
    final nomeAluno = usuario?.alunoInfo?.nomeCompleto.split(' ')[0] ?? 'Aluno';

    // Tema
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

    // --- FUNÇÃO PARA MOSTRAR DETALHES DA PROVA ---
    void _mostrarDetalhesProva(ProvaAgendada prova) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cardColor,
          title: Row(
            children: [
              const Icon(Icons.assignment_late, color: AppColors.primaryPurple),
              const SizedBox(width: 12),
              Expanded(child: Text(prova.titulo, style: TextStyle(color: textColor))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prova.disciplina, style: TextStyle(color: subTextColor, fontSize: 14, fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              
              _buildDetailRow(
                Icons.access_time, 
                t.t('lbl_data_hora'), 
                DateFormat("dd/MM/yyyy 'às' HH:mm").format(prova.dataHora), 
                textColor, subTextColor
              ),
              const SizedBox(height: 16),

              _buildDetailRow(
                Icons.menu_book, 
                t.t('lbl_conteudo'), 
                prova.conteudo.isEmpty ? t.t('lbl_nao_informado') : prova.conteudo, 
                textColor, subTextColor
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 20, color: subTextColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.t('lbl_local'), style: TextStyle(color: subTextColor, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text("${prova.predio} - ${prova.sala}", style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(ctx); 
                      servicoMapas.abrirLocalizacao(prova.predio).catchError((e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
                      });
                    },
                    icon: const Icon(Icons.map, color: AppColors.primaryPurple),
                    tooltip: t.t('aluno_detalhes_ver_mapa'),
                  )
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.t('fechar'), style: const TextStyle(color: AppColors.primaryPurple)),
            )
          ],
        ),
      );
    }

    void _abrirDriveGlobal() {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaDriveProvas()));
    }
    
    void _abrirDicasGerais() {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaDicasGerais()));
    }

    // Lista de Widgets para animação FadeIn
    final widgets = [
      // 1. CABEÇALHO
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text("👋 ", style: TextStyle(fontSize: 24)),
                  Text(
                    "${t.t('inicio_ola')}, $nomeAluno", 
                    style: GoogleFonts.poppins(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: textColor
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                t.t('inicio_subtitulo'), 
                style: TextStyle(fontSize: 14, color: subTextColor),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardColor, 
              shape: BoxShape.circle,
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Icon(Icons.notifications_none, color: textColor),
          ),
        ],
      ),

      const SizedBox(height: 24),

      // 2. ACESSO RÁPIDO
      Text(
        t.t('inicio_acesso_rapido'), 
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)
      ),
      const SizedBox(height: 16),
      
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drive
          Expanded(child: _buildCategoryItem(context, icon: Icons.folder_shared_outlined, label: t.t('card_drive'), color: const Color(0xFFFFF3E0), iconColor: Colors.orange, textColor: subTextColor, onTap: _abrirDriveGlobal)),
          const SizedBox(width: 8),
          
          // Solicitar Adaptação
          Expanded(
            child: _buildCategoryItem(
              context, 
              icon: Icons.accessibility_new, 
              label: t.t('card_adaptacao'), 
              color: const Color(0xFFF3E5F5), 
              iconColor: Colors.purple, 
              textColor: subTextColor, 
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaSolicitarAdaptacao()))
            )
          ),
          const SizedBox(width: 8),
          
          // Meus Pedidos (NOVO)
          Expanded(
            child: _buildCategoryItem(
              context, 
              icon: Icons.checklist_rtl, 
              label: "Meus Pedidos", 
              color: const Color(0xFFE3F2FD), 
              iconColor: Colors.blue, 
              textColor: subTextColor, 
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaMinhasSolicitacoes()))
            )
          ),
          
          const SizedBox(width: 8),
          
          Expanded(
            child: _buildCategoryItem(
              context, 
              icon: Icons.lightbulb_outline, 
              label: t.t('card_dicas'), 
              color: const Color(0xFFE8F5E9), 
              iconColor: Colors.green, 
              textColor: subTextColor, 
              onTap: _abrirDicasGerais
            )
          ),
        ],
      ),

      const SizedBox(height: 24),

      // 3. BANNER DE CADASTRO NFC
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryPurple, Color(0xFF7E57C2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaCadastroNFC()));
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.nfc, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.t('nfc_cadastro_titulo'), 
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.t('inicio_configurar_nfc'), 
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),

      const SizedBox(height: 32),

      // 4. PRÓXIMAS AVALIAÇÕES (Calendário Inline)
      Text(
        t.t('inicio_proximas_avaliacoes'), 
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)
      ),
      const SizedBox(height: 16),

      asyncTurmas.when(
        loading: () => const WidgetCarregamento(texto: ''),
        error: (_,__) => const SizedBox.shrink(),
        data: (turmas) {
          final meusIds = turmas.map((t) => t.id).toSet();

          return asyncProvas.when(
            loading: () => const WidgetCarregamento(texto: ''),
            error: (e,s) => const SizedBox.shrink(),
            data: (todasProvas) {
              
              // --- FILTRO DE DATA ---
              final agora = DateTime.now();
              
              final minhasProvas = todasProvas.where((p) {
                  final ehMinhaTurma = meusIds.contains(p.turmaId);
                  final ehFutura = p.dataHora.isAfter(agora);
                  return ehMinhaTurma && ehFutura;
              }).toList();

              // Ordena para mostrar a mais próxima primeiro
              minhasProvas.sort((a,b) => a.dataHora.compareTo(b.dataHora));
              
              if (minhasProvas.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
                  child: Center(child: Text(t.t('inicio_sem_provas'), style: TextStyle(color: subTextColor))),
                );
              }
              
              return Column(
                children: minhasProvas.take(3).map((prova) => 
                  GestureDetector(
                    onTap: () => _mostrarDetalhesProva(prova),
                    child: _buildResultCard(prova, cardColor, textColor, subTextColor)
                  )
                ).toList()
              );
            }
          );
        }
      ),

      const SizedBox(height: 30),
      
      // 5. BOTÃO SINCRONIZAR
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.t('sucesso'))));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(t.t('inicio_btn_sincronizar'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(height: 80),
    ];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: FadeInListAnimation(children: widgets),
    );
  }

  // Helper para linhas de detalhe no Dialog
  Widget _buildDetailRow(IconData icon, String label, String value, Color textColor, Color subTextColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: subTextColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: subTextColor, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: textColor, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(BuildContext context, {
      required IconData icon, 
      required String label, 
      required Color color, 
      required Color iconColor, 
      required Color textColor,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 55, width: 55,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500), 
            textAlign: TextAlign.center, 
            maxLines: 2, 
            overflow: TextOverflow.ellipsis
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(ProvaAgendada prova, Color cardColor, Color titleColor, Color subtitleColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.cardBlue.withOpacity(0.2),
            child: Text(DateFormat('dd').format(prova.dataHora), style: const TextStyle(color: AppColors.cardBlue, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prova.disciplina, style: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(prova.titulo, style: TextStyle(color: subtitleColor, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(DateFormat('HH:mm').format(prova.dataHora), style: TextStyle(color: subtitleColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
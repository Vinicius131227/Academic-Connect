// lib/telas/aluno/aba_inicio_aluno.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../providers/provedor_autenticacao.dart';
import '../../providers/provedores_app.dart'; 
import '../../providers/provedor_mapas.dart'; // IMPORTANTE: Mapas
import '../../models/prova_agendada.dart'; 
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../comum/animacao_fadein_lista.dart'; 
import '../comum/widget_carregamento.dart';

// Telas de navegação
import 'tela_solicitar_adaptacao.dart';
import 'tela_drive_provas.dart'; 
import 'tela_dicas_gerais.dart'; 
import 'tela_calendario.dart';   

@UseCase(
  name: 'Home Aluno',
  type: AbaInicioAluno,
)
Widget buildAbaInicioAluno(BuildContext context) {
  return const ProviderScope(
    child: AbaInicioAluno(),
  );
}

final quoteProvider = FutureProvider<String>((ref) async {
  try {
    final response = await http.get(Uri.parse('https://api.adviceslip.com/advice'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['slip']['advice'].toString();
    }
    return "Estude com dedicação!";
  } catch (e) {
    return "Mantenha o foco nos estudos.";
  }
});

class AbaInicioAluno extends ConsumerWidget {
  const AbaInicioAluno({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    // Providers de dados
    final asyncTurmas = ref.watch(provedorStreamTurmasAluno);
    final asyncProvas = ref.watch(provedorStreamCalendario); 
    final servicoMapas = ref.read(provedorMapas); // Serviço de Mapas
    
    final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;
    final asyncQuote = ref.watch(quoteProvider);

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
              // Matéria
              Text(prova.disciplina, style: TextStyle(color: subTextColor, fontSize: 14, fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              
              // Data e Hora
              _buildDetailRow(
                Icons.access_time, 
                "Data e Hora", 
                DateFormat("dd/MM/yyyy 'às' HH:mm").format(prova.dataHora), 
                textColor, subTextColor
              ),
              const SizedBox(height: 16),

              // Conteúdo
              _buildDetailRow(
                Icons.menu_book, 
                "Conteúdo", 
                prova.conteudo.isEmpty ? "Não informado" : prova.conteudo, 
                textColor, subTextColor
              ),
              const SizedBox(height: 16),

              // Localização com Ação de Mapa
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 20, color: subTextColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Local", style: TextStyle(color: subTextColor, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text("${prova.predio} - ${prova.sala}", style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  // Botão MAPA
                  IconButton(
                    onPressed: () {
                      Navigator.pop(ctx); // Fecha o dialog
                      // Chama o serviço de mapas com o nome do prédio
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
              asyncQuote.when(
                data: (frase) => SizedBox(
                  width: 250, 
                  child: Text(
                    '"$frase"', 
                    style: TextStyle(fontSize: 12, color: subTextColor, fontStyle: FontStyle.italic), 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis
                  )
                ),
                loading: () => Text(t.t('carregando'), style: TextStyle(fontSize: 12, color: subTextColor)),
                error: (_, __) => Text(t.t('inicio_subtitulo'), style: TextStyle(fontSize: 12, color: subTextColor)),
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

      // 3. ACESSO RÁPIDO
      Text(
        t.t('inicio_acesso_rapido'), 
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)
      ),
      const SizedBox(height: 16),
      
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildCategoryItem(context, icon: Icons.folder_shared_outlined, label: t.t('card_drive'), color: const Color(0xFFFFF3E0), iconColor: Colors.orange, textColor: subTextColor, onTap: _abrirDriveGlobal)),
          const SizedBox(width: 8),
          Expanded(child: _buildCategoryItem(context, icon: Icons.lightbulb_outline, label: t.t('card_dicas'), color: const Color(0xFFE3F2FD), iconColor: Colors.blue, textColor: subTextColor, onTap: _abrirDicasGerais)),
          const SizedBox(width: 8),
          Expanded(child: _buildCategoryItem(context, icon: Icons.accessibility_new, label: t.t('card_adaptacao'), color: const Color(0xFFF3E5F5), iconColor: Colors.purple, textColor: subTextColor, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaSolicitarAdaptacao())))),
          const SizedBox(width: 8),
          Expanded(child: _buildCategoryItem(context, icon: Icons.calendar_month, label: t.t('card_calendario'), color: const Color(0xFFE8F5E9), iconColor: Colors.green, textColor: subTextColor, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaCalendario())))),
        ],
      ),

      const SizedBox(height: 32),

      // 4. PRÓXIMAS AVALIAÇÕES (COM CLIQUE)
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
              
              final minhasProvas = todasProvas.where((p) {
                 return meusIds.contains(p.turmaId) && 
                        p.dataHora.isAfter(DateTime.now().subtract(const Duration(days: 1)));
              }).toList();

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
                  // Adicionado GestureDetector para clique
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
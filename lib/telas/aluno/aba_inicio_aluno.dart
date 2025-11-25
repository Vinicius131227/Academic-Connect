// lib/telas/aluno/aba_inicio_aluno.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../providers/provedores_app.dart'; 
import '../../models/prova_agendada.dart'; 
import 'package:intl/intl.dart';
import 'tela_notas_avaliacoes.dart';
import 'tela_solicitar_adaptacao.dart';
import 'tela_cadastro_nfc.dart';
import 'tela_drive_provas.dart'; 
import 'tela_dicas_gerais.dart'; 
import 'tela_calendario.dart';   
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart'; // ÚNICA FONTE DE CORES
import '../comum/animacao_fadein_lista.dart'; 
import '../comum/widget_carregamento.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';

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
    final asyncProvas = ref.watch(provedorStreamCalendario); 
    final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;
    final nomeAluno = usuario?.alunoInfo?.nomeCompleto.split(' ')[0] ?? 'Aluno';
    final cr = usuario?.alunoInfo?.cr ?? 0.0;
    final asyncQuote = ref.watch(quoteProvider);

    // --- LÓGICA DE TEMA ---
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    
    // Cor segura para cards
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

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
                    "Olá, $nomeAluno",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              asyncQuote.when(
                data: (frase) => SizedBox(width: 250, child: Text('"$frase"', style: TextStyle(fontSize: 12, color: subTextColor, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis)),
                loading: () => Text("Carregando...", style: TextStyle(fontSize: 12, color: subTextColor)),
                error: (_, __) => Text("Vamos estudar hoje!", style: TextStyle(fontSize: 12, color: subTextColor)),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle),
            child: Icon(Icons.notifications_none, color: textColor),
          ),
        ],
      ),

      const SizedBox(height: 24),

      // 2. CARD DE STATUS
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF8A65), Color(0xFFFF7043)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: const Color(0xFFFF7043).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatusItem(icon: Icons.auto_graph, value: cr.toStringAsFixed(1), label: "CR Geral"),
            Container(width: 1, height: 40, color: Colors.white30),
            _buildStatusItem(icon: Icons.check_circle_outline, value: "Ativo", label: "Status"),
          ],
        ),
      ),

      const SizedBox(height: 32),

      // 3. CATEGORIAS EM DESTAQUE
      Text("Acesso Rápido", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
      const SizedBox(height: 16),
      
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildCategoryItem(context, icon: Icons.folder_shared_outlined, label: "Drive Provas", color: const Color(0xFFFFF3E0), iconColor: Colors.orange, textColor: subTextColor, onTap: _abrirDriveGlobal)),
          const SizedBox(width: 8),
          Expanded(child: _buildCategoryItem(context, icon: Icons.lightbulb_outline, label: "Dicas Gerais", color: const Color(0xFFE3F2FD), iconColor: Colors.blue, textColor: subTextColor, onTap: _abrirDicasGerais)),
          const SizedBox(width: 8),
          Expanded(child: _buildCategoryItem(context, icon: Icons.accessibility_new, label: "Adaptação", color: const Color(0xFFF3E5F5), iconColor: Colors.purple, textColor: subTextColor, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaSolicitarAdaptacao())))),
          const SizedBox(width: 8),
          Expanded(child: _buildCategoryItem(context, icon: Icons.calendar_month, label: "Calendário", color: const Color(0xFFE8F5E9), iconColor: Colors.green, textColor: subTextColor, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaCalendario())))),
        ],
      ),

      const SizedBox(height: 32),

      // 4. LISTA RECENTE
      Text("Próximas Avaliações", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
      const SizedBox(height: 16),

      asyncProvas.when(
        loading: () => const WidgetCarregamento(texto: ''),
        error: (e,s) => const SizedBox.shrink(),
        data: (provas) {
          if (provas.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text("Sem provas agendadas.", style: TextStyle(color: subTextColor))),
            );
          }
          return Column(children: provas.take(3).map((prova) => _buildResultCard(prova, cardColor, textColor, subTextColor)).toList());
        }
      ),

      const SizedBox(height: 30),
      
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dados sincronizados com sucesso!")));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text("Sincronizar Dados", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(height: 80),
    ];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: FadeInListAnimation(children: widgets),
    );
  }

  Widget _buildStatusItem({required IconData icon, required String value, required String label}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
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
          Text(label, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
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
                ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: 0.7, color: AppColors.cardBlue, backgroundColor: subtitleColor.withOpacity(0.1), minHeight: 6)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(DateFormat('MMM').format(prova.dataHora), style: TextStyle(color: subtitleColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
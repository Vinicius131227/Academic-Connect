import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/provedor_ca.dart'; // Caso tenha lógica específica do CA
import '../../providers/provedores_app.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../comum/widget_carregamento.dart';
import '../comum/animacao_fadein_lista.dart';

// Telas de ação
import 'tela_criar_evento.dart';
import 'tela_presenca_evento.dart';

class AbaInicioCA extends ConsumerWidget {
  const AbaInicioCA({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final asyncEventos = ref.watch(provedorStreamEventosCA);
    final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;
    final nomeCA = usuario?.alunoInfo?.nomeCompleto.split(' ')[0] ?? 'Gestão';

    // --- LÓGICA DE TEMA ---
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white70 : Colors.black54;
    final Color cardBgColor = isDark ? AppColors.surfaceDark : Colors.white;
    final Color borderColor = isDark ? Colors.transparent : Colors.black12;

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
                  const Text("📢 ", style: TextStyle(fontSize: 24)),
                  Text(
                    "${t.t('inicio_ola')}, $nomeCA",
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
                t.t('ca_inicio_resumo'),
                style: GoogleFonts.poppins(fontSize: 14, color: subTextColor),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardBgColor, 
              shape: BoxShape.circle,
              border: Border.all(color: borderColor)
            ),
            child: Icon(Icons.campaign, color: textColor),
          ),
        ],
      ),

      const SizedBox(height: 24),

      // 2. CARD DE STATUS (Laranja Vibrante)
      asyncEventos.when(
        data: (eventos) {
          final totalInscritos = eventos.fold(0, (sum, e) => sum + e.totalParticipantes);
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8A65), Color(0xFFFF7043)], 
                begin: Alignment.topLeft, 
                end: Alignment.bottomRight
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF7043).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6)
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem(
                  icon: Icons.event_available, 
                  value: eventos.length.toString(), 
                  label: t.t('ca_eventos_ativos')
                ),
                Container(width: 1, height: 40, color: Colors.white30),
                _buildStatusItem(
                  icon: Icons.groups, 
                  value: totalInscritos.toString(), 
                  label: t.t('ca_participantes')
                ),
              ],
            ),
          );
        },
        loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
        error: (_,__) => const SizedBox.shrink(),
      ),

      const SizedBox(height: 32),

      // 3. AÇÕES RÁPIDAS
      Text(
        t.t('ca_subtitulo'), 
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)
      ),
      const SizedBox(height: 16),
      
      Row(
        children: [
          Expanded(
            child: _buildCategoryItem(
              context,
              icon: Icons.add_box_outlined,
              label: t.t('ca_criar_evento'),
              color: const Color(0xFFE3F2FD), // Azul claro
              iconColor: Colors.blue,
              textColor: subTextColor,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaCriarEvento())),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCategoryItem(
              context,
              icon: Icons.qr_code_scanner,
              label: t.t('ca_ler_presenca'),
              color: const Color(0xFFE8F5E9), // Verde claro
              iconColor: Colors.green,
              textColor: subTextColor,
              onTap: () {
                 asyncEventos.whenData((eventos) {
                    if (eventos.isNotEmpty) {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => TelaPresencaEvento(evento: eventos.first)));
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.t('ca_sem_eventos'))));
                    }
                 });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCategoryItem(
              context,
              icon: Icons.email_outlined,
              label: t.t('ca_comunicado'),
              color: const Color(0xFFFFF3E0), // Laranja claro
              iconColor: Colors.orange,
              textColor: subTextColor,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Demo")));
              },
            ),
          ),
        ],
      ),

      const SizedBox(height: 32),

      // 4. PRÓXIMOS EVENTOS
      Text(
        t.t('ca_proximos_eventos'), 
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)
      ),
      const SizedBox(height: 16),

      asyncEventos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,s) => const SizedBox.shrink(),
        data: (eventos) {
          if (eventos.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: Text(t.t('ca_sem_eventos'), style: TextStyle(color: subTextColor))
              ),
            );
          }
          eventos.sort((a, b) => a.data.compareTo(b.data));
          
          return Column(
            children: eventos.take(5).map((evento) => 
              _buildEventCard(context, evento, cardBgColor, borderColor, textColor)
            ).toList(),
          );
        },
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
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
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
            height: 60, width: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: GoogleFonts.poppins(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, dynamic evento, Color bgColor, Color borderColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(evento.data), 
                  style: GoogleFonts.poppins(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 18)
                ),
                Text(
                  DateFormat('MMM').format(evento.data), 
                  style: GoogleFonts.poppins(color: AppColors.primaryPurple, fontSize: 12)
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento.nome, 
                  style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(evento.local, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        ],
      ),
    );
  }
}
// lib/telas/ca_projeto/aba_inicio_ca.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provedor_ca.dart';
import '../../providers/provedores_app.dart';
import 'tela_presenca_evento.dart';
import 'tela_criar_evento.dart';
import '../comum/animacao_fadein_lista.dart'; 
import '../../l10n/app_localizations.dart'; 
import '../../themes/app_theme.dart'; // Cores
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/provedor_autenticacao.dart';

class AbaInicioCA extends ConsumerWidget {
  const AbaInicioCA({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final asyncEventos = ref.watch(provedorStreamEventosCA);
    final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;
    final nomeCA = usuario?.alunoInfo?.nomeCompleto.split(' ')[0] ?? 'Gestão';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          "Olá, $nomeCA",
                          style: GoogleFonts.poppins(
                            fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textWhite
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Gerencie os eventos do campus.",
                      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                  child: const Icon(Icons.campaign, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 2. CARD DE STATUS (Laranja/Roxo)
            asyncEventos.when(
              data: (eventos) {
                final totalInscritos = eventos.fold(0, (sum, e) => sum + e.totalParticipantes);
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A65), Color(0xFFFF7043)], 
                      begin: Alignment.topLeft, end: Alignment.bottomRight
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFF7043).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusItem(icon: Icons.event_available, value: eventos.length.toString(), label: "Eventos Ativos"),
                      Container(width: 1, height: 40, color: Colors.white30),
                      _buildStatusItem(icon: Icons.groups, value: totalInscritos.toString(), label: "Participantes"),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (_,__) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 32),

            // 3. ATALHOS RÁPIDOS
            Text("Ações Rápidas", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCategoryItem(
                  icon: Icons.add_box_outlined,
                  label: "Criar Evento",
                  color: const Color(0xFFE3F2FD), // Azul claro
                  iconColor: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaCriarEvento())),
                ),
                _buildCategoryItem(
                  icon: Icons.qr_code_scanner,
                  label: "Ler Presença",
                  color: const Color(0xFFE8F5E9), // Verde claro
                  iconColor: Colors.green,
                  onTap: () {
                     // Pega o primeiro evento para demo ou abre lista
                     asyncEventos.whenData((eventos) {
                        if (eventos.isNotEmpty) {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => TelaPresencaEvento(evento: eventos.first)));
                        } else {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nenhum evento para ler.")));
                        }
                     });
                  },
                ),
                _buildCategoryItem(
                  icon: Icons.email_outlined,
                  label: "Comunicado",
                  color: const Color(0xFFFFF3E0), // Laranja claro
                  iconColor: Colors.orange,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Envio de e-mail em massa (via Firebase).")));
                  },
                ),
                _buildCategoryItem(
                  icon: Icons.analytics_outlined,
                  label: "Relatórios",
                  color: const Color(0xFFF3E5F5), // Roxo claro
                  iconColor: Colors.purple,
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 4. PRÓXIMOS EVENTOS (Lista)
            Text("Próximos Eventos", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),

            asyncEventos.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e,s) => const Text("Erro ao carregar"),
              data: (eventos) {
                if (eventos.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Text("Nenhum evento agendado.", style: TextStyle(color: Colors.grey))),
                  );
                }
                return Column(
                  children: eventos.take(3).map((evento) => _buildEventCard(evento)).toList(),
                );
              },
            ),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
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
            Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryItem({required IconData icon, required String label, required Color color, required Color iconColor, required VoidCallback onTap}) {
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
          Text(label, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEventCard(evento) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(DateFormat('dd').format(evento.data), style: GoogleFonts.poppins(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 18)),
                Text(DateFormat('MMM').format(evento.data), style: GoogleFonts.poppins(color: AppColors.primaryPurple, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(evento.nome, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(evento.local, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
        ],
      ),
    );
  }
}
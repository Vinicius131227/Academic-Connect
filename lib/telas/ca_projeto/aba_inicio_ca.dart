import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provedor_ca.dart';
import '../../providers/provedores_app.dart';
import 'tela_presenca_evento.dart';
// import 'package:ddm_projeto_final/telas/ca_projeto/tela_enviar_comunicado.dart'; // <-- REMOVIDO
import '../comum/animacao_fadein_lista.dart'; 
import 'package:url_launcher/url_launcher.dart'; 
import '../../l10n/app_localizations.dart'; 

class AbaInicioCA extends ConsumerWidget {
  const AbaInicioCA({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    final asyncEventos = ref.watch(provedorStreamEventosCA);
    final links = ref.watch(provedorLinksUteis);

    final widgets = [
      // Card de Boas-Vindas
      Card(
        color: theme.colorScheme.primary,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.t('ca_inicio_bemvindo'),
                style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                t.t('ca_inicio_resumo'),
                style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.9),
                      ),
              ),
            ],
          ),
        ),
      ),
      
      // Botões de Ação Rápida
      _buildAcaoRapida(
        context,
        t: t,
        titulo: t.t('ca_acao_presenca'),
        subtitulo: t.t('ca_acao_presenca_desc'),
        icone: Icons.nfc,
        onTap: () {
          asyncEventos.whenData((eventos) {
            if (eventos.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TelaPresencaEvento(evento: eventos.first)),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nenhum evento cadastrado para registrar presença.')),
              );
            }
          });
        }
      ),
      
      // --- BLOCO REMOVIDO ---
      // _buildAcaoRapida(
      //   context,
      //   t: t,
      //   titulo: t.t('ca_acao_comunicado'),
      //   subtitulo: t.t('ca_acao_comunicado_desc'),
      //   icone: Icons.send_outlined,
      //   onTap: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (_) => const TelaEnviarComunicado()),
      //     );
      //   }
      // ),
      // --- FIM DO BLOCO REMOVIDO ---

      // Card de Links Úteis
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.t('ca_links_uteis'),
                style: theme.textTheme.titleLarge,
              ),
              const Divider(height: 24),
              ...links.map((link) {
                return ListTile(
                  leading: Icon(Icons.link, color: theme.colorScheme.secondary),
                  title: Text(link['titulo']!),
                  contentPadding: EdgeInsets.zero,
                  onTap: () async {
                    final url = Uri.parse(link['url']!);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                );
              }),
            ],
          ),
        ),
      ),
    ];
    
    return FadeInListAnimation(children: widgets);
  }

  Widget _buildAcaoRapida(BuildContext context, {required AppLocalizations t, required String titulo, required String subtitulo, required IconData icone, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(icone, size: 24, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: theme.textTheme.titleLarge),
                    Text(subtitulo, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: theme.textTheme.bodySmall?.color),
            ],
          ),
        ),
      ),
    );
  }
}
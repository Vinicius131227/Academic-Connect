import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// --- IMPORTES ATUALIZADOS ---
import '../../providers/provedores_app.dart'; // MUDOU
import '../comum/widget_carregamento.dart'; // NOVO
import 'package:intl/intl.dart'; // NOVO
// --- FIM IMPORTES ATUALIZADOS ---
import 'tela_presenca_evento.dart';
import 'tela_criar_evento.dart';
import '../../l10n/app_localizations.dart';
import '../comum/animacao_fadein_lista.dart'; 
import '../../models/evento_ca.dart';

class AbaEventosCA extends ConsumerWidget {
  const AbaEventosCA({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    // --- ATUALIZADO: Assiste ao Stream de eventos ---
    final asyncEventos = ref.watch(provedorStreamEventosCA);
    // --- FIM ATUALIZAÇÃO ---
    
    return Scaffold(
      // --- ATUALIZADO: Lida com AsyncValue (loading/error/data) ---
      body: asyncEventos.when(
        loading: () => const WidgetCarregamento(),
        error: (err, st) => Center(child: Text('Erro ao carregar eventos: $err')),
        data: (eventos) {
          if (eventos.isEmpty) {
            return const Center(child: Text('Nenhum evento cadastrado.'));
          }
          final widgets = eventos.map((evento) => _buildCardEvento(context, t, evento)).toList();
          return FadeInListAnimation(children: widgets);
        },
      ),
      // --- FIM ATUALIZAÇÃO ---
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TelaCriarEvento()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCardEvento(BuildContext context, AppLocalizations t, EventoCA evento) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(evento.nome, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            // --- ATUALIZADO: Formata o DateTime ---
            _buildInfoLinha(context, Icons.calendar_today_outlined, DateFormat('dd/MM/yyyy').format(evento.data)),
            // --- FIM ATUALIZAÇÃO ---
            _buildInfoLinha(context, Icons.location_on_outlined, evento.local),
            _buildInfoLinha(context, Icons.group_outlined, '${evento.totalParticipantes} ${t.t('ca_eventos_inscritos')}'),
            const Divider(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.nfc, size: 18),
              label: Text(t.t('ca_eventos_iniciar_registro')),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TelaPresencaEvento(evento: evento)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoLinha(BuildContext context, IconData icone, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icone, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
          const SizedBox(width: 8),
          Text(texto, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}